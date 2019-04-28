/*************************************************************************
 *
 * FILE  tlrpatch.h
 * Copyright (c) 2002 Daniel Kahlin
 * Written by Daniel Kahlin <daniel@kahlin.net>
 * $Id: util.h,v 1.1 2002/04/29 12:47:54 tlr Exp $
 *
 * DESCRIPTION
 *   Utility functions for tlrutils.
 *
 ******/

#include <stdio.h>
#include <stdarg.h>

void warning(const char *str, ...);
void panic(const char *str, ...);

/* eof */
