
/*************************************************************************
**
** pr_Protocol.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Handle Highlevelprotocol
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#ifdef IRR_PROFILING
#include <time.h>
#endif /* IRR_PROFILING */

#include "util.h"
#include "o5protocol.h"

#include "protocol.h"

#define BSIZE 256


/*************************************************************************
**
** skriv till c64 minne
**
******/
void bl_sendmem(u_int8_t *buffer,u_int32_t addr, u_int32_t len)
{
    struct wm_header wmhd;
    u_int32_t endaddr;


/*** calculate relevant info ***/
    endaddr=addr+len;

/*** send COMMAND on channel 15 ***/
    wmhd.wmhd_type=TYPE_MEMTRANSFER;
    wmhd.wmhd_subtype=SUB_MT_WRITEMEM;
    wmhd.wmhd_start_l=addr&0xff;
    wmhd.wmhd_start_h=(addr>>8)&0xff;
    wmhd.wmhd_end_l=endaddr&0xff;
    wmhd.wmhd_end_h=(endaddr>>8)&0xff;
    writeblock_err((u_int8_t *)&wmhd,sizeof(struct wm_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** send body on channel 1 ***/
    sendbody_err(buffer,len);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

}

/*************************************************************************
**
** Ta emot minne från c64
**
**
******/
void bl_recvmem(u_int8_t *buffer,u_int32_t addr, u_int32_t len)
{
    struct rm_header rmhd;
    u_int32_t endaddr;

/*** calculate relevant info ***/
    endaddr=addr+len;

/*** send COMMAND on channel 15 ***/
    rmhd.rmhd_type=TYPE_MEMTRANSFER;
    rmhd.rmhd_subtype=SUB_MT_READMEM;
    rmhd.rmhd_start_l=addr&0xff;
    rmhd.rmhd_start_h=(addr>>8)&0xff;
    rmhd.rmhd_end_l=endaddr&0xff;
    rmhd.rmhd_end_h=(endaddr>>8)&0xff;
    writeblock_err((u_int8_t *)&rmhd,sizeof(struct rm_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** receive body on channel 1 ***/
    receivebody_err(buffer,len);

/*** send ok! ***/
    respond_err(RESP_OK);

}

/*************************************************************************
**
**
******/
void bl_sys(u_int32_t pc, u_int8_t memory, u_int8_t sr, u_int8_t ac, u_int8_t xr, u_int8_t yr, u_int8_t sp)
{
    struct sy_header syhd;

/*** send COMMAND on channel 15 ***/
    syhd.syhd_type=TYPE_MEMTRANSFER;
    syhd.syhd_subtype=SUB_MT_SYS;
    syhd.syhd_pc_l=pc&0xff;
    syhd.syhd_pc_h=(pc>>8)&0xff;
    syhd.syhd_memory=memory;
    syhd.syhd_sr=sr;
    syhd.syhd_ac=ac;
    syhd.syhd_xr=xr;
    syhd.syhd_yr=yr;
    syhd.syhd_sp=sp;
    writeblock_err((u_int8_t *)&syhd,sizeof(struct sy_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);
}

/*************************************************************************
**
**
******/
void bl_run(u_int32_t lowmem, u_int32_t himem)
{
    struct ru_header ruhd;

/*** send COMMAND on channel 15 ***/
    ruhd.ruhd_type=TYPE_MEMTRANSFER;
    ruhd.ruhd_subtype=SUB_MT_RUN;
    ruhd.ruhd_lowmem_l=lowmem&0xff;
    ruhd.ruhd_lowmem_h=(lowmem>>8)&0xff;
    ruhd.ruhd_himem_l=himem&0xff;
    ruhd.ruhd_himem_h=(himem>>8)&0xff;
    writeblock_err((u_int8_t *)&ruhd,sizeof(struct ru_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);
}



/*************************************************************************
**
** Skicka fil med block
**
******/
void bl_sendfile(char *filename,u_int8_t *buffer,u_int32_t len,int device)
{
    u_int8_t *dataptr;
    u_int32_t datalen;
    struct wf_header wfhd;
    u_int32_t blocks;


/*** calculate relevant info ***/
    dataptr=buffer;
    datalen=len;
    blocks=((len+253)/254);
    printf("Sending (%d bytes, %d blocks)...\n",len,blocks);


/*** send COMMAND on channel 15 ***/
    wfhd.wfhd_type=TYPE_FILETRANSFER;
    wfhd.wfhd_subtype=SUB_FT_WRITEFILE;
    wfhd.wfhd_len_l=datalen&0xff;
    wfhd.wfhd_len_h=(datalen>>8)&0xff;
    wfhd.wfhd_device=device;
    strncpy(wfhd.wfhd_filename,filename,HEADER_FILENAMELEN);
    writeblock_err((u_int8_t *)&wfhd,sizeof(struct wf_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** send body on channel 1 ***/
    sendbody_err(dataptr,datalen);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** check status again on channel 15 ***/
    checkresponse_err(0,0,TIMEOUT_FILEWAIT);

}

/*************************************************************************
**
** Ta emot fil!
**
**
******/
void bl_recvfile(char *filename,u_int8_t **buffer_st, u_int32_t *len_st, int device)
{
    u_int8_t *dataptr;
    u_int32_t datalen;
    struct rf_header rfhd;
    struct rf_response rfrs;
    u_int32_t blocks;


/*** send COMMAND on channel 15 ***/
    rfhd.rfhd_type=TYPE_FILETRANSFER;
    rfhd.rfhd_subtype=SUB_FT_READFILE;
    rfhd.rfhd_device=device;
    strncpy(&(rfhd.rfhd_filename[0]),filename,HEADER_FILENAMELEN);
    writeblock_err((u_int8_t *)&rfhd,sizeof(struct rf_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** check status again on channel 15 ***/
    checkresponse_err((u_int8_t *)&rfrs,sizeof(struct rf_response),TIMEOUT_FILEWAIT);

    datalen=rfrs.rfrs_len_l+rfrs.rfrs_len_h*256;
    blocks=((datalen+253)/254);
    printf("Receiving (%d bytes, %d blocks)...\n",datalen,blocks);
/*** malloc+ safety ***/
    if (!(dataptr=(u_int8_t *) jalloc(datalen+256)))
	panic("couldn't malloc");


/*** send ok! ***/
    respond_err(RESP_OK);

/*** receive body on channel 1 ***/
    receivebody_err(dataptr,datalen);

/*** send ok! ***/
    respond_err(RESP_OK);

    *buffer_st=dataptr;
    *len_st=datalen;

}



/*************************************************************************
**
** Ta emot Directory!
**
**
******/
void bl_recvdir(char *filename,u_int8_t **buffer_st, u_int32_t *len_st,int device)
{
    u_int8_t *dataptr;
    u_int32_t datalen;
    struct dr_header drhd;
    struct dr_response drrs;


/*** send COMMAND on channel 15 ***/
    drhd.drhd_type=TYPE_DISKCOMMAND;
    drhd.drhd_subtype=SUB_DC_DIRECTORY;
    drhd.drhd_device=device;
    strncpy(&(drhd.drhd_filename[0]),filename,HEADER_FILENAMELEN);
    writeblock_err((u_int8_t *)&drhd,sizeof(struct dr_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** check status again on channel 15 ***/
    checkresponse_err((u_int8_t *)&drrs,sizeof(struct dr_response),TIMEOUT_FILEWAIT);

    datalen=drrs.drrs_len_l+drrs.drrs_len_h*256;

/*** malloc+ safety ***/
    if (!(dataptr=(u_int8_t *) jalloc(datalen+256)))
	panic("couldn't malloc");


/*** send ok! ***/
    respond_err(RESP_OK);

/*** receive body on channel 1 ***/
    receivebody_err(dataptr,datalen);

/*** send ok! ***/
    respond_err(RESP_OK);

    *buffer_st=dataptr;
    *len_st=datalen;

}

/*************************************************************************
**
** Ta emot Status!
**
**
******/
void bl_recvstatus(u_int8_t **buffer_st, u_int32_t *len_st,int device)
{
    u_int8_t *dataptr;
    u_int32_t datalen;
    struct st_header sthd;
    int channel;


/*** malloc ***/
    if (!(dataptr=(u_int8_t *) jalloc(256)))
	panic("couldn't malloc");

/*** send COMMAND on channel 15 ***/
    sthd.sthd_type=TYPE_DISKCOMMAND;
    sthd.sthd_subtype=SUB_DC_STATUS;
    sthd.sthd_device=device;
    writeblock_err((u_int8_t *)&sthd,sizeof(struct st_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** receive body on channel 1 ***/
    readblock_err(dataptr,&datalen,&channel,0);
    if (channel!=1)
	panic("unexpected packet");

/*** send ok! ***/
    respond_err(RESP_OK);

    *buffer_st=dataptr;
    *len_st=datalen;

}

/*************************************************************************
**
** Skicka DISK COMMAND
**
******/
void bl_sendcommand(u_int8_t *buffer,u_int32_t len,int device)
{
    struct cm_header cmhd;

/*** send COMMAND on channel 15 ***/
    cmhd.cmhd_type=TYPE_DISKCOMMAND;
    cmhd.cmhd_subtype=SUB_DC_COMMAND;
    cmhd.cmhd_device=device;
    writeblock_err((u_int8_t *)&cmhd,sizeof(struct cm_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** send body on channel 1 ***/
    writeblock_err(buffer,len,1);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

}


/*************************************************************************
**
** Do transfer diagnostics! BLOCK
**
******/
void bl_blocktest()
{
    int i,j;
    int channel,recvchannel;
    u_int32_t datalen,recvlen;
    u_int8_t buffer[2048];
    u_int8_t buffer2[2048];
    struct bt_header bthd;

/*** send BLOCKTEST COMMAND on channel 15 ***/
    puts("Requesting blocktest...");
    bthd.bthd_type=TYPE_TESTCOMMAND;
    bthd.bthd_subtype=SUB_TC_BLOCKTEST;
    writeblock_err((u_int8_t *)&bthd,sizeof(struct bt_header),15);
/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);


/*** build testdata ***/
    for (i=0; i<2048; i++)
	buffer[i]=i*7;

/*** DO BLOCKTEST ***/
    puts("***testing block level...");
    for (j=0; j<16; j++) {
	channel=j;
	datalen=256-j;
	printf("sending %d bytes on channel %d...\n",datalen,channel);
	writeblock_err(&buffer[0],datalen,channel);

	recvlen=0;
	recvchannel=0;
	readblock_err(&buffer2[0],&recvlen,&recvchannel,0);
	if (recvlen!=datalen) 
	    panic("wrong length");
	if (recvchannel!=channel) 
	    panic("wrong channel");
	puts("Bounced OK!");

/*** compare blocks ***/
	for (i=0; i<256; i++) {
	    if (buffer[i]!=buffer2[i])
		panic("error in block");
	}
    }
    puts("all was ok...");
}


/*************************************************************************
**
** Do transfer diagnostics! FILE
**
******/
#define FILETESTLEN 40960
void bl_filetest()
{
    u_int32_t i;
    u_int32_t datalen,recvlen;
    u_int8_t *buffer;
    u_int8_t *buffer2;
    u_int8_t out,in;
    struct ft_header fthd;
    struct ft_response ftrs;


/*** malloc ***/
    if (!(buffer=(u_int8_t *) jalloc(FILETESTLEN)))
	panic("couldn't malloc");
    if (!(buffer2=(u_int8_t *) jalloc(FILETESTLEN)))
	panic("couldn't malloc");

/*** build testdata ***/
    for (i=0; i<FILETESTLEN; i++)
	*(buffer+i)=i*7;


/*** DO FILETEST ***/
    puts("Requesting filetest...");
    datalen=FILETESTLEN;

/*** send FILETEST COMMAND on channel 15 ***/
    fthd.fthd_type=TYPE_TESTCOMMAND;
    fthd.fthd_subtype=SUB_TC_FILETEST;
    fthd.fthd_len_l=datalen&255;
    fthd.fthd_len_h=datalen>>8;
    writeblock_err((u_int8_t *)&fthd,sizeof(struct ft_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);
    puts("sending body...");

/*** send body on channel 1 ***/
    sendbody_err(buffer,datalen);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);


    puts("Waiting for bounce...");

/*** GET THE BOUNCE ***/
    checkresponse_err((u_int8_t *)&ftrs,sizeof(struct ft_response),60);

    recvlen=ftrs.ftrs_len_l+ftrs.ftrs_len_h*256;
    if (recvlen!=datalen)
	panic("wrong length");

/*** send ok! ***/
    respond_err(RESP_OK);

    puts("receiving body...");
/*** receive body on channel 1 ***/
    receivebody_err(buffer2,recvlen);

/*** send ok! ***/
    respond_err(RESP_OK);

/*** compare files ***/
    for (i=0; i<datalen; i++) {
	out=*(buffer+i);
	in=*(buffer2+i);
	if (out!=in) {
	    printf("error @ %d   sent $%02x   got $%02x\n",i,out,in);
	    panic("error in data");
	}
    }

    puts("all was ok...");
}


int sectors[]={
    0,
    21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,
    19,19,19,19,19,19,19,
    18,18,18,18,18,18,
    17,17,17,17,17
};

/*************************************************************************
**
** Skicka Track
**
******/
u_int8_t *bl_sendtrack(int track,int numtracks,u_int8_t *buffer,int device)
{
    int i;
    struct  wt_header wthd;
    int32_t  size=0;

/*** calculate size ***/
    for (i=0; i<numtracks; i++) {
	size+=256*sectors[track+i]; 
    }

/*** send COMMAND on channel 15 ***/
    wthd.wthd_type=TYPE_RAWDISKTRANSFER;
    wthd.wthd_subtype=SUB_RT_WRITETRACK;
    wthd.wthd_track=track;
    wthd.wthd_numtracks=numtracks;
    wthd.wthd_device=device;
    writeblock_err((u_int8_t *)&wthd,sizeof(struct wt_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** send body on channel 1 ***/
    sendbody_err(buffer,size);

/*** check status again on channel 15 ***/
    checkresponse_err(0,0,TIMEOUT_FILEWAIT);


    return(buffer+size);
}



/*************************************************************************
**
** Receive Track
**
******/
u_int8_t *bl_recvtrack(int track,int numtracks,u_int8_t *buffer,int device)
{
    int i;
    struct  rt_header rthd;
    int32_t  size=0;

#ifdef IRR_PROFILING
    time_t time0, time1;
    double diff;
#endif /* IRR_PROFILING */

/*** calculate size ***/
    for (i=0; i<numtracks; i++) {
	size+=256*sectors[track+i]; 
    }

/*** send COMMAND on channel 15 ***/
    rthd.rthd_type=TYPE_RAWDISKTRANSFER;
    rthd.rthd_subtype=SUB_RT_READTRACK;
    rthd.rthd_track=track;
    rthd.rthd_numtracks=numtracks;
    rthd.rthd_device=device;
    writeblock_err((u_int8_t *)&rthd,sizeof(struct rt_header),15);

/*** check status on channel 15 ***/
    checkresponse_err(0,0,0);

/*** check status again on channel 15 ***/
    checkresponse_err(0,0,TIMEOUT_FILEWAIT);

/*** send ok! ***/
    respond_err(RESP_OK);

#ifdef IRR_PROFILING
    time(&time0);
#endif /* IRR_PROFILING */

/*** receive body on channel 1 ***/
    receivebody_err(buffer,size);

/*** send ok! ***/
    respond_err(RESP_OK);

#ifdef IRR_PROFILING
    time(&time1);
    diff = difftime(time1, time0);
    printf("** Seconds elapsed: %3.0f  Bytes recieved: %d  Bytes/Second %4.2f **\n",
	   diff, size, (double)size/diff);
#endif /* IRR_PROFILING */

    return(buffer+size);
}

/* eof */

