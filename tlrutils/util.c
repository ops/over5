/*************************************************************************
 *
 * FILE  util.c
 * Copyright (c) 2002 Daniel Kahlin
 * Written by Daniel Kahlin <daniel@kahlin.net>
 * $Id: util.c,v 1.1 2002/04/29 12:47:54 tlr Exp $
 *
 * DESCRIPTION
 *   Utility functions for tlrutils.
 *
 ******/

#include "config.h"
#include "util.h"

/*************************************************************************
 *
 * NAME  warning()
 *
 * SYNOPSIS
 *   warning (str, ...)
 *   void warning (const char *, ...)
 *
 * DESCRIPTION
 *   output warning message prepended with 'Warning: ' and appended
 *   with '\n'.
 *
 * INPUTS
 *   str              - format string
 *   ...              - vararg parameters
 *
 * RESULT
 *   none
 *
 * KNOWN BUGS
 *   none
 *
 ******/
void warning (const char *str, ...)
{
    va_list args;

    fprintf (stderr, "Warning: ");
    va_start (args, str);
    vfprintf (stderr, str, args);
    va_end (args);
    fputc ('\n', stderr);
}


/*************************************************************************
 *
 * NAME  panic()
 *
 * SYNOPSIS
 *   panic (str, ...)
 *   void panic (const char *, ...)
 *
 * DESCRIPTION
 *   output error message prepended with 'PROGRAM: ' and appended
 *   with '\n'.
 *
 * INPUTS
 *   str              - format string
 *   ...              - vararg parameters
 *
 * RESULT
 *   none
 *
 * KNOWN BUGS
 *   none
 *
 ******/
void panic (const char *str, ...)
{
    va_list args;

    fprintf (stderr, "%s: ", _program);
    va_start (args, str);
    vfprintf (stderr, str, args);
    va_end (args);
    fputc ('\n', stderr);
    exit (1);
}

/* eof */
