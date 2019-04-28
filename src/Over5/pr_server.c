
/*************************************************************************
**
** pr_Server.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDANT
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#ifndef LINUX_VERSION
# include <dir.h>
#else
# include <unistd.h>
#endif /* ! LINUX_VERSION */

#include "main_rev.h"

#include "mach_include.h"
#include "mach.h"        
#include "o5protocol.h"
#include "protocol.h"
#include "convert.h"
#include "block.h"
#include "main.h"


void addstringva(char *str, ...);
void addstring(char *str);

char *rs_strpointer;
char *rs_current;

u_int8_t *srv_loadfile(char *);
int srv_savefile(char *,u_int8_t *, u_int32_t);

void command_CD(char *);
void command_DIR(char *);

struct table {
  char *tbl_name;
  void (*tbl_func)(char *);
};

struct table commtab[]={
  {"CD",  &command_CD},
  {"DIR", &command_DIR},
  {"$", &command_DIR},
  {NULL,NULL}
};

/*************************************************************************
**
** bl_server
**
******/
int bl_server(void)
{
  int channel;
  u_int8_t *ptr,type,subtype;
  u_int32_t blen;


  rs_strpointer=NULL;
  rs_current=NULL;

  if (!(ptr=(u_int8_t *) jalloc(256)))
    panic("no mem");


/* startup msg */
  addstring("startup string!\n");

/* get block no timeout */
  while (TRUE) {
    if (readblock(ptr,&blen,&channel,-1))
      continue;
    if (channel != 15) continue;
    if ( blen < sizeof(struct o_header) ) continue;


    type=((struct o_header *)ptr)->ohd_type;
    subtype=((struct o_header *)ptr)->ohd_subtype;

    if ( type!=TYPE_SERVER) continue;

    switch (subtype) {
      case SUB_SRV_LOAD:
        addstring(NULL);
        bl_srvload((struct srvld_header *)ptr);
        break;
      case SUB_SRV_SAVE:
        addstring(NULL);
        bl_srvsave((struct srvsv_header *)ptr);
        break;
      case SUB_SRV_COMMAND:
        addstring(NULL);
        bl_srvcommand((struct srvcm_header *)ptr);
        break;
      case SUB_SRV_READSTRING:
        bl_srvreadstring((struct srvrs_header *)ptr);
        break;
      default:
        respond(RESP_NOTSUPPORTED);
        if (debug>=DBG_FULL)
          printf(">> Wrong command SUBTYPE %02x\n",subtype);
        break;
    }
  }

  jfree(ptr);
  return(PRERR_OK);
}


/*************************************************************************
**
** bl_srvload
**
******/
int bl_srvload(struct srvld_header *srvldhd)
{
  char *name;
  u_int8_t *dataptr;
  u_int32_t datalen;
  u_int32_t start,end;
  struct srvld_response srvldrs;
  int err;

/* get name */
  name=(char *) srvldhd->srvldhd_filename;
  if (debug>=DBG_FULL)
    printf(">> srvload\n   name: %s\n",name);

/* load file */
  dataptr=srv_loadfile(name);
  if (!dataptr) {
    err=respond(RESP_ERROR);
    return(err);
  }
  datalen=jsize(dataptr);
  start=(*dataptr)+(*(dataptr+1)<<8);
  end=start+datalen-2;


/* send ok! */
  srvldrs.srvldrs_response=RESP_OK;
  srvldrs.srvldrs_start_l=start&0xff;
  srvldrs.srvldrs_start_h=(start>>8);
  srvldrs.srvldrs_end_l=end&0xff;
  srvldrs.srvldrs_end_h=(end>>8);
  if ((err=writeblock((u_int8_t *)&srvldrs,sizeof(struct srvld_response),15)))
  {
    jfree(dataptr);
    return(err);
  }

/* wait for ok */
  if ((err=checkresponse(0,0,0))) {
    jfree(dataptr);
    return(err);
  }

/* send data */
  if ((err=sendbody(dataptr+2,datalen-2))) {
    jfree(dataptr);
    return(err);
  }


/* wait for ok */
  if ((err=checkresponse(0,0,0))) {
    jfree(dataptr);
    return(err);
  }

  addstringva("loading from $%04x to $%04x\n",start,end);

/* clean up */
  jfree(dataptr);

  return(PRERR_OK);
}

