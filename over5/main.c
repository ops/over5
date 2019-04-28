
/*************************************************************************
**
** Main.c
** Copyright (c) 1995,1996,2002 Daniel Kahlin <daniel@kahlin.net>
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "block.h"
#include "o5.h"
#include "mach.h"
#include "config_file.h"

#include "main.h"

void o5_Help(int argc, char **argv);

struct O5Config o5config;

u_int32_t debug=DBG_NONE;

struct table {
    char *tbl_name;
    void (*tbl_func)(int,char**);
};

struct table command[]={
    {"SIMPLEWRITE", &o5_SimpleWrite},
    {"SW",          &o5_SimpleWrite},
    {"SIMPLEREAD",  &o5_SimpleRead},
    {"SR",          &o5_SimpleRead},
    {"COPY",        &o5_Copy},
    {"CP",          &o5_Copy},
    {"WRITEFILE",   &o5_WriteFile},
    {"WF",          &o5_WriteFile},
    {"READFILE",    &o5_ReadFile},
    {"RF",          &o5_ReadFile},
    {"WRITEMEM",    &o5_WriteMem},
    {"WM",          &o5_WriteMem},
    {"READMEM",     &o5_ReadMem},
    {"RM",          &o5_ReadMem},
    {"SYS",         &o5_Sys},
    {"RUN",         &o5_Run},
    {"RESET",       &o5_Reset},
    {"BOOT",        &o5_Boot},
    {"DIR",         &o5_Dir},
    {"STATUS",      &o5_Status},
    {"ST",          &o5_Status},
    {"COMMAND",     &o5_Command},
    {"CM",          &o5_Command},
    {"WRITEDISK",   &o5_WriteDisk},
    {"WD",          &o5_WriteDisk},
    {"WRITEZIP",    &o5_WriteZip},
    {"WZ",          &o5_WriteZip},
    {"READDISK",    &o5_ReadDisk},
    {"RD",          &o5_ReadDisk},
    {"READZIP",     &o5_ReadZip},
    {"RZ",          &o5_ReadZip},
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
    char *ErrorStr=NULL;
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
    
    if ((ErrorStr=CreateSerial()))
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

/* eof */


