/*************************************************************************
**
** bl_Serial.c
** Win32 module by Martin Sikström <e93_msi@e.kth.se>
** Linux module by Andreas Andersson <e92_aan@e.kth.se>
** Copyright (c) 1995,1996,1999,2000 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

/* For autoconf support */
#include "config.h"

#include <stdio.h>
#include <string.h>

#ifdef __MINGW32__
#include <windows.h>
#endif /* __MINGW32__ */

#ifdef LINUX_VERSION
#include <errno.h>
#include <fcntl.h>
#include <strings.h>
#include <sys/time.h>
#include <sys/types.h>
#include <termios.h>
#include <unistd.h>
#endif /* LINUX_VERSION */

#include "util.h"
#include "main.h"
#include "mach.h"

#include "block.h"

#define SER_BAUDRATE 38400
/*#define SER_BREAKLENGTH 1000000 */
#define SER_BITSPERCHAR 8
#define SER_STOPBITS 2
/*
 * It seems that SerRead needs the serialbuffersize to be
 * as big as the largest read requested.   The largest is
 * during SIMPLEREAD, which would be max 64Kb in the case of
 * a c64.  Let's hope that this doesn't have any bad side
 * effects.
 */ 
/*#define SERBUFFERSIZE 512*/
#define SERBUFFERSIZE 65536 

#define ERRBUFFERSIZE 256

/*** serial statics! ***/
static char     errorbuffer[ERRBUFFERSIZE];
static int      serial_open=FALSE;

#ifdef WIN32_VERSION
static HANDLE          serhandle=NULL;
static COMMPROP        serprop;
static DCB             serdcb;
static COMMTIMEOUTS    sertimeout;
static int             quitflag;
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
static struct termios  old_termios, new_termios;
static int             fd_serial;
#endif /* LINUX_VERSION */

/* Function prototypes (all others are declared in Block.h */
static BOOL InitParams(int32_t baudrate);
#ifdef LINUX_VERSION
static speed_t convertbaud(int32_t baudrate);
#endif /* LINUX_VERSION */

/*
** Write buffer to serport   (Size==-1) => zero terminated string
*/
void SerWrite(u_int8_t *Buffer, int32_t Size)
{

#ifdef WIN32_VERSION
    DWORD byteswritten;
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    int byteswritten;
#endif /* LINUX_VERSION */

#ifdef ECHO_FUNCTION_CALL
    printf ("SerWrite(%p, %ld);\n", Buffer, Size);
#endif

    if(Size < 0)
	Size = strlen(Buffer);

#ifdef WIN32_VERSION
    if (serhandle) {
	if (!WriteFile(serhandle, Buffer, Size, &byteswritten, NULL)) {
	    if (GetLastError() != ERROR_IO_PENDING) {
		puts(GetSerialError(GetLastError()));
		panic("WriteFile failed");
	    }
	    if (byteswritten != (unsigned) Size) {
		panic("Requested and written bytes do not match");
	    }
	}
    }
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION  
    if (fd_serial > 0) {
	for(;;) {
	    if((byteswritten = write(fd_serial, Buffer, Size)) == -1) {
		if(errno != EAGAIN)
		    panic("write() failed");
	    } else if(byteswritten == (unsigned) Size) {
		DrainSerial();
		return;
	    } else {
		/* There should be some timeout handling here, but it really */
		/* isn't that necessary in this case */
		Size = Size - byteswritten;
		Buffer = Buffer + byteswritten;
		MicroWait(17000);
	    }
	}
    }
#endif /* LINUX_VERSION */
}


