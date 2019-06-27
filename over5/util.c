/*************************************************************************
**
** util.c
** Copyright (c) 1995,1996,2002 Daniel Kahlin <daniel@kahlin.net>
**
******/

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "main_rev.h"
#include "block.h"
#include "util.h"
#include "main.h"
#include "mach.h"

/*************************************************************************
**
** closeall
**
******/
void closeall(int ret)
{
    DeleteSerial();
    mach_closeall(ret);

    exit(ret);
}


/*************************************************************************
**
** Panic (new cool with varargs)
**
******/
void panic(char *str, ...)
{
    va_list arglist;

    va_start(arglist,str);

    if (str) {
	printf(PROGRAM_NAME ": ");
	vprintf(str, arglist);
	if (str[strlen(str)] != '\n')
	    puts("!");
    } else
	puts(PROGRAM_NAME ": panic!\n");

    va_end(arglist);

    closeall(1);
}

/*************************************************************************
**
** Ladda fil till buffer
**
******/
u_int8_t *LoadFile(char *filename)
{
    FILE *fp;
    int size=0;
    char *ptr=NULL;

#ifdef ECHO_FUNCTION_CALL
    printf("LoadFile(%s);\n", filename);
#endif

    if (!(fp=fopen(filename,"rb")))
	panic("couldn't open file");
    fseek(fp,0,SEEK_END);
    size=ftell(fp);
    ptr=jalloc(size);
    fseek(fp,0,SEEK_SET);

    fread(ptr,1,size,fp);
    fclose(fp);

    return(ptr);  
}


/*************************************************************************
**
** spara fil från buffer
**
******/
void SaveFile(char *filename,u_int8_t *ptr,u_int32_t size)
{
    FILE *fp;

    if (!(fp=fopen(filename,"wb")))
	panic("couldn't open file");
    fwrite(ptr,1,size,fp);
    fclose(fp);

}



/*************************************************************************
**
** Jücklo minnes hantering (kommer ihåg size)
**
** void *jalloc(int32_t)
** void jfree(void *)
** u_int32_t jsize(void *)
**
******/
void *jalloc(int32_t len)
{
    u_int8_t *ptr;

    if (len<0)
	panic("negative mem");
    if (!(ptr=malloc(len+4)))
	panic("couldn't jalloc");

    memset(ptr,len+4,0);
    *(u_int32_t *)ptr=len;
    return ((void *)(ptr+4));
}
/************************************************************************/
void jfree(void *ptr)
{
    if (ptr)
	free(ptr-4);
}
/************************************************************************/
u_int32_t jsize(void *ptr)
{
    if (ptr)    
        return(*(u_int32_t *)(ptr-4));
    else
        return(0);
}

/* eof */


