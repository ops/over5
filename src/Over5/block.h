
/*************************************************************************
**
** Block.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Handle blockprotocol
**
******/



/* bl_block.c */

#ifdef LINUX_VERSION
# include "mach_include.h"
#endif

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

extern void Setbaud(u_int32_t baudrate);

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
extern void SerWrite(APTR Buffer, int32_t Size);

/*
** Read from serport to buffer (timeout=-1) => no timeout!
*/
extern int SerRead(APTR Buffer, u_int32_t Size, int32_t timeout);

/*
** Deallocate all serial stuffs
*/
extern void DeleteSerial(void);


/*
** Return string for serial error
*/
extern STRPTR GetSerialError(int32_t Error);


/*
** Allocate all serial stuffs
*/
extern STRPTR CreateSerial(void);


extern void MicroWait(u_int32_t microsecs);