/*
** Read from serport to buffer (timeout==-1 => no timeout)
*/
int SerRead(u_int8_t *Buffer, u_int32_t Size, int32_t timeout)
{

#ifdef WIN32_VERSION
    DWORD bytesread;
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
    int bytesread;
    int32_t timeout_counter;
    struct timeval time_val;
    int retval;
    fd_set fdset_serial;
#endif /* LINUX_VERSION */

#ifdef ECHO_FUNCTION_CALL
    printf ("SerRead(%p, %ld, %ld);\n", Buffer, Size, timeout);
#endif

#ifdef WIN32_VERSION
    sertimeout.ReadIntervalTimeout=0;
    sertimeout.ReadTotalTimeoutMultiplier=0;
    sertimeout.WriteTotalTimeoutMultiplier=0;
    sertimeout.WriteTotalTimeoutConstant=0;
  
    if (timeout<0)
	/* Do read without timeout in chunks of 2 seconds */
	sertimeout.ReadTotalTimeoutConstant=2000;
    else
	/* timeout is given in seconds */
	sertimeout.ReadTotalTimeoutConstant=timeout*1000;

    if (serhandle) {
	do {
	    SetCommTimeouts(serhandle, &sertimeout);

	    if (!ReadFile(serhandle, Buffer, Size, &bytesread, NULL)) {
		/* There was an error (timeout is not an error) */
		panic(GetSerialError(GetLastError()));
	    }
	    if (bytesread == Size) {
		/* There was no timeout */
		return (0);
	    }
	    /* In case of read without timeout, go back and wait for
	       the remaining bytes */
	    Size -= bytesread;
	    Buffer += bytesread;
	} while (timeout < 0 && !quitflag);
    }
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
    if (fd_serial > 0) {
	/* Check to see if some data is already waiting */
	bytesread = read(fd_serial, Buffer, Size);
	if (bytesread > 0) {
	    Size -= bytesread;
	    Buffer += bytesread;

#ifdef PRINTF_DEBUG
	    printf ("->bytesread = %d\n", bytesread);
#endif

	    /* Check for errors. EAGAIN is not a real error */ 
	} else if ((bytesread == -1) && (errno != EAGAIN)) {
	    panic(GetSerialError(errno));
	}
	if (Size == 0) return 0;

	timeout_counter = timeout * TIMEOUT_TICKS_PER_SECOND;

	/* Add some to the timeout_counter to account for large packages */
	/* Very carefully calculated divisor of course :) */
	timeout_counter += (int)Size/17;

#ifdef PRINTF_DEBUG
	printf ("->(before)timeout = %d  timeout_counter %d  Size = %d\n",
		timeout, timeout_counter, Size);
#endif

	for (;;) {
	    /* Put fd_serial in an fd_set to wait for */
	    FD_ZERO(&fdset_serial);
	    FD_SET(fd_serial, &fdset_serial);

	    time_val.tv_sec = 0;
	    /* Every timeout tick is 1/TIMEOUT_TICKS_PER_SECOND seconds long */
	    time_val.tv_usec = (1000000/TIMEOUT_TICKS_PER_SECOND);

	    retval = select(fd_serial + 1, &fdset_serial, NULL, NULL, &time_val);
	    if(retval < 1) {
		/* timeout_counter is decreased (as long as it's positive) every */
		/* time the select times out and no data has arrived */
		if(timeout_counter > 0)
		    timeout_counter -= 1;
	    }
	    /* Probably OK to try to read now. Even if it isn't, who cares... */
	    bytesread = read(fd_serial, Buffer, Size);
	    if (bytesread > 0) {

#ifdef PRINTF_DEBUG
		printf ("->bytesread (inside)= %d\n", bytesread);
#endif

		Size -= bytesread;
		Buffer += bytesread;
	    }

	    /* If Buffer is full or timeout_counter is 0, break the loop */
	    if ( (Size == 0) || ( (timeout_counter == 0) && (timeout != -1) ) )
		break;
	}

#ifdef PRINTF_DEBUG
	printf ("->(after) timeout = %d  timeout_counter %d  Size = %d\n",
		timeout, timeout_counter, Size);
#endif
    
    }
  
    /* All OK? */
    if(Size == 0) return 0;

#endif /* LINUX_VERSION */
  
    return 1;
}

/*
** Allocate all serial stuffs
*/
char *CreateSerial()
{
#ifdef ECHO_FUNCTION_CALL
    printf ("CreateSerial();\n");
#endif

#ifdef WIN32_VERSION

    serhandle=CreateFile(o5config.serdevice, GENERIC_READ | GENERIC_WRITE,
			 0, NULL, OPEN_EXISTING, 
			 FILE_ATTRIBUTE_NORMAL,
			 NULL);
    if (serhandle==INVALID_HANDLE_VALUE) {
	serhandle=NULL;
	return (GetSerialError(GetLastError()));
    }
  
    if (!SetupComm(serhandle, SERBUFFERSIZE, SERBUFFERSIZE))
	return (GetSerialError(GetLastError()));
  
    if (!SetCommMask(serhandle, EV_RXCHAR))
	return (GetSerialError(GetLastError()));
  
    if (!InitParams(SER_BAUDRATE))
	return (GetSerialError(GetLastError()));
  
    quitflag=0;
  
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION  

    /* Open in asynchronous mode to make the timeouts work right */
    fd_serial = open(o5config.serdevice, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd_serial < 0) {
	return (strerror(errno));
    }
  
    /* Be nice and save the old settings */
    tcgetattr(fd_serial, &old_termios);

    if (!InitParams(SER_BAUDRATE)) {
	return (strerror(errno));
    }

#endif /* LINUX_VERSION */
  
    serial_open=TRUE;
    return(NULL);
}


