dnl***********************************************************************
dnl
dnl FILE  configure.in
dnl Copyright (c) 2000,2002 Daniel Kahlin
dnl Written by Daniel Kahlin <daniel@kahlin.net>
dnl $Id: configure.in,v 1.3 2002/05/07 19:12:31 tlr Exp $
dnl
dnl DESCRIPTION
dnl   run autoconf to produce the ./configure script from this file.
dnl
dnl******
AC_INIT(servers/ms_main.asm)

dnl Checks for programs.
AC_PATH_PROG(DASM,dasm)
AC_PROG_INSTALL
AC_PATH_PROG(TAR,tar)
AC_PATH_PROG(GZIP,gzip)

dnl Checks for header files.

AC_OUTPUT(Makefile common.mk servers/Makefile kernal/Makefile fastrs/Makefile)
dnl
dnl eof
dnl
