
/*************************************************************************
**
** pr_Simple.c
** Copyright (c) 1995,1996,2002 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#include "config.h"

#include <stdio.h>
#include <stdlib.h>

#include "util.h"
#include "block.h"
#include "o5protocol.h"
#include "main.h"

#include "protocol.h"

#define BSIZE 256
#define BOOT_BSIZE 128

/*************************************************************************
**
** SlowsendOld!
**
**
******/
void slowsendold(u_int8_t *buffer, u_int32_t len)
{
    u_int8_t temp[6];
    u_int8_t checksum;
    u_int32_t i;
    u_int32_t addr,endaddr;
    u_int8_t *dataptr,*tempptr;
    u_int32_t datalen,templen;
    u_int32_t blocks;


    Setbaud(150);

/*** calculate relevant info ***/
    dataptr=buffer+2;
    datalen=len-2;
    addr=*buffer+(*(buffer+1)<<8);
    endaddr=addr+datalen;
    blocks=((len+253)/254);

    printf("Syncing...\n");

/*** sync ***/
    for (i=0; i<6; i++) {
	temp[0]='S';
	SerWrite(temp,1);
	DrainSerial();
	MicroWait(300000);
    }

    printf("Sending $%04x-$%04x (%d bytes, %d blocks)...\n",addr,endaddr,datalen,blocks);

    checksum=0;
/*** build header ***/
    temp[0]=addr&0xff;
    temp[1]=(addr>>8)&0xff;
    temp[2]=endaddr&0xff;
    temp[3]=(endaddr>>8)&0xff;
    SerWrite(temp,4);
    DrainSerial();
/*** calculate checksum on header ***/
    for (i=0; i<4; i++)
	checksum+=temp[i];

/*** send body and check for break ***/
    templen=datalen;
    tempptr=dataptr;
    while(templen>BSIZE) {
	SerWrite(tempptr,BSIZE);
	templen-=BSIZE;
	tempptr+=BSIZE;
	DrainSerial();
	chkabort();
    }
    SerWrite(tempptr,templen);
    DrainSerial();
    
/*** calculate checksum on body ***/
    for (i=0; i<(datalen); i++)
	checksum+=*(dataptr+i);

/*** send checksum ***/
    checksum=-checksum;
    SerWrite(&checksum,1);
    DrainSerial();

/*** wait for character to be sent ***/
    MicroWait(800000);

    printf("Done!\n");
}


/*************************************************************************
**
** Slowsend!
**
**
******/
void slowsend(u_int8_t *buffer, u_int32_t len, int baudrate, char *name)
{
    u_int8_t temp[6];
    u_int8_t *dataptr,*tempptr;
    u_int32_t datalen,templen;
    int counts,i;

    Setbaud(baudrate);

/*** calculate relevant info ***/
    dataptr=buffer;
    datalen=len;

    printf("Syncing...");
    fflush(stdout);

/*** sync ***/
    for (i=0; i<6; i++) {
	temp[0]='S';
	SerWrite(temp,1);
	MicroWait(300000);
    }
    temp[0]='E';
    SerWrite(temp,1);
    MicroWait(300000);

    printf("\rSending %s (%d bytes)\n",name,datalen);

    counts=(datalen+BOOT_BSIZE-1)/BOOT_BSIZE;
    for (i=0; i<counts; i++)
	putchar('.');
    putchar('\r');
    fflush(stdout);

/*** send body and check for break ***/
    templen=datalen;
    tempptr=dataptr;
    while(templen>BOOT_BSIZE) {
	SerWrite(tempptr,BOOT_BSIZE);
	templen-=BOOT_BSIZE;
	tempptr+=BOOT_BSIZE;
	counts--;
	putchar('o');
	fflush(stdout);
	chkabort();
    }
    SerWrite(tempptr,templen);
    while(counts>0) {
	counts--;
	putchar('o');
	fflush(stdout);
    } 

    putchar('\n');

/*** wait for character to be sent ***/
    MicroWait(800000);

}


/*************************************************************************
**
** Skicka fil utan handskakning!
**
**
******/
void sendfile(u_int8_t *buffer, u_int32_t len)
{
    u_int8_t temp[6];
    u_int8_t checksum;
    u_int32_t i;
    u_int32_t addr,endaddr;
    u_int8_t *dataptr,*tempptr;
    u_int32_t datalen,templen;
    u_int32_t blocks;

/*** calculate relevant info ***/
    dataptr=buffer+2;
    datalen=len-2;
    addr=*buffer+(*(buffer+1)<<8);
    endaddr=addr+datalen;
    blocks=((len+253)/254);

    printf("Sending $%04x-$%04x (%d bytes, %d blocks)...\n",addr,endaddr,datalen,blocks);

    checksum=0;
/*** build header ***/
    temp[0]=0xe7;
    temp[1]=addr&0xff;
    temp[2]=(addr>>8)&0xff;
    temp[3]=endaddr&0xff;
    temp[4]=(endaddr>>8)&0xff;

/*** calculate checksum on header ***/
    for (i=0; i<5; i++)
	checksum^=temp[i];

/*** send header ***/
    temp[5]=checksum;
    SerWrite(temp,6);
    DrainSerial();

    checksum=0;
/*** send body and check for break ***/
    templen=datalen;
    tempptr=dataptr;
    while(templen>BSIZE) {
	SerWrite(tempptr,BSIZE);

	templen-=BSIZE;
	tempptr+=BSIZE;
	chkabort();
    }
    SerWrite(tempptr,templen);
    DrainSerial();

/*** calculate checksum on body ***/
    for (i=0; i<(datalen); i++)
	checksum^=*(dataptr+i);

/*** send checksum ***/
    SerWrite(&checksum,1);

    printf("Done!\n");
}



/*************************************************************************
**
** Ta emot fil utan handskakning!
**
**
******/
int receivefile(u_int8_t **buffer_st, u_int32_t *len_st)
{
    u_int8_t temp[6];
    u_int8_t checksum;
    int i;
    u_int32_t addr,endaddr;
    u_int8_t *buffer,*dataptr;
    int32_t len,datalen;
    u_int32_t blocks;

    puts("Waiting...");
/*** get header ***/
    SerRead(temp,6,-1);

    checksum=0;
/*** calculate checksum on header ***/
    for (i=0; i<6; i++)
	checksum^=temp[i];

    if (temp[0]!=0xe7)
	panic("error in header");
    if (checksum!=0)
	panic("error in header");

/*** calculate relevant info ***/
    addr=temp[1]|(temp[2]<<8);
    endaddr=temp[3]|(temp[4]<<8);
    datalen=endaddr-addr;
    len=datalen+2;

    if (len<0)
	panic("error in header");
    if (!(buffer=malloc(len)))
	panic("couldn't malloc");

    dataptr=buffer+2;
    *buffer=addr&0xff;
    *(buffer+1)=addr>>8;
    blocks=((len+253)/254);

    printf("Receiving $%04x-$%04x (%d bytes, %d blocks)...\n",addr,endaddr,datalen,blocks);

    if (datalen==0)
	panic("no body");


/*** get body ***/
    SerRead(dataptr,datalen,-1);
    
    checksum=0;
/*** calculate checksum on body ***/
    for (i=0; i<(datalen); i++)
	checksum^=*(dataptr+i);

/*** get checksum ***/
    SerRead(temp,1,-1);

    if (temp[0]!=checksum)
	panic("checksum error");

    puts("checksum ok.");

    *buffer_st=buffer;
    *len_st=len;
    return(0);
}

/* eof */




