
/*************************************************************************
**
** o5_Disk.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Commands: WRITEDISK, WRITEZIP, READDISK, READZIP
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>

#include "util.h"
#include "main.h"
#include "protocol.h"
#include "convert.h"
#include "cbm.h"
#include "mach.h"

#include "o5.h"

#define WD_TEMPLATE "FROM/A,DEVICE/N,DEBUG/S"

struct wd_args {
    char *as_from;
    u_int32_t *as_device;
    u_int32_t as_debug;
};

#define WZ_TEMPLATE "FROM/A,DEVICE/N,DEBUG/S"

struct wz_args {
    char *as_from;
    u_int32_t *as_device;
    u_int32_t as_debug;
};

#define RD_TEMPLATE "TO/A,DEVICE/N,DEBUG/S"

struct rd_args {
    char *as_to;
    u_int32_t *as_device;
    u_int32_t as_debug;
};

#define RZ_TEMPLATE "TO/A,DEVICE/N,DEBUG/S"

struct rz_args {
    char *as_to;
    u_int32_t *as_device;
    u_int32_t as_debug;
};

struct rd_args rd_argarray;
struct wd_args wd_argarray;
struct rz_args rz_argarray;
struct wz_args wz_argarray;


void readdisk(u_int8_t *inbuffer,int device);
void writedisk(u_int8_t *inbuffer,int device);

/*************************************************************************
**
** WRITEDISK
**
******/
void o5_WriteDisk(int argc, char **argv)
{
    u_int8_t *inbuffer=NULL;
    char *filename;
    u_int32_t len;
    int device;
  
    if (!(mach_rdargs(WD_TEMPLATE,(int32_t *)&wd_argarray,argc,argv)))
	panic("error in args");
    if (wd_argarray.as_debug)
	debug=DBG_FULL;

    filename=wd_argarray.as_from;

    inbuffer=LoadFile(filename);
    len=jsize(inbuffer);

     /* Should this allow
	len==175531 (35 trk + error info)
	len==196608 (40 trk)
	len==197376 (40 trk + error info) also? */ 
    if (len!=174848) 
	panic("wrong size of diskimage %d",len);


    device=o5config.device;
    if (wd_argarray.as_device)
	device=*(wd_argarray.as_device);

    writedisk(inbuffer,device);


    printf("Ok!\n");
}



/*************************************************************************
**
** WRITEZIP
**
******/
void o5_WriteZip(int argc, char **argv)
{
    u_int8_t *inbuffer=NULL;
    char *fromname;
    char *filename;
    char path[MACH_PATHLEN];
    u_int32_t len;
    int device;

    if (!(mach_rdargs(WZ_TEMPLATE,(int32_t *)&wz_argarray,argc,argv)))
	panic("error in args");
    if (wz_argarray.as_debug)
	debug=DBG_FULL;

    fromname=wz_argarray.as_from;


    filename=mach_getpath(fromname,path,MACH_PATHLEN);
  
    /* if name begins with "<1,2,3,4>!" skip the first two chars */
    if (strlen(filename)>2) {
	if ((*(filename+1)=='!') && (*(filename)>='1') && (*(filename)<='4')) { 
	    filename+=2;
	}
    }


    len=174848;
    if (!(inbuffer=jalloc(len)))
	panic("no mem");

    printf("unzipping...\n");
    dounzip(filename,path,inbuffer);

    device=o5config.device;
    if (wz_argarray.as_device)
	device=*(wz_argarray.as_device);

    writedisk(inbuffer,device);
    /*SaveFile(filename,inbuffer,len);*/

}



/*************************************************************************
**
** READDISK
**
******/
void o5_ReadDisk(int argc, char **argv)
{
    u_int8_t *inbuffer=NULL;
    char *filename;
    u_int32_t len;
    int device;

    if (!(mach_rdargs(RD_TEMPLATE,(int32_t *)&rd_argarray,argc,argv)))
	panic("error in args");
    if (rd_argarray.as_debug)
	debug=DBG_FULL;

    filename=rd_argarray.as_to;

    len=174848;
    if (!(inbuffer=jalloc(len)))
	panic("no mem");

    device=o5config.device;
    if (rd_argarray.as_device)
	device=*(rd_argarray.as_device);

    readdisk(inbuffer,device);


    SaveFile(filename,inbuffer,len);
    printf("Ok!\n");
}


/*************************************************************************
**
** READZIP
**
******/
void o5_ReadZip(int argc, char **argv)
{
    u_int8_t *inbuffer=NULL;
    char *fromname;
    char *filename;
    char path[MACH_PATHLEN];
    u_int32_t len;
    int device;

    if (!(mach_rdargs(RZ_TEMPLATE,(int32_t *)&rz_argarray,argc,argv)))
	panic("error in args");
    if (rz_argarray.as_debug)
	debug=DBG_FULL;

    fromname=rz_argarray.as_to;

    len=174848;
    if (!(inbuffer=jalloc(len)))
	panic("no mem");

    device=o5config.device;
    if (rz_argarray.as_device)
	device=*(rz_argarray.as_device);


    filename=mach_getpath(fromname,path,MACH_PATHLEN);
  
    /* if name begins with "<1,2,3,4>!" skip the first two chars */
    if (strlen(filename)>2) {
	if ((*(filename+1)=='!') && (*(filename)>='1') && (*(filename)<='4')) { 
	    filename+=2;
	}
    }


    readdisk(inbuffer,device);
    
    printf("zipping...\n");
    dozip(filename,path,inbuffer);

    printf("Ok!\n");
}




/*************************************************************************
**
** writedisk
**
******/
void writedisk(u_int8_t *inbuffer,int device)
{
    u_int8_t *buffer=NULL;
    u_int32_t blen=0;
    char name[64];

    u_int8_t *ptr;
    int track, numtracks;

    track=1;
    numtracks=5;
    ptr=inbuffer;
    while (track<=35) {
	if (((track+numtracks-1))>35) {
	    numtracks=35-track+1;
	} 
	printf("writing %d-%d\n",track,track+numtracks-1);
	ptr=bl_sendtrack(track,numtracks,ptr,device);
	track+=numtracks;
    }

    bl_recvstatus(&buffer,&blen,device);
    petscii2str((char *) buffer,name,sizeof(name));
    printf("diskstatus: %s\n",name);
}

/*************************************************************************
**
** readdisk
**
******/
void readdisk(u_int8_t *inbuffer,int device)
{
    u_int8_t *buffer=NULL;
    u_int32_t blen=0;
    char name[64];

    u_int8_t *ptr;
    int track, numtracks;

    track=1;
    numtracks=5;
    ptr=inbuffer;
    while (track<=35) {
	if (((track+numtracks-1))>35) {
	    numtracks=35-track+1;
	} 
	printf("reading %d-%d\n",track,track+numtracks-1);
	ptr=bl_recvtrack(track,numtracks,ptr,device);
	track+=numtracks;
    }

    bl_recvstatus(&buffer,&blen,device);
    petscii2str((char *)buffer,name,sizeof(name));
    printf("diskstatus: %s\n", name);
}

/* eof */