/*
** clear
*/
void ClearSerial(void)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("ClearSerial();\n");
#endif
  
#ifdef WIN32_VERSION

    if (serhandle) {
	FlushFileBuffers(serhandle);
	PurgeComm(serhandle, PURGE_TXCLEAR | PURGE_RXCLEAR);
	ClearCommBreak(serhandle);
    }

#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION  

    if (fd_serial > 0) {
	tcflush(fd_serial, TCIOFLUSH);
    }

#endif /* LINUX_VERSION */

}


/*
** Make sure everything gets out OK before returning
** Needed under Linux in some cases. (Probably)
*/
void DrainSerial(void)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("DrainSerial();\n");
#endif

#ifdef LINUX_VERSION
    if (fd_serial > 0) {
	while(tcdrain(fd_serial) == -1) {
	    if(errno != EAGAIN) break;
	}
    }
#endif /* LINUX_VERSION */

}


/*
** Deallocate all serial stuff
*/
void DeleteSerial()
{
#ifdef ECHO_FUNCTION_CALL
    printf ("DeleteSerial();\n");
#endif

/* if it wasn't opened in the first place, just return */
    if (!serial_open)
	return;

#ifdef WIN32_VERSION
    if (serhandle) {
	quitflag=1;
	ClearSerial();
	CloseHandle(serhandle);
	serhandle=NULL;
    }
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
    if (fd_serial > 0) {
	/* Return to 'before' settings */
	tcsetattr(fd_serial, TCSANOW, &old_termios);
	close(fd_serial);
	fd_serial = -1;
    }
#endif /* LINUX_VERSION */

    serial_open=FALSE;
}


#ifdef LINUX_VERSION
/*
** Helper function to beautify things a little bit
*/
static speed_t convertbaud(int32_t baudrate)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("convertbaud(%ld);\n", baudrate);
#endif

    switch (baudrate) {
    case 0 :      return B0;
    case 50 :     return B50;
    case 75 :     return B75;
    case 150 :    return B150;
    case 300 :    return B300;
    case 600 :    return B600;
    case 1200 :   return B1200;
    case 2400 :   return B2400;
    case 4800 :   return B4800;
    case 9600 :   return B9600;
    case 19200 :  return B19200;
    case 38400 :  return B38400;
#ifdef B57600
    case 57600 :  return B57600;
#endif
#ifdef B115200
    case 115200 : return B115200;
#endif
#ifdef B230400
    case 230400 : return B230400;
#endif
	default : break;
    }
    return B0;
}

#ifndef HAVE_CFMAKERAW
/*
** Some systems (e.g. IRIX) don't seem to have cfmakeraw
*/
int cfmakeraw(struct termios *termios_p)
{
    termios_p->c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP
			  |INLCR|IGNCR|ICRNL|IXON);
    termios_p->c_oflag &= ~OPOST;
    termios_p->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
    termios_p->c_cflag &= ~(CSIZE|PARENB);
    termios_p->c_cflag |= CS8;

    /* This should mean success. I think. */
    return 0;
}
#endif /* HAVE_CFMAKERAW */

#endif /* LINUX_VERSION */


/*
** Set Baud rate etc...
*/
void Setbaud(u_int32_t baudrate)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("Setbaud(%ld);\n", baudrate);
#endif

#ifdef WIN32_VERSION
    if (serhandle) {
	serdcb.BaudRate=baudrate;
	SetCommState(serhandle, &serdcb);
    }
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION 
    if (fd_serial > 0) {

	/* Crappy kludge, but works! */
	DrainSerial();
	usleep(1000000);

	tcgetattr(fd_serial, &new_termios);

	/* Set input speed to the same as the output */
	cfsetospeed(&new_termios, convertbaud(baudrate));
	cfsetispeed(&new_termios, convertbaud(baudrate));

	/* Wait for output data to drain first */
	if(tcsetattr(fd_serial, TCSADRAIN, &new_termios) == -1) {
	    panic(GetSerialError(0));
	}

	/* Crappy kludge, but works! */
	DrainSerial();
	usleep(1000000);

    }
