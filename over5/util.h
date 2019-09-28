/*************************************************************************
**
** util.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#include <sys/types.h>
#include <stdarg.h>
#include <stdint.h>

u_int8_t *LoadFile(char *);
void SaveFile(char *, u_int8_t *,u_int32_t);
void *jalloc(int32_t len);
void jfree(void *);
u_int32_t jsize(void *); 
void panic(char *, ...);
void closeall(int);

/* eof */