/*************************************************************************
**
** bl_srvsave
**
******/
int bl_srvsave(struct srvsv_header *srvsvhd)
{
  char *name;
  u_int8_t *ptr;
  u_int32_t size,start,end;
  int err;

/* get name */
  name=(char *) srvsvhd->srvsvhd_filename;
  start=(srvsvhd->srvsvhd_start_l)+((srvsvhd->srvsvhd_start_h)<<8);
  end=(srvsvhd->srvsvhd_end_l)+((srvsvhd->srvsvhd_end_h)<<8);
  size=end-start+2;
  if (debug>=DBG_FULL)
    printf(">> srvsave\n   name: %s\n   size: %d\n",name,size);

  if (!(ptr=(u_int8_t *) jalloc(size)))
    panic("no mem");


  if (!srv_savefile(name,NULL,0)) {
    err=respond(RESP_ERROR);
    jfree(ptr);
    return(err);
  }

/* send ok! */
  if ((err=respond(RESP_OK))) {
    jfree(ptr);
    return(err);
  }

/* receive body */
  if ((err=receivebody(ptr+2,size-2))) {
    jfree(ptr);
    return(err);
  }

/* fix buffer */
  *ptr=start&0xff;
  *(ptr+1)=(start>>8);

/* save */
  if (!srv_savefile(name,ptr,size)) {
    err=respond(RESP_ERROR);
    jfree(ptr);
    return(err);
  }


  jfree(ptr);

  addstringva("saving from $%04x to $%04x\n",start,end);

/* send ok! */
  err=respond(RESP_OK);
  return(err);
}

