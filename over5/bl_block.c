
/*************************************************************************
**
** bl_Block.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#ifdef __MINGW32__
#include <dos.h>
#endif /* __MINGW32__ */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"

#include "block.h"

#define TIMEOUT_ACK 1 /* 1 second */
#define TIMEOUT_BLOCK 3 /* 3 seconds */
#define TIMEOUT_BODY  1 /* 1 second */
#define DELAY_RESEND  500000  /* .5 seconds */
#define NUM_RETRIES 3
#define DELAY_BLOCK 1800


#define ST_MASK 0xf0
#define ST_OK 0x10
#define ST_RESEND 0x20

u_int8_t thisblocknum=0;
u_int8_t receiveblocknum=0;

/*** public functions ***/
int writeblock(u_int8_t *dataptr, u_int32_t datalen, int channel);
int readblock(u_int8_t *dataptr, u_int32_t *datalen, int *channel,int initialtimeout);

/*** internal ***/
int receiveblock(u_int8_t *dataptr, u_int32_t *datalen, int *channel,
		 u_int8_t *blocknum, int initialtimeout);
void sendack(u_int8_t status, u_int32_t datalen, int channel,
	     u_int8_t blocknum);
void emitblock(u_int8_t *dataptr, u_int32_t datalen,int channel,
	       u_int8_t blocknum);
int checkack(u_int32_t datalen, int channel, u_int8_t blocknum);


#define BSIZE 256


/*************************************************************************
**
** RESET
**
******/
void doreset(void)
{
    SendBreak();
    MicroWait(250000);
    ClearSerial();
}

/*************************************************************************
**
** Skicka block med handskakning!
**
******/
int writeblock(u_int8_t *dataptr, u_int32_t datalen, int channel)
{
    int i,lasterror = BLERR_OK;

    if (datalen==0)
	return(BLERR_OK);
    if (debug>=DBG_FULL)
	printf("* Sending block %d (%d bytes) on channel %d...\n",thisblocknum,datalen,channel);

    for (i=0; i<NUM_RETRIES; i++) {
	emitblock(dataptr,datalen,channel,thisblocknum);
	lasterror=checkack(datalen,channel,thisblocknum);
	if (lasterror==BLERR_OK) break;

	if (debug>=DBG_FULL)
	    puts("  failed...");
	MicroWait(DELAY_RESEND);
    }
    if (i==NUM_RETRIES) {
	// panic("too many errors");
	return(lasterror);
    }

    thisblocknum++;

    if (debug>=DBG_FULL)
	puts("  ok!");
    MicroWait(DELAY_BLOCK);
    return(BLERR_OK);
}


/*************************************************************************
**
** Ta emot block med handskakning!
**
******/
int readblock(u_int8_t *dataptr, u_int32_t *datalen, int *channel,
	      int initialtimeout)
{
    int i,timeout,lasterror = BLERR_OK;

    if (debug>=DBG_FULL)
	puts("* Waiting for block...");

    timeout=initialtimeout;

    for (i=0; i<NUM_RETRIES; i++) {
	lasterror=receiveblock(dataptr,datalen,channel,&receiveblocknum,timeout);
	if (lasterror==BLERR_OK) {
	    sendack(ST_OK,*datalen,*channel,receiveblocknum);
	    break;
	}
	MicroWait(DELAY_RESEND);
	sendack(ST_RESEND,*datalen,*channel,receiveblocknum);
	if (debug>=DBG_FULL)
	    puts("  failed...");
	timeout=0;
    }
    if (i==NUM_RETRIES) {
	//panic("too many errors");
	return(lasterror);
    }

    if (debug>=DBG_FULL)
	printf("  Received block %d (%d bytes) on channel %d...\n",
	       receiveblocknum,*datalen,*channel);

    MicroWait(DELAY_BLOCK);
    return(BLERR_OK);
}





