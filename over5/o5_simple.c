
/*************************************************************************
**
** o5_Simple.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Commands: SIMPLEWRITE, SIMPLEREAD, BOOT, TEST
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>
#include <string.h>

#include "util.h"
#include "protocol.h"
#include "main.h"
#include "copytail64.h"
#include "booter.h"
#include "convert.h"
#include "mach.h"

#include "o5.h"

#define SW_TEMPLATE "FROM/A"

struct sw_args {
    char *as_from;
};

#define SR_TEMPLATE "TO/A"

struct sr_args {
    char *as_to;
};

#define BT_TEMPLATE "FROM/A,SAFEADDR,OLD/S"

struct bt_args {
    char *as_from;
    char *as_safeaddr;
    u_int32_t as_old;
};

#define TS_TEMPLATE "BLOCK/S,FILE/S,DEBUG/S"

struct ts_args {
    u_int32_t as_block;
    u_int32_t as_file;
    u_int32_t as_debug;
};

struct sr_args sr_argarray;
struct sw_args sw_argarray;
struct bt_args bt_argarray;
struct ts_args ts_argarray;

void oldboot(u_int8_t *buffer, u_int32_t len, u_int32_t safeaddr);
void newboot(u_int8_t *buffer, u_int32_t len);
u_int8_t *stuffit(u_int8_t *buffer, u_int32_t len, u_int8_t *ptr);
void stuffchecksum(u_int8_t *buffer, u_int32_t len);



/*************************************************************************
**
** SIMPLEWRITE
**
******/
void o5_SimpleWrite(int argc, char **argv)
{
    char *filename=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;

    if (!(mach_rdargs(SW_TEMPLATE,(int32_t *)&sw_argarray,argc,argv)))
	panic("error in args");

    filename=sw_argarray.as_from;

    inbuffer=LoadFile(filename);
    len=jsize(inbuffer);

    sendfile(inbuffer,len);

}





/*************************************************************************
**
** SIMPLEREAD
**
******/
void o5_SimpleRead(int argc, char **argv)
{
    char *filename=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;

    if (!(mach_rdargs(SR_TEMPLATE,(int32_t *)&sr_argarray,argc,argv)))
	panic("error in args");

    filename=sr_argarray.as_to;

    receivefile(&inbuffer,&len);

    SaveFile(filename,inbuffer,len);
}





/*************************************************************************
**
** BOOT
**
******/
void o5_Boot(int argc, char **argv)
{
    char *filename=NULL;
    u_int8_t *buffer=NULL;
    int32_t safeaddr;
    u_int32_t len=0;

    if (!(mach_rdargs(BT_TEMPLATE,(int32_t *)&bt_argarray,argc,argv)))
	panic("error in args");

    filename=bt_argarray.as_from;
    buffer=LoadFile(filename);
    len=jsize(buffer);

/* c64 safeaddr */
    safeaddr=0xc000;
    if (bt_argarray.as_safeaddr) {
	safeaddr=makenum(bt_argarray.as_safeaddr,0x0000,0xffff,16);
	if (safeaddr==-1)
	    panic("illegal SAFEADDR");
    } 

    if (bt_argarray.as_old) {
	oldboot(buffer,len,safeaddr);
    } else {
        newboot(buffer,len);
    }

}

/*************************************************************************
**
** oldboot
**
******/
void oldboot(u_int8_t *buffer, u_int32_t len, u_int32_t safeaddr)
{
    u_int8_t *newbuffer=NULL;
    u_int32_t addr,endaddr;
    u_int32_t newaddr;
    u_int8_t *dataptr,*ptr;
    u_int32_t datalen;
    u_int32_t newlen;

    if (!(newbuffer=(u_int8_t *) jalloc(32768)))
	panic("no mem");

/*
** calculate relevant info
*/
    dataptr=buffer+2;
    datalen=len-2;
    addr=*buffer+(*(buffer+1)<<8);
    endaddr=addr+datalen;
    printf("Loaded $%04x-$%04x, relocating and appending copytail...\n",addr,endaddr);

/*
** setnewaddr
*/
    newaddr=safeaddr-datalen;

/*
** build new file
*/
    *newbuffer=newaddr&0xff;
    *(newbuffer+1)=newaddr>>8;
    memcpy((newbuffer+2),dataptr,datalen);
    ptr=newbuffer+2+datalen;

/*
** append copytail
*/
    memcpy(ptr,tail,sizeof(tail));
    ptr+=sizeof(tail);

/*
** append params
*/
    *ptr++=newaddr&0xff;
    *ptr++=newaddr>>8;
    *ptr++=addr&0xff;
    *ptr++=addr>>8;
    *ptr++=endaddr&0xff;
    *ptr++=endaddr>>8;
    *ptr++=(datalen+255)>>8;
    newlen=ptr-newbuffer;
  
/*
** send away
*/
    slowsendold(newbuffer,newlen);
}


