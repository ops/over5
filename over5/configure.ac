dnl Process this file with autoconf to produce a configure script.
AC_INIT(bl_block.c)

dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL

dnl Checks for libraries.
dnl Replace `main' with a function in -liberty:
AC_CHECK_LIB(iberty, main)

AC_CONFIG_HEADER(config.h)

dnl Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_CHECK_HEADERS(fcntl.h limits.h strings.h sys/time.h unistd.h)

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_HEADER_TIME

dnl Check the size of ordinary types
AC_CHECK_SIZEOF(char, 1)
AC_CHECK_SIZEOF(short int, 2)
AC_CHECK_SIZEOF(int, 4)
AC_CHECK_SIZEOF(long int, 4)

dnl These are a little bit dangerous, but it's the best I can do right now...
AC_CHECK_TYPE(int8_t, signed char)
AC_CHECK_TYPE(u_int8_t, unsigned char)
AC_CHECK_TYPE(int16_t, signed short int)
AC_CHECK_TYPE(u_int16_t, unsigned short int)
AC_CHECK_TYPE(int32_t, signed int)
AC_CHECK_TYPE(u_int32_t, unsigned int)

dnl Checks for library functions.
AC_FUNC_FNMATCH
AC_TYPE_SIGNAL
AC_FUNC_VPRINTF
AC_CHECK_FUNCS(cfmakeraw getcwd select strdup strerror usleep)

AC_OUTPUT(Makefile)