/*************************************************************************
**
** bl_srvcommand
**
******/
int bl_srvcommand(struct srvcm_header *srvcmhd)
{
  char *name;
  int num,fail;
  u_int32_t i;
  char *params=NULL;
  void (*func)(char *)=NULL;
  u_int32_t len=0;
  int err;

/* get name */
  name=(char *) srvcmhd->srvcmhd_command;
  if (debug>=DBG_FULL)
    printf(">> srvcommand\n   name: %s\n",name);

/* send ok! */
  if ((err=respond(RESP_OK))) {
    return(err);
  }

/* fix the params */


  len=strlen(name);
  if (!len) {
    addstring("!over5 server!\n");
    err=respond(RESP_OK);
    return(err);
  }

  params=name;
  
/*** skip leading spaces ***/
  for (i=0; i<len; i++) {
    if (!(isspace(*(params++)))) break;
  }
  params--;

/*** find keyword ***/
  num=0;
  fail=TRUE;
  while ((name=commtab[num].tbl_name)) {
    func=commtab[num].tbl_func;
#ifndef LINUX_VERSION
    if (0==strnicmp((params),name,strlen(name))) {
#else
    if (0==strncasecmp((params),name,strlen(name))) {
#endif /* ! LINUX_VERSION */
      params+=strlen(name); 
      fail=FALSE;
      break;
    }
    num++;
  }

/*** skip leading spaces ***/
  for (i=0; i<len; i++) {
    if (!(isspace(*(params++)))) break;
  }
  params--;

/*** execute command ***/
  if(fail)
    addstring("?unknown command  error\n");
  else
    (func)(params);

/* send ok! */
  err=respond(RESP_OK);
  return(err);
}


/*************************************************************************
**
** AddStringVA (with varargs)
**
******/
void addstringva(char *str, ...)
{
  va_list arglist;
  char buf[512];

  va_start(arglist,str);
  vsprintf(buf, str, arglist);
  addstring(buf);
}


/*************************************************************************
**
** AddString
**
******/
void addstring(char *str)
{
  int32_t  len;
  char *ptr;

  if (debug>=DBG_FULL)
    printf("-- addstring\n");
  
  if (rs_strpointer) {
    jfree(rs_strpointer);
    rs_strpointer=NULL;
    rs_current=NULL;
    if (debug>=DBG_FULL)
      printf("-- addstring free\n");
  }

  if (str) {
    if (*str!=0) {
      len=strlen(str)+1;

      if (!(ptr=(char *) jalloc(len)))
        panic("no mem");

      memcpy(ptr,str,len);

      rs_strpointer=ptr;
      rs_current=ptr;
    }
  }
  
}

/*************************************************************************
**
** bl_srvreadstring
**
******/
int bl_srvreadstring(struct srvrs_header *srvrshd)
{
  int i,x,y;
  u_int8_t tkn;
  int width;
  int height,rows;
  struct srvrs_response srvrsrs;
  u_int8_t screen[40*25];
  char *str;
  int err;
  
/* get sizes */
  width=srvrshd->srvrshd_width;
  height=srvrshd->srvrshd_height;
  if (debug>=DBG_FULL)
    printf(">> srvreadstring\n   width: %d\n   height: %d\n",width,height);

/* clear screen! */
  for (i=0; i<width*height; i++)
    screen[i]=0x20;


  str=rs_current;

/* if no string */
  if (!(rs_current)) {
    srvrsrs.srvrsrs_response=RESP_OK;
    srvrsrs.srvrsrs_rows=0x00;
    err=writeblock((u_int8_t *)&srvrsrs,sizeof(struct srvrs_response),15);
    return(err);
  }

/* if null string */
  if (*str==0) {
    srvrsrs.srvrsrs_response=RESP_OK;
    srvrsrs.srvrsrs_rows=0x00;
    err=writeblock((u_int8_t *)&srvrsrs,sizeof(struct srvrs_response),15);
    return(err);
  }



/* Build screen! */
  x=0;
  y=0;
  while ((tkn=*str++)) {
    switch (tkn) {
      case '\n':
        x=0;
        y++;
        break;
      default:
        tkn=toupper(tkn);
        screen[x+(y*width)]=tkn & 0x3f;
        x++;
        break;
    }
    if (x==width) {
      x=0;
      y++;
    }
    if (y>(height-5)) break;
  }

/** do newline if its not done */
  if (tkn==0 && x!=0) {
    x=0;
    y++;
  }

/** is next byte the end? **/
  if (tkn!=0) {
    if (*(str)==0)
      tkn=0;
  }

/** set info **/
  rows=y;
  rs_current=str;

  if (tkn==0) {
    addstring(NULL);
  } else {
    rows|=0x80;
  }

/* send ok! */
  srvrsrs.srvrsrs_response=RESP_OK;
  srvrsrs.srvrsrs_rows=rows;
  if ((err=writeblock((u_int8_t *)&srvrsrs,sizeof(struct srvrs_response),15)))
  {
    return(err);
  }

/* wait ok */
  if ((err=checkresponse(0,0,0))) {
    return(err);
  }

/* send data */
  err=sendbody(screen,width*(rows&0x7f));

  return(err);
}




/*************************************************************************
**
** LOADFILE
**
******/
u_int8_t *srv_loadfile(char *name)
{
  FILE *fp;
  int size=0;
  u_int8_t *ptr=NULL;

  if (!(fp=fopen(name,"rb"))) {
    addstring("?file not found  error\n");
    return(NULL);
  }
  fseek(fp,0,SEEK_END);
  size=ftell(fp);
  ptr=(u_int8_t *) jalloc(size);
  fseek(fp,0,SEEK_SET);

  fread(ptr,1,size,fp);
  fclose(fp);

  return(ptr);  

}

/*************************************************************************
**
** SAVEFILE
**
******/
int srv_savefile(char *name,u_int8_t *ptr, u_int32_t size)
{
  FILE *fp;

  if (!(fp=fopen(name,"wb"))) {
    addstring("?couldn't save  error\n");
    return(0);
  }
  if (!(size==0 || ptr==NULL))
    fwrite(ptr,1,size,fp);

  fclose(fp);
  return(-1);

}



/*************************************************************************
**
** command_CD
**
******/
void command_CD(char *dirname)
{
  char strbuf[80];

  if (0==strlen(dirname)) {
    if (getcwd(strbuf,80)) {
      /* Relies on the fact that str2petscii can handle src==dest */
      str2petscii(strbuf,strbuf,80);
      addstringva("%s\n",strbuf);
    } else  {
      addstring("?COULD NOT GET DIR  ERROR\n");
    }
    return;
  }

  if (chdir(dirname))
    addstring("?DIR NOT FOUND  ERROR\n");

}


/*************************************************************************
**
** command_DIR
**
******/
void command_DIR(char *str)
{
  struct mach_direntry *mde; 
  struct mach_dirlock *mdl; 

  FILE  *tmpfp=NULL;
  char *ptr=NULL;
  char *tempname=NULL;
  char *name=NULL;
  int blocks=0;
  int size=0;
  char buf[256];


  tempname=tmpnam(NULL);
/*** build directory ***/
  if (!(tmpfp=fopen(tempname,"wb")))
    panic("couldn't open tempfile");


/*** lock current dir ***/
  if (!(mdl=mach_lockdir(""))) {
    addstring("?couldn't lock  error\n");
    fclose(tmpfp);
    return;
  }


/*** get entries ***/
  while ((mde=mach_examine(mdl))) {
    size=mde->size;
    name=mde->name;
    blocks=(size+253)/254;
    buf[0]='"';
    buf[81]=0;
    strncpy(&buf[1],name,80);
    buf[strlen(buf)]='"';
    buf[strlen(buf)]=0;

    if ((mde->type)<0) 
      fprintf(tmpfp,"%-3d %-19s %s\n",blocks,buf,"PRG");
    else
      fprintf(tmpfp,"%-3d %-19s %s\n",0,buf,"DIR");
  }


/* end */
  fputc(0,tmpfp);
  mach_unlockdir(mdl);
  fclose(tmpfp);

/*** show directory ***/
  ptr=(char *) LoadFile(tempname);
  addstring(ptr);
  jfree(ptr);
  remove(tempname);

}