/*************************************************************************
**
** newboot
**
******/
void newboot(u_int8_t *buffer, u_int32_t len)
{
    u_int8_t *newbuffer=NULL;
    u_int8_t *ptr;
    u_int32_t i;
    int32_t stuff,unstuffend;
    u_int32_t newlen;
    u_int8_t last;
    int counters[256];
    int code;

    if (!(newbuffer=(u_int8_t *) jalloc(32768)))
	panic("no mem");

/*** new boot ***/


/*
** search for 0xea,0xea start mark
** NO occurances of 0x00 byte before start mark allowed
** byte stuffing starts after the start mark
*/
    ptr=newbuffer;
    last=0x00;
    stuff=FALSE;
    for (i=0; i<sizeof(booter); i++) {
	if (booter[i]==0xea && last==0xea) {
	    stuff=TRUE;
	    break;
	}
	*ptr++=booter[i];
	if (booter[i]==0x00)
	    panic("(internal) null byte in unstuffer at 0x%03x",i);
	last=booter[i];
    }
    if (stuff==FALSE)
	panic("(internal) no start mark in booter");

    unstuffend=i;

/*
**
** Hunt for a byte that is not used at all. (may not be 0x00)
**
*/
    for (i=0; i<256; i++)
	counters[i]=0;

    for (i=unstuffend; i<sizeof(booter); i++)
	counters[booter[i]]++;

    code=-1;
    for (i=1; i<256; i++) {
	if (counters[i]==0) {
	    code=i;
	    break;
	}
    }
    if (code==-1)
	panic("(internal) no code");
  
/*
**
** Translate all occurances of 0x00 to 'code'
**
*/

    for (i=unstuffend; i<sizeof(booter); i++) {
	if (booter[i]==0x00)
	    *ptr++=code;
	else
	    *ptr++=booter[i];
    }
/*
** insert code at the third byte!
*/
    newbuffer[2]=code;

/*
** calculate checksum on data
** except for the last two bytes
*/
    stuffchecksum(newbuffer,0x1fe);

/*
** send away booter at 150 baud
*/
    slowsend(newbuffer,0x200,150,"BOOTER");


/*
** code the actual data!
** skip the first two bytes... as we always load into basic start.
** insert and 0x11,0x01 ENDMARK between the data and the checksum
*/
    ptr=stuffit(buffer+2,len-2,newbuffer);
    newlen=ptr-newbuffer;
    newbuffer[newlen]=0x11;
    newbuffer[newlen+1]=0x01;
    stuffchecksum(newbuffer,newlen+2);
    newlen+=4;
/*
** send away the program at 600 baud
*/
    slowsend(newbuffer,newlen,600,"DATA");

    puts("Ok!");
}


/*************************************************************************
**
** Deep shit byte stuffer.
** 0x11 -> 0x11,0x11   0x00 -> 0x11,0x80
**
******/
u_int8_t *stuffit(u_int8_t *buffer, u_int32_t len, u_int8_t *ptr)
{
    u_int32_t i;
    for (i=0; i<len; i++) {
	switch (buffer[i]) {
	case 0x00:
	    *ptr++=0x11;
	    *ptr++=0x80;
	    break;
	case 0x11:
	    *ptr++=0x11;
	    *ptr++=0x11;
	    break;
	default:
	    *ptr++=buffer[i];
	    break;
	}
    }

    return(ptr);
}

/*************************************************************************
**
** stuffchecksum
** calculate and append checksum (no null bytes)
**
******/
void stuffchecksum(u_int8_t *buffer, u_int32_t len)
{
    u_int32_t i;
    u_int8_t chk,sum;

/*
** calculate checksum on data
*/
    sum=0;
    for (i=0; i<len; i++) {
	sum+=buffer[i];
    }
    chk=-sum;

/*
** tricky checksum...  (no null bytes! remember?)
*/
    if (chk!=1) {
	buffer[len]=0x01;
	buffer[len+1]=chk-1;
    } else {
	buffer[len]=0x02;
	buffer[len+1]=chk-2;
    }
}





/*************************************************************************
**
** TEST
**
******/
void o5_Test(int argc, char **argv)
{

    if (!(mach_rdargs(TS_TEMPLATE,(int32_t *)&ts_argarray,argc,argv)))
	panic("error in args");

    if (!(ts_argarray.as_block || ts_argarray.as_file))
	panic("error in args");

    if (ts_argarray.as_debug)
	debug=DBG_FULL;
    if (ts_argarray.as_block)
	bl_blocktest();
    if (ts_argarray.as_file)
	bl_filetest();

}

/* eof */


