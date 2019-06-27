dnl***********************************************************************
dnl
dnl FILE  configure.in
dnl Copyright (c) 2000,2002 Daniel Kahlin
dnl Written by Daniel Kahlin <daniel@kahlin.net>
dnl $Id: configure.in,v 1.1 2002/04/27 15:19:44 tlr Exp $
dnl
dnl DESCRIPTION
dnl   run autoconf to produce the ./configure script from this file.
dnl
dnl******
AC_INIT(tlrpatch.c)

AC_CONFIG_HEADER(config.h)

dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL

dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS(unistd.h)
AC_CHECK_TYPE(u_int32_t, uint32_t)
AC_CHECK_TYPE(uint32_t, unsigned long)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_BIGENDIAN

dnl Checks for library functions.
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(strtoul)

AC_OUTPUT(Makefile)
dnl
dnl eof
dnl