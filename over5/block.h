
/*************************************************************************
**
** Block.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Handle blockprotocol
**
******/

#include <stdint.h>

/* bl_block.c */

#define BLERR_OK        0
#define BLERR_RESEND 1
#define BLERR_ERROR 2
#define BLERR_TIMEOUT 3
#define BLERR_HEADERFORMAT 4
#define BLERR_HEADERCHECKSUM 5
#define BLERR_DATACHECKSUM 6
#define BLERR_BLOCKMISMATCH 7
#define BLERR_LENGTHMISMATCH 8

int writeblock(u_int8_t *dataptr, u_int32_t datalen, int channel);
int readblock(u_int8_t *dataptr, u_int32_t *datalen, int *channel, int initialtimeout);
void doreset(void);





/* bl_serial.c */

/*
** Set Baud rate etc...
*/

void Setbaud(u_int32_t baudrate);

/*
** Sendbreak
*/
void SendBreak(void);

/*
** Clear
*/
void ClearSerial(void);

/*
** Make sure everything gets out OK before returning
*/
void DrainSerial(void);

/*
** Write buffer to serport   (Size=-1) => zero terminated string
*/
void SerWrite(u_int8_t *Buffer, int32_t Size);

/*
** Read from serport to buffer (timeout=-1) => no timeout!
*/
int SerRead(u_int8_t *Buffer, u_int32_t Size, int32_t timeout);

/*
** Deallocate all serial stuffs
*/
void DeleteSerial(void);


/*
** Return string for serial error
*/
char *GetSerialError(int32_t Error);


/*
** Allocate all serial stuffs
*/
char *CreateSerial(void);


void MicroWait(u_int32_t microsecs);




