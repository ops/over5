
/*************************************************************************
**
** o5_File.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Commands: WRITEFILE, READFILE, COPY, DIR, STATUS, COMMAND
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#ifdef AMIGA_VERSION
#include <exec/types.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <dos/dos.h>
#include <dos/dosextens.h>
#include <dos/doshunks.h>
#include <proto/dos.h>
#include <proto/exec.h>
#endif

#include "main_rev.h"

#include "mach_include.h"
#include "main.h"
#include "block.h"
#include "o5protocol.h"
#include "protocol.h"
#include "main.h"
#include "convert.h"
#include "cbm.h"

#include "mach.h"

#define WF_TEMPLATE "FROM/A,TO/A,DEVICE/N,DEBUG/S"

struct wf_args {
  char *as_from;
  char *as_to;
  u_int32_t *as_device;
  u_int32_t as_debug;
};

#define RF_TEMPLATE "FROM/A,TO/A,DEVICE/N,DEBUG/S"

struct rf_args {
  char *as_from;
  char *as_to;
  u_int32_t *as_device;
  u_int32_t as_debug;
};

#define CP_TEMPLATE "FROM/A/M,TO/A,DEBUG/S"

struct cp_args {
  char **as_from;
  char *as_to;
  u_int32_t as_debug;
};

#define DR_TEMPLATE "DEVICE/N,DEBUG/S"

struct dr_args {
  u_int32_t *as_device;
  u_int32_t as_debug;
};

#define ST_TEMPLATE "DEVICE/N,DEBUG/S"

struct st_args {
  u_int32_t *as_device;
  u_int32_t as_debug;
};

#define CM_TEMPLATE "COMMAND/A,DEVICE/N,DEBUG/S"

struct cm_args {
  char *as_command;
  u_int32_t *as_device;
  u_int32_t as_debug;
};

struct rf_args rf_argarray;
struct wf_args wf_argarray;
struct cp_args cp_argarray;
struct dr_args dr_argarray;
struct st_args st_argarray;
struct cm_args cm_argarray;


void copyfile(char *sourcename, char *destname);
void copymatch(char *sourcename, char *destname);
int getcbmdevice(char *name);
char readcbmextension(char *name);


/*************************************************************************
**
** WRITEFILE
**
******/
void o5_WriteFile(int argc, char **argv)
{
    char *filename=NULL;
    char *toname=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;
    char name[64];
    int device;

    if (!(mach_rdargs(WF_TEMPLATE,(int32_t *)&wf_argarray,argc,argv)))
	panic("error in args");
    if (wf_argarray.as_debug)
	debug=DBG_FULL;

    filename=wf_argarray.as_from;
    toname=wf_argarray.as_to;

    device=o5config.device;
    if (wf_argarray.as_device)
	device=*(wf_argarray.as_device);

    inbuffer=LoadFile(filename);
    len=jsize(inbuffer);
    str2petscii(toname,name,sizeof(name));
    bl_sendfile(name,inbuffer,len,device);
}




/*************************************************************************
**
** READFILE
**
******/
void o5_ReadFile(int argc, char **argv)
{
    char *filename=NULL;
    char *toname=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;
    char name[64];
    int device;

    if (!(mach_rdargs(RF_TEMPLATE,(int32_t *)&rf_argarray,argc,argv)))
	panic("error in args");
    if (rf_argarray.as_debug)
	debug=DBG_FULL;

    device=o5config.device;
    if (rf_argarray.as_device)
	device=*(rf_argarray.as_device);

    filename=rf_argarray.as_from;
    toname=rf_argarray.as_to;
    str2petscii(filename,name,sizeof(name));
    bl_recvfile(name,&inbuffer,&len,device);
    SaveFile(toname,inbuffer,len);

}