#endif /* LINUX_VERSION */

}


/*
** Sendbreak
*/
void SendBreak(void)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("Sendbreak();");
#endif

#ifndef LINUX_VERSION
    if (serhandle)
	SetCommBreak(serhandle);
#else

    if (fd_serial > 0)
	tcsendbreak(fd_serial, BREAK_DURATION);

#endif /* ! LINUX_VERSION */

}


/*
** Return string for serial error
*/
char *GetSerialError(int32_t Error)
{
#ifdef WIN32_VERSION
    int offs;
    char *ptr;
#endif /* WIN32_VERSION */

#ifdef ECHO_FUNCTION_CALL
    printf ("GetSerialError(%ld);\n", Error);
#endif

#ifdef WIN32_VERSION
    offs = sprintf (errorbuffer, "%s: ", o5config.serdevice);
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, Error, 0,
		  errorbuffer+offs, ERRBUFFERSIZE-1-offs, NULL);

    /* FormatMessage() usually puts a ".\r\n" at the end of the string,
       which will look ugly when panic() puts an exclamation mark after. */
    if ((ptr=strrchr(errorbuffer, '.')))
	*ptr='\0';
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION

    /* This probably isn't how it should be done, but what the hell... */
    return strerror(errno);

#endif /* ! LINUX_VERSION */

    return (errorbuffer);
}


static BOOL InitParams(int32_t baudrate)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("InitParams(%ld);\n", baudrate);
#endif

#ifdef WIN32_VERSION
    if (serhandle) {
	if (!(GetCommProperties(serhandle, &serprop)))
	    return FALSE;
	if (!(GetCommState(serhandle, &serdcb)))
	    return FALSE;
      
	serdcb.BaudRate=baudrate;
	serdcb.fBinary=TRUE;
	serdcb.fParity=TRUE;
	serdcb.fOutxCtsFlow=FALSE;
	serdcb.fOutxDsrFlow=FALSE;
	serdcb.fDtrControl=DTR_CONTROL_DISABLE;
	serdcb.fOutX=FALSE;
	serdcb.fInX=FALSE;
	serdcb.fErrorChar=FALSE;
	serdcb.fNull=FALSE;
	serdcb.fRtsControl=RTS_CONTROL_DISABLE;
	serdcb.fAbortOnError=FALSE;
	serdcb.ByteSize=SER_BITSPERCHAR;
	serdcb.Parity=NOPARITY;
	serdcb.StopBits=SER_STOPBITS;
      
	if (!SetCommState(serhandle, &serdcb))
	    return FALSE;
    }
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
    /*  bzero((void*)&new_termios, sizeof(new_termios)); */
    tcgetattr(fd_serial, &new_termios);
  
    /* Make serial port "raw" */
    cfmakeraw(&new_termios);

    /* 2 stop bits, ignore modem control lines, enable reciever */
    new_termios.c_cflag |= CSTOPB | CLOCAL | CREAD;
    new_termios.c_cc[VTIME] = 0;
    new_termios.c_cc[VMIN] = 1;

    /* Set input speed to the same as the output */
    cfsetospeed(&new_termios, convertbaud(baudrate));
    cfsetispeed(&new_termios, convertbaud(baudrate));
    /*  cfsetispeed(&new_termios, 0); */

    /* Don't mind waiting for output data to drain */
    if(tcsetattr(fd_serial, TCSANOW, &new_termios) == -1) {
	panic(GetSerialError(0));
    }

    /* Flush input and output data just to make sure */
    while(tcflush(fd_serial, TCIOFLUSH) == -1) {
	if(errno != EAGAIN) break;
    }

#endif /* LINUX_VERSION */

#ifdef ECHO_FUNCTION_CALL
    printf ("InitParams(%ld); finished\n", baudrate);
#endif
    return TRUE;
}

/*************************************************************************
**
** microwait.
**
** Note: the number of microseconds to sleep is rounded to milliseconds.
** 
******/
void MicroWait(u_int32_t microsecs)
{
#ifdef ECHO_FUNCTION_CALL
    printf ("MicroWait(%ld);\n", microsecs);
#endif

#ifdef WIN32_VERSION
    Sleep((microsecs+500)/1000);
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
    usleep(microsecs);
#endif /* LINUX_VERSION */
}

/* eof */
