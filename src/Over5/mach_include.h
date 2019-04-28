/**********************************************************************
**
** mach_include.h
**
** Here are definitions and header files that are platform specific
** but not really belong to any specific part of the code
**
******/

#ifndef _MACH_INCLUDE_H
#define _MACH_INCLUDE_H

#ifdef LINUX_VERSION
# include <sys/types.h>
#else

typedef signed char        int8_t;
typedef unsigned char      u_int8_t;
typedef signed short       int16_t;
typedef unsigned short     u_int16_t;
typedef signed long        int32_t;
typedef unsigned long      u_int32_t;
typedef signed long long   int64_t;
typedef unsigned long long u_int64_t;

#endif /* LINUX_VERSION */

#ifdef AMIGA_VERSION

#include <dos.h>
#include <error.h>

#endif /* AMIGA_VERSION */

#ifdef WIN32_VERSION

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif
#ifdef UNICODE
#undef UNICODE
#endif

typedef void *          APTR;
typedef char *          STRPTR;

#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION

/* Some 'useful' defaults */
# define CFG_FILE     ".over5rc"
# define DEFAULT_PORT "/dev/ttyS0"
# define BREAK_DURATION 2 /* For a break length of 0.5 to 1.0 seconds */ 
# define TIMEOUT_TICKS_PER_SECOND 4 /* Granularity of timeout counter */

/* They are probably around somewhere */
# define FILE_ATTRIBUTE_NORMAL -1
# define FILE_ATTRIBUTE_DIRECTORY 1

/* Ugly but effective... */
# define BOOL int
# define DWORD u_int32_t

# ifndef FALSE
#  define FALSE 0
# endif
# ifndef TRUE
#  define TRUE (!FALSE) /* Of course :) */
# endif

/* I really couldn't find these anywhere... */
# define max(a,b) ((a) > (b) ? (a) : (b))
# define min(a,b) ((a) < (b) ? (a) : (b))

typedef void * APTR;
typedef char * STRPTR;

#endif /* LINUX_VERSION */

#endif /* ! _MACH_INCLUDE_H */