/*************************************************************************
**
** COPY
**
******/
void o5_Copy(int argc, char **argv)
{
    char *filename=NULL;
    char *destname=NULL;
    char **froms;
    char *dest_filename;
    char dest_path[MACH_PATHLEN];
    char dest_fileref[MACH_FILEREFLEN];
    int numin=0;


    if (!(mach_rdargs(CP_TEMPLATE,(int32_t *)&cp_argarray,argc,argv)))
	panic("error in args");
    if (cp_argarray.as_debug)
	debug=DBG_FULL;

    froms=cp_argarray.as_from;
/*
** check in:s 
*/
    while ((filename=*froms++))
	numin++;

/*
** check dest
*/
    destname=cp_argarray.as_to;
    dest_filename=mach_getpath(destname,dest_path,MACH_PATHLEN);

/*
** If multiple sources, and one dest
** use mach_addpart to force a valid path.
*/
    if (numin>1 && strlen(dest_filename)!=0) {
	strncpy(dest_fileref,destname,MACH_FILEREFLEN);
	mach_addpart(dest_fileref,"",MACH_FILEREFLEN);
	destname=dest_fileref;
	dest_filename=mach_getpath(destname,dest_path,MACH_PATHLEN);
    } 

    froms=cp_argarray.as_from;
/*
** Do copy
*/
    while ((filename=*froms++)) {
	copymatch(filename,destname);
    }

}




/*************************************************************************
**
** DIRECTORY
**
******/
void o5_Dir(int argc, char **argv)
{
    int device;
    struct cbm_dirlock *cdl=NULL;
    struct cbm_direntry *cde=NULL;

    if (!(mach_rdargs(DR_TEMPLATE,(int32_t *)&dr_argarray,argc,argv)))
	panic("error in args");
    if (dr_argarray.as_debug)
	debug=DBG_FULL;

    device=o5config.device;
    if (dr_argarray.as_device)
	device=*(dr_argarray.as_device);

/*
** lock dir, and print header
*/
    if (!(cdl=cbm_lockdir(device)))
	panic("couldn't lock cbm dir");

    printf("%s\n",cdl->direntry.printable);

/*
** print entries
*/
    while ((cde=cbm_examine(cdl))) {
	printf("%s\n",cde->printable);
    }

/*
** print blocks free line, and unlock dir
*/
    printf("%s\n",cdl->direntry.printable);

    cbm_unlockdir(cdl);

}

/*************************************************************************
**
** STATUS
**
******/
void o5_Status(int argc, char **argv)
{
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;
    char name[64];
    int device;

    if (!(mach_rdargs(ST_TEMPLATE,(int32_t *)&st_argarray,argc,argv)))
	panic("error in args");
    if (st_argarray.as_debug)
	debug=DBG_FULL;

    device=o5config.device;
    if (st_argarray.as_device)
	device=*(st_argarray.as_device);

    bl_recvstatus(&inbuffer,&len,device);
    petscii2str((char *)inbuffer,name,sizeof(name));
    printf("diskstatus: %s\n",name);

}


/*************************************************************************
**
** COMMAND
**
******/
void o5_Command(int argc, char **argv)
{
    char *toname=NULL;
    char name[64];
    int device;

    if (!(mach_rdargs(CM_TEMPLATE,(int32_t *)&cm_argarray,argc,argv)))
	panic("error in args");
    if (cm_argarray.as_debug)
	debug=DBG_FULL;

    device=o5config.device;
    if (cm_argarray.as_device)
	device=*(cm_argarray.as_device);

    toname=cm_argarray.as_command;
    str2petscii(toname,name,sizeof(name));
    bl_sendcommand((u_int8_t *)name,strlen(name),device);

}



