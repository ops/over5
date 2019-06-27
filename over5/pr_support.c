
/*************************************************************************
**
** pr_support.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include <string.h>

#include "config.h"

#include "util.h"
#include "o5protocol.h"
#include "block.h"
#include "main.h"

#include "protocol.h"

#define BSIZE 256



/*************************************************************************
**
** Skicka block med handskakning!
** panic on error.
**
******/
void writeblock_err(u_int8_t *dataptr, u_int32_t datalen, int channel)
{
    if (writeblock(dataptr,datalen,channel))
	panic("writeblock failed");
}


/*************************************************************************
**
** Ta emot block med handskakning!
** panic on error.
**
******/
void readblock_err(u_int8_t *dataptr, u_int32_t *datalen, int *channel,int initialtimeout)
{
    if (readblock(dataptr,datalen,channel,initialtimeout))
	panic("readblock failed");
}


/*************************************************************************
**
** Ta emot BODY!
** panic on error.
**
******/
void receivebody_err(u_int8_t *dataptr, u_int32_t datalen)
{
    if (receivebody(dataptr,datalen))
	panic("receivebody failed");
}


/*************************************************************************
**
** Skicka BODY!
** panic on error.
**
******/
void sendbody_err(u_int8_t *dataptr, u_int32_t datalen)
{
    if (sendbody(dataptr,datalen))
	panic("sendbody failed");
}


/*************************************************************************
**
** Kolla statuskoder
** panic on error.
**
******/
void checkresponse_err(u_int8_t *buf, u_int32_t len, int timeout)
{
    int err;

    if ((err=checkresponse(buf,len,timeout))) {
	switch (err) {
	case PRERR_NOTSUPPORTED:
	    panic("command not supported by host");
	case PRERR_COMMANDFAILED:
	    panic("command failed");
	default:
	    panic("checkresponse failed");
	}
    }
}


/*************************************************************************
**
** skicka statuskoder
** panic on error.
**
******/
void respond_err(u_int8_t status)
{
    if (respond(status))
	panic("respond failed");
}

/*************************************************************************
**
** Ta emot BODY!
**
******/
int receivebody(u_int8_t *dataptr, u_int32_t datalen)
{
    int channel;
    u_int8_t *tempptr;
    u_int32_t blen;
    int32_t templen;
    int err;

/*** receive body on channel 1 ***/
    templen=datalen;
    tempptr=dataptr;
    while(templen>0) {
	if ((err=readblock(tempptr,&blen,&channel,0)))
	    return(err);
	if (channel!=1)
	    return(PRERR_UNEXPECTEDPACKET); //panic("unexpected packet");
	templen-=blen;
	tempptr+=blen;
    }

    return(PRERR_OK);
}

/*************************************************************************
**
** Skicka BODY!
**
******/
int sendbody(u_int8_t *dataptr, u_int32_t datalen)
{
    u_int8_t *tempptr;
    u_int32_t templen;
    int err;

/*** send body on channel 1 ***/
    templen=datalen;
    tempptr=dataptr;
    while(templen>BSIZE) {
	if ((err=writeblock(tempptr,BSIZE,1)))
	    return(err);
	templen-=BSIZE;
	tempptr+=BSIZE;
    }
    if ((err=writeblock(tempptr,templen,1)))
	return(err);
    return(PRERR_OK);
}


/*************************************************************************
**
** Kolla statuskoder
**
******/
int checkresponse(u_int8_t *buf, u_int32_t len, int timeout)
{
    int channel;
    u_int32_t blen;
    u_int8_t temp[256];
    u_int8_t *ptr;
    int err;

    ptr=&temp[0];

/*** check status on channel 15 ***/
    if ((err=readblock(ptr,&blen,&channel,timeout)))
	return(err);
    if (channel!=15)
	return(PRERR_UNEXPECTEDPACKET); //panic("unexpected packet");
    switch (temp[0]) {
    case RESP_OK:
	break;
    case RESP_NOTSUPPORTED:
	return(PRERR_NOTSUPPORTED); //panic("command not supported by host");
    case RESP_ERROR:
	return(PRERR_COMMANDFAILED); //panic("command failed");
    default:
	return(PRERR_UNKNOWNERROR); //panic("unknown error code");
    }

    if (buf) {
	if (len) {
	    if (len!=blen)
		return(PRERR_FORMAT); //panic("error in response");
	}
	memcpy(buf,ptr,len);
    }

    return(PRERR_OK);
}

/*************************************************************************
**
** skicka statuskoder
**
******/
int respond(u_int8_t status)
{
    u_int8_t temp;
    int err;
    temp=status;
    err=writeblock(&temp,1,15);
    return(err);
}

/* eof */