/*************************************************************************
**
** ta emot block!
**
******/
int receiveblock(u_int8_t *dataptr, u_int32_t *datalen, int *channel,
		 u_int8_t *blocknum, int initialtimeout)
{
    u_int8_t header[5];
    u_int8_t checksum;
    u_int8_t check;
    int timeout;
    u_int32_t i;

/*** settimeout ***/
    timeout=initialtimeout;
    if (initialtimeout==0)
	timeout=TIMEOUT_BLOCK;
    if (initialtimeout<0)
	timeout=-1;


/*** receive header ***/
    if (SerRead(&(header[0]),1,timeout))
	return(BLERR_TIMEOUT);
    if (SerRead(&(header[1]),4,TIMEOUT_BLOCK))
	return(BLERR_TIMEOUT);

/*** calculate checksum on header ***/
    checksum=0;
    for (i=0; i<4; i++)
	checksum^=header[i];
    if (checksum!=header[4])
	return(BLERR_HEADERCHECKSUM);

/*** check head ***/
    if (header[0]!=0x7e)
	return(BLERR_HEADERFORMAT);

/*** get channel ***/
    if (header[1]&0xf0)
	return(BLERR_HEADERFORMAT);
    *channel=header[1];

/*** get blocknum ***/
    *blocknum=header[2];

/*** get length ***/
    if (header[3]==0)
	*datalen=0x100;
    else
	*datalen=header[3];

/*** get body ***/
    if (SerRead(dataptr,*datalen,TIMEOUT_BODY))
	return(BLERR_TIMEOUT);

/*** calculate checksum on body ***/
    checksum=0;
    for (i=0; i<(*datalen); i++)
	checksum^=*(dataptr+i);

/*** check checksum ***/
    if (SerRead(&check,1,TIMEOUT_BODY))
	return(BLERR_TIMEOUT);
    if (checksum!=check)
	return(BLERR_DATACHECKSUM);

/*** return OK ***/
    return(BLERR_OK);
}

/*************************************************************************
**
** Skicka ack!
**
******/
void sendack(u_int8_t status, u_int32_t datalen, int channel,
	     u_int8_t blocknum)
{
    u_int8_t header[5];
    u_int8_t checksum;
    u_int32_t i;

/*** build header ***/
    header[0]=0x7e;
    header[1]=channel|status; /*channel */
    header[2]=blocknum; /*block num */
    header[3]=datalen&0xff;

/*** calculate checksum on header ***/
    checksum=0;
    for (i=0; i<4; i++)
	checksum^=header[i];
    header[4]=checksum;

/*** send header ***/
    SerWrite(header,5);
    /*    DrainSerial();  Seems this only slows things down... */
}



/*************************************************************************
**
** Skicka block!
**
******/
void emitblock(u_int8_t *dataptr, u_int32_t datalen,int channel,
	       u_int8_t blocknum)
{
    u_int8_t header[5];
    u_int8_t checksum;
    u_int32_t i;

/*** build header ***/
    header[0]=0x7e;
    header[1]=channel;  /*channel */
    header[2]=blocknum; /*block num */
    header[3]=datalen&0xff;

/*** calculate checksum on header ***/
    checksum=0;
    for (i=0; i<4; i++)
	checksum^=header[i];
    header[4]=checksum;

/*** send header ***/
    SerWrite(header,5);

/*** send body and check for break ***/
    SerWrite(dataptr,datalen);
    
/*** calculate checksum on body ***/
    checksum=0;
    for (i=0; i<(datalen); i++)
	checksum^=*(dataptr+i);

/*** send checksum ***/
    SerWrite(&checksum,1);

}

/*************************************************************************
**
** Kolla acknowledge!
**
******/
int checkack(u_int32_t datalen, int channel, u_int8_t blocknum)
{
    u_int8_t header[5];
    u_int8_t checksum;
    u_int32_t i;

/*** receive ack ***/
    if (SerRead(header,5,TIMEOUT_ACK))
	return(BLERR_TIMEOUT);

/*** calculate checksum on header ***/
    checksum=0;
    for (i=0; i<4; i++)
	checksum^=header[i];
    if (checksum!=header[4])
	return(BLERR_HEADERCHECKSUM);

/*** check head ***/
    if (header[0]!=0x7e)
	return(BLERR_HEADERFORMAT);

/*** check channel ***/
    if ((header[1]&0x0f)!=channel)
	return(BLERR_HEADERFORMAT);

/*** check blocknum ***/
    if (header[2]!=blocknum)
	return(BLERR_BLOCKMISMATCH);

/*** check length ***/
    if (header[3]!=(datalen&0xff))
	return(BLERR_LENGTHMISMATCH);

/*** check if resend ***/
    if ((header[1]&ST_MASK)==ST_RESEND)
	return(BLERR_RESEND);

/*** return OK ***/
    return(BLERR_OK);
}
