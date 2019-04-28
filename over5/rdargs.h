/*
  rdargs.h
*/

#ifndef INCLUDED_RDARGS_H
#define INCLUDED_RDARGS_H

typedef long ARR_T;
#define ARR_T_MAX LONG_MAX

char *readargs(char *tplstr, ARR_T **array, int argc, char **argv);
int endreadargs(void);

#endif /* INCLUDED_RDARGS_H */
