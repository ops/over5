
/*************************************************************************
**
** Main.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#ifdef AMIGA_VERSION

#define BOLD "\x9b" "0;1" "\x6d"
#define ITALICS "\x9b" "0;3" "\x6d"
#define NORMAL "\x9b" "0" "\x6d"

#endif /* AMIGA_VERSION */


u_int8_t *LoadFile(char *);
void SaveFile(char *, u_int8_t *,u_int32_t);
void *jalloc(int32_t);
void jfree(void *);
u_int32_t jsize(void *); 
void panic(char *, ...);
void closeall(int);

#define DBG_NONE 0
#define DBG_FULL 2
#define DBG_MEDIUM 1

extern u_int32_t debug;
extern struct O5Config o5config;
