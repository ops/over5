
/*************************************************************************
**
** Main.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#include "main_rev.h"

#include "mach_include.h"
#include "block.h"
#include "o5protocol.h"
#include "protocol.h"
#include "main.h"
#include "o5.h"
#include "mach.h"
#include "config.h"



void o5_Help(int argc, char **argv);


u_int8_t serial=FALSE;

struct O5Config o5config;

u_int32_t debug=DBG_NONE;

struct table {
  char *tbl_name;
  void (*tbl_func)(int,char**);
};

struct table command[]={
    {"SIMPLEWRITE", &o5_SimpleWrite},
    {"SIMPLEREAD",  &o5_SimpleRead},
    {"COPY",        &o5_Copy},
    {"WRITEFILE",   &o5_WriteFile},
    {"READFILE",    &o5_ReadFile},
    {"WRITEMEM",    &o5_WriteMem},
    {"READMEM",     &o5_ReadMem},
    {"SYS",         &o5_Sys},
    {"RUN",         &o5_Run},
    {"RESET",       &o5_Reset},
    {"BOOT",        &o5_Boot},
    {"DIR",         &o5_Dir},
    {"STATUS",      &o5_Status},
    {"COMMAND",     &o5_Command},
    {"WRITEDISK",   &o5_WriteDisk},
    {"WRITEZIP",    &o5_WriteZip},
    {"READDISK",    &o5_ReadDisk},
    {"READZIP",     &o5_ReadZip},
    {"TEST",        &o5_Test},
    {"SERVER",      &o5_Server},
    {"HELP",        &o5_Help},
    {"?",           &o5_Help},
    {NULL,          NULL}
};

/*************************************************************************
**
** The absolute main....
**
******/
int main(int argc, char **argv)
{
    int num,fail;
    STRPTR ErrorStr=NULL;
    char *name=NULL;
    char **newargv=NULL;
    void (*func)(int,char**)=NULL;
    char configfile[256];

    mach_startup();
    
/*
** set config defaults
** and readconfig file
*/
    o5config.device=8;
    readconfig(mach_getconfigfile(configfile, 256), configtable);
    
/*
**
*/
    
    if (!(serial=!(ErrorStr=CreateSerial())))
	panic(ErrorStr);
    
    if (argc<=1)
	panic("no args");
    
/*** find keyword ***/
    num=0;
    fail=TRUE;
    while ((name=command[num].tbl_name)!=NULL) {
	func=command[num].tbl_func;
#ifndef LINUX_VERSION
	if (!stricmp(argv[1],name)) {
#else 
	if (!strcasecmp(argv[1],name)) {
#endif /* ! LINUX_VERSION */
	    fail=FALSE;
	    break;
	}
	num++;
    }
    if (fail)
	panic("error in args");


/*** found command prepare to execute ***/
    if (argc>2) {
	newargv=argv+2;
    } else {
	newargv=NULL;
    }

/*** execute! ***/
    (func)(argc-2, newargv);

    closeall(0);
    return (0);
}



/*************************************************************************
**
** closeall
**
******/
void closeall(int ret)
{
    if (serial) DeleteSerial();
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
** HELP
**
******/
void o5_Help(int argc, char **argv)
{
    int num=0;
    int fail=TRUE;
    char *name=NULL;
    static char *newargv=NULL;
    static char qmark[]="?";
    void (*func)(int,char**)=NULL;

    /* Convert 'Over5 HELP COMMAND' to 'Over5 COMMAND ?' */
    if (argc>0) {
	while ((name=command[num].tbl_name)!=NULL) {
	    func=command[num].tbl_func;
#ifndef LINUX_VERSION
	    if (!stricmp(argv[0],name)) {
#else
	    if (!strcasecmp(argv[0],name)) {
#endif /* ! LINUX_VERSION */
		fail=FALSE;
		break;
	    }
	    num++;
	}
	if (!fail && func!=&o5_Help) {
	    newargv=qmark;
	    (func)(1, &newargv);
	    return;
	}
    }

    puts(
	"Usage: Over5 COMMAND/A\n"
	"where COMMAND is one of the following:\n"
	"  HELP, ?, COPY, WRITEFILE, READFILE, WRITEMEM, READMEM, SYS,\n"
	"  RUN, RESET, SIMPLEWRITE, SIMPLEREAD, BOOT, DIR, STATUS, COMMAND,\n"
	"  TEST, WRITEDISK, WRITEZIP, READDISK, READZIP, SERVER\n"
	"use 'Over5 COMMAND/A ?' or 'Over5 HELP COMMAND' for more info."
	);
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


