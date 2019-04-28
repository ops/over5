
/*************************************************************************
**
** o5_Server.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** Commands: SERVER
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>

#include "util.h"
#include "protocol.h"
#include "main.h"
#include "mach.h"

#include "o5.h"

#define SRV_TEMPLATE "DEBUG/S"

struct srv_args {
    u_int32_t as_debug;
};

struct srv_args srv_argarray;


/*************************************************************************
**
** SERVER
**
******/
void o5_Server(int argc, char **argv)
{

    if (!(mach_rdargs(SRV_TEMPLATE,(int32_t *)&srv_argarray,argc,argv)))
	panic("error in args");
    if (srv_argarray.as_debug)
	debug=DBG_FULL;

    printf("Now in server mode!\n");

/* disable requesters */
    mach_noerror();

/* go server */
    bl_server();


}

/* eof */

