
/*************************************************************************
**
** Convert.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#include <stdint.h>

void str2petscii(char *src, char *dest,int maxlen);
void petscii2str(char *src, char *dest,int maxlen);
int32_t makenum(char *str, int32_t lowvalue, int32_t highvalue, int defaultradix);
