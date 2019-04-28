
/*************************************************************************
**
** o5_Memory.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Commands: WRITEMEM, READMEM, SYS, RUN, RESET
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>

#include "util.h"
#include "block.h"
#include "protocol.h"
#include "main.h"
#include "convert.h"
#include "mach.h"

#include "o5.h"

#define WM_TEMPLATE "FROM/A,NEWADDR,RUN/S,RESET/S,DEBUG/S"

struct wm_args {
    char *as_from;
    char *as_newaddr;
    u_int32_t as_run;
    u_int32_t as_reset;
    u_int32_t as_debug;
};

#define RM_TEMPLATE "START/A,END/A,TO/A,RESET/S,DEBUG/S"

struct rm_args {
    char *as_start;
    char *as_end;
    char *as_to;
    u_int32_t as_reset;
    u_int32_t as_debug;
};

#define SY_TEMPLATE "PC/A,MEMORY,SR,AC,XR,YR,SP,RESET/S,DEBUG/S"

struct sy_args {
    char *as_pc;
    char *as_memory;
    char *as_sr;
    char *as_ac;
    char *as_xr;
    char *as_yr;
    char *as_sp;
    u_int32_t as_reset;
    u_int32_t as_debug;
};

#define RU_TEMPLATE "DEBUG/S"

struct ru_args {
    u_int32_t as_debug;
};


#define RST_TEMPLATE "DEBUG/S"

struct rst_args {
    u_int32_t as_debug;
};

struct rm_args rm_argarray;
struct wm_args wm_argarray;
struct sy_args sy_argarray;
struct ru_args ru_argarray;
struct rst_args rst_argarray;

/*************************************************************************
**
** WRITEMEM
**
******/
void o5_WriteMem(int argc, char **argv)
{
    char *filename=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;
    int32_t  newaddr,addr,endaddr,blocks;

    if (!(mach_rdargs(WM_TEMPLATE,(int32_t *)&wm_argarray,argc,argv)))
	panic("error in args");

    if (wm_argarray.as_debug)
	debug=DBG_FULL;

    filename=wm_argarray.as_from;

    inbuffer=LoadFile(filename);
    len=jsize(inbuffer);
    addr=(*inbuffer)+(*(inbuffer+1)<<8);
    if (wm_argarray.as_newaddr) {
	newaddr=makenum((char *) wm_argarray.as_newaddr,0x0000,0xffff,16);
	if (newaddr==-1)
	    panic("illegal NEWADDR");
	addr=newaddr;
    }
    endaddr=addr+len-2;

    blocks=((len+253)/254);
    printf("Writing $%04x-$%04x (%d bytes, %d blocks)\n",addr,endaddr,len-2,blocks);

    if (wm_argarray.as_reset)
	doreset();
    bl_sendmem(inbuffer+2,addr,len-2);

    if (wm_argarray.as_run) {
	bl_run(addr,endaddr);
	puts("RUN");
    }
}





/*************************************************************************
**
** READMEM
**
******/
void o5_ReadMem(int argc, char **argv)
{
    char *filename=NULL;
    u_int8_t *inbuffer=NULL;
    u_int32_t len=0;
    int32_t  start,end,blocks;

    if (!(mach_rdargs(RM_TEMPLATE,(int32_t *)&rm_argarray,argc,argv)))
	panic("error in args");

    if (rm_argarray.as_debug)
	debug=DBG_FULL;

    start=makenum(rm_argarray.as_start,0x0000,0xffff,16);
    if (start==-1)
	panic("illegal START");
    end=makenum(rm_argarray.as_end,0x0000,0xffff,16);
    if (end==-1)
	panic("illegal END");
    filename=rm_argarray.as_to;

    len=end-start;
    if (end==0)
	len=0x10000-start;

    if (!(inbuffer=jalloc(len+2)))
	panic("no mem");


    blocks=(((len+2)+253)/254);
    printf("Reading $%04x-$%04x (%d bytes, %d blocks)\n",start,end,len,blocks);


    *inbuffer=start&0xff;
    *(inbuffer+1)=start>>8;
    if (rm_argarray.as_reset)
	doreset();
    bl_recvmem(inbuffer+2,start,len);
    SaveFile(filename,inbuffer,len+2);
}



/*************************************************************************
**
** SYS
**
******/
void o5_Sys(int argc, char **argv)
{
    int32_t  pc;
    int32_t memory=0x37,sr=0x00,ac=0x00,xr=0x00,yr=0x00,sp=0xff;

    if (!(mach_rdargs(SY_TEMPLATE,(int32_t *)&sy_argarray,argc,argv)))
	panic("error in args");

    if (sy_argarray.as_debug)
	debug=DBG_FULL;

    pc=makenum(sy_argarray.as_pc,0x0000,0xffff,16);
    if (pc==-1)
	panic("illegal PC");

    if (sy_argarray.as_memory) {
	memory=makenum(sy_argarray.as_memory,0x00,0xff,16);
	if (memory==-1)
	    panic("illegal MEMORY");
    }
    if (sy_argarray.as_sr) {
	sr=makenum(sy_argarray.as_sr,0x00,0xff,16);
	if (sr==-1)
	    panic("illegal SR");
    }
    if (sy_argarray.as_ac) {
	ac=makenum(sy_argarray.as_ac,0x00,0xff,16);
	if (ac==-1)
	    panic("illegal AC");
    }
    if (sy_argarray.as_xr) {
	xr=makenum(sy_argarray.as_xr,0x00,0xff,16);
	if (xr==-1)
	    panic("illegal XR");
    }
    if (sy_argarray.as_yr) {
	yr=makenum(sy_argarray.as_yr,0x00,0xff,16);
	if (yr==-1)
	    panic("illegal YR");
    }
    if (sy_argarray.as_sp) {
	sp=makenum(sy_argarray.as_sp,0x00,0xff,16);
	if (sp==-1)
	    panic("illegal SP");
    }

    if (sy_argarray.as_reset)
	doreset();
    bl_sys(pc,memory,sr,ac,xr,yr,sp);
    printf(" PC  01 SR AC XR YR SP\n");
    printf("%04x %02x %02x %02x %02x %02x %02x\n",pc,memory,sr,ac,xr,yr,sp);
    printf("AWAY!!!\n");
}


/*************************************************************************
**
** RUN
**
******/
void o5_Run(int argc, char **argv)
{
    if (!(mach_rdargs(RU_TEMPLATE,(int32_t *)&ru_argarray,argc,argv)))
	panic("error in args");

    if (ru_argarray.as_debug)
	debug=DBG_FULL;

    panic("not yet implemented");
}


/*************************************************************************
**
** RESET
**
******/
void o5_Reset(int argc, char **argv)
{
    if (!(mach_rdargs(RST_TEMPLATE,(int32_t *)&rst_argarray,argc,argv)))
	panic("error in args");

    if (rst_argarray.as_debug)
	debug=DBG_FULL;

    doreset();
    printf("reset sent!\n");
}

/* eof */