/*************************************************************************
**
** copyfile
**
******/
void copyfile(char *sourcename, char *destname)
{
    u_int8_t *inbuffer=NULL,*stbuf;
    u_int32_t len=0,stlen;
    char source_fileref[MACH_FILEREFLEN];
    char dest_fileref[MACH_FILEREFLEN];
    char name[MACH_FILENAMELEN];
    int srcdevice,destdevice;
    char *source_filename, *dest_filename;
    char source_path[MACH_PATHLEN], dest_path[MACH_PATHLEN];
    char source_ext='\0',dest_ext='\0';
    char temp[3];


/*
** Make internal copies of params
*/
    strncpy(source_fileref,sourcename,MACH_FILEREFLEN);
    strncpy(dest_fileref,destname,MACH_FILEREFLEN);

/*
** Split source and destination into 'file' & 'path'
*/
    srcdevice=getcbmdevice(source_fileref);
    destdevice=getcbmdevice(dest_fileref);
    if (srcdevice)
	source_ext=readcbmextension(source_fileref);
    if (destdevice)
	dest_ext=readcbmextension(dest_fileref);
    source_filename=mach_getpath(source_fileref,source_path,MACH_PATHLEN);
    dest_filename=mach_getpath(dest_fileref,dest_path,MACH_PATHLEN);



/*
** fix destination
*/
    if (strlen(dest_filename)==0) {
	mach_addpart(dest_fileref,source_filename,MACH_FILEREFLEN-1);
    }

    if (dest_ext) {
	temp[0]=',';
	temp[1]=dest_ext;
	temp[2]='\0';
	strncat(dest_fileref,temp,MACH_FILEREFLEN-1);
    }

/*
** fix source
*/
    if (source_ext) {
	temp[0]=',';
	temp[1]=source_ext;
	temp[2]='\0';
	strncat(source_fileref,temp,MACH_FILEREFLEN-1);
    }

    printf("%-20s -> %s\n",source_fileref,dest_fileref);


/*
** Split source and destination again
** because extensions where rebuilt.
*/
    source_filename=mach_getpath(source_fileref,source_path,MACH_PATHLEN);
    dest_filename=mach_getpath(dest_fileref,dest_path,MACH_PATHLEN);



/*
** read source ->
*/

    if ((srcdevice=getcbmdevice(source_fileref))) {
	str2petscii(source_filename,name,sizeof(name));
	bl_recvfile(name,&inbuffer,&len,srcdevice);
    } else {
	inbuffer=LoadFile(source_fileref);
	len=jsize(inbuffer);
    }

/*
** status
*/
    if (srcdevice) {
	bl_recvstatus(&stbuf,&stlen,srcdevice);
	petscii2str((char *)stbuf,name,sizeof(name));
	printf("diskstatus: %s\n",name);
    }


/*
** -> write destination 
*/
    if ((destdevice=getcbmdevice(dest_fileref))) {
	str2petscii(dest_filename,name,sizeof(name));
	bl_sendfile(name,inbuffer,len,destdevice);
    } else {
	SaveFile(dest_fileref,inbuffer,len);
    }

/*
** status
*/
    if (destdevice) {
	bl_recvstatus(&stbuf,&stlen,destdevice);
	petscii2str((char *)stbuf,name,sizeof(name));
	printf("diskstatus: %s\n",name);
    }

/*
** clean up!
*/
    jfree(inbuffer);
}



/*************************************************************************
**
** NAME copymatch
**
** DESCRIPTION
**  Copy with MACH wildcards.
**  Includes special case for '<8-11>:' which is interpreted
**  as the cbm-drive (1541).  Full support for wildcards on
**  byte cbm and MACH drives.
**  cbm filenames may end with ',<s,p,u,r>' which will force
**  matching of that file type. (default is PRG)
**  destination may NOT contain wildcards.
**
******/
void copymatch(char *sourcename, char *destname)
{
    char *matchname;
    char *source_filename, *dest_filename;
    char source_path[MACH_PATHLEN], dest_path[MACH_PATHLEN];
    char sname[MACH_FILEREFLEN];
    char tname[MACH_FILEREFLEN];
    char source_fileref[MACH_FILEREFLEN];
    char dest_fileref[MACH_FILEREFLEN];
    int srcdevice=0,destdevice=0;
    struct cbm_dirlock *cdl=NULL;
    struct cbm_direntry *cde=NULL;
    struct mach_dirlock *mdl=NULL;
    struct mach_direntry  *mde=NULL;

    struct mach_matchstruct *mms=NULL;
    char source_ext='\0',dest_ext='\0';
    char temp[3];

/*
** Make internal copies of params
*/
    strncpy(source_fileref,sourcename,MACH_FILEREFLEN);
    strncpy(dest_fileref,destname,MACH_FILEREFLEN);

/*
** Split source and destination into 'file' & 'path'
*/
    source_filename=mach_getpath(source_fileref,source_path,MACH_PATHLEN);
    dest_filename=mach_getpath(dest_fileref,dest_path,MACH_PATHLEN);

/*
** is source Amiga or Cbm?
*/
    srcdevice=getcbmdevice(source_fileref);
    destdevice=getcbmdevice(dest_fileref);


/*
** check if dest contains wildcards
*/
    if (!(mms=mach_parsepattern(dest_filename)))
	panic("couldn't parse pattern");
    if (mms->iswild) {
	mach_unparsepattern(mms);
	panic("wildcard destination invalid");
    }
    mach_unparsepattern(mms);

/*
** if cbm dest, strip file ext from name
*/
    if (destdevice) {
	dest_ext=readcbmextension(dest_fileref);
	if (dest_ext==0)
	    dest_ext='p';
    }

    if (srcdevice) {
	source_ext=readcbmextension(source_fileref);
	if (source_ext==0)
	    source_ext='p';
	temp[0]=',';
	temp[1]=source_ext;
	temp[2]='\0';
	strncat(source_fileref,temp,MACH_FILEREFLEN-1);
    }

/*
** Handle source name.
*/
    matchname=source_filename;
    if (!(mms=mach_parsepattern(matchname)))
	panic("couldn't parse pattern");

/*
** If multiple sources, and one dest
** use mach_addpart to force a valid path.
*/
    if (mms->iswild) {
	if (strlen(dest_filename)!=0) {
	    mach_addpart(dest_fileref,"",MACH_FILEREFLEN);
	    dest_filename=mach_getpath(dest_fileref,dest_path,MACH_PATHLEN);
	} 
    }

/*
** Put extension back on dest!
*/
    if (dest_ext) {
	temp[0]=',';
	temp[1]=dest_ext;
	temp[2]='\0';
	strncat(dest_fileref,temp,MACH_FILEREFLEN-1);
    }


    if (mms->iswild) {

/*
** Do wildcard copy 
**
*/
	if (srcdevice) {
/*
** lock dir (cbm)
*/
	    if (!(cdl=cbm_lockdir(srcdevice)))
		panic("couldn't lock cbm dir");

/*
** test entries (cbm)
*/
	    while ((cde=cbm_examine(cdl))) {
  
/*
** handle cbm extension
*/
		switch(cde->type) {
		case CDET_SEQ:
		    source_ext='s';
		    break;
		case CDET_PRG:
		    source_ext='p';
		    break;
		case CDET_USR:
		    source_ext='u';
		    break;
		case CDET_REL:
		    source_ext='r';
		    break;
		default:
		    source_ext='\0';
		    break;
		}
		if (!source_ext) continue;

		/* match filename */
		strncpy(tname,cde->name,sizeof(tname)-1);
		temp[0]=',';
		temp[1]=source_ext;
		temp[2]=0;
		strncat(tname,temp,sizeof(tname)-1);

		if (!mach_matchpattern(mms, tname))
		    continue;

		strcpy(sname,source_path);
		mach_addpart(sname,tname,sizeof(sname));
		copyfile(sname,dest_fileref);
	    }
/*
**  unlock dir (cbm)
*/

	    cbm_unlockdir(cdl);

	} else {

/*
** lock dir (mach)
*/
	    if (!(mdl=mach_lockdir(source_path)))
		panic("couldn't lock dir");

/*
** test entries (mach)
*/
	    while ((mde=mach_examine(mdl))) {
  
		/* is directory */
		if (mach_isdir(mde)) 
		    continue;
		/* match filename */
		if (!mach_matchpattern(mms, mde->name))
		    continue;
		
		strcpy(sname,source_path);
		mach_addpart(sname,mde->name,sizeof(sname));
		copyfile(sname,dest_fileref);
	    }
/*
**  unlock dir (mach)
*/

	    mach_unlockdir(mdl);
	}
    } else {

/*
** Do normal copy 
**
*/
	copyfile(source_fileref,dest_fileref);
    }

/*
** clean up! 
**
*/
    mach_unparsepattern(mms);
}



/*************************************************************************
**
** getcbmdevice
**
** INPUT: namestring
** RETURN: cbm device number (0 means no cbm file)
**
******/
int getcbmdevice(char *name)
{
    char *ptr;
    char str[16];

    strncpy(str,name,15);
    str[15]='\0';
    if (!(ptr=strchr(str,':')))
	return(0);

    *ptr='\0';

    return(atoi(str));
}


/*************************************************************************
**
** readcbmextension
** gets extension and removes from string
** INPUT: namestring
** RETURN: cbm extension letter ('\0' means no cbm ext)
**
******/
char readcbmextension(char *name)
{
    char *ptr;
    char tkn;

    if (!(ptr=strchr(name,',')))
	return('\0');
    else {
	*ptr++='\0';
	tkn=tolower(*ptr);
	switch(tkn) {
	case 's':
	case 'p':
	case 'u':
	case 'r':
	    break;
	default:
	    panic("invalid cbm extension '%c'",tkn);
	}
	return(tkn);
    }
}

