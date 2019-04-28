
/*************************************************************************
**
** Convert.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "main_rev.h"

#include "mach_include.h"
#include "convert.h"


/*************************************************************************
**
** str2petscii
**
******/
void str2petscii(char *src, char *dest,int maxlen)
{
    char tkn;

    while(TRUE) {
	tkn=*src++;

	switch (tkn) {

	case '_':
	    tkn=' ';
	    break;

	case '\\':
	    tkn='/';
	    break;

	case '[':
	    tkn='(';
	    break;

	case ']':
	    tkn=')';
	    break;

	default:
	    tkn=toupper(tkn);
	    break;
	}

	*dest++=tkn;
	maxlen--;
	if (maxlen==0) break;
	if (tkn==0) break;
    }
}

/*************************************************************************
**
** petscii2str
**
******/
void petscii2str(char *src, char *dest,int maxlen)
{
    char tkn;

    while(TRUE) {
	tkn=*src++;

	switch (tkn) {

	case '/':
	    tkn='\\';
	    break;

	case '(':
	    tkn='[';
	    break;

	case ')':
	    tkn=']';
	    break;

	default:
	    tkn=toupper(tkn);
	    break;
	}

	*dest++=tkn;
	maxlen--;
	if (maxlen==0) break;
	if (tkn==0) break;
    }
}

/*************************************************************************
**
** makenum
**
******/
int32_t makenum(char *str, int32_t lowvalue, int32_t highvalue, int defaultradix)
{
    int32_t num;
    char tkn;
    int digitvalue;
    int radix;

    radix=defaultradix;

/*
** skip whitespaces, if any.
*/
    while(isspace(*str)) {
	str++;
    }

/*
** check eol for safety
*/
    if (*str=='\0')
	return(-1);

/*
** determine radix
*/
    switch (tolower(*str)) {

/* '0' maybe C-like */
    case '0':
	switch (tolower(*(str+1))) {
        case 'x':
	    radix=16;
	    str+=2;
	    break;
        default:
	    break;
	}
	break;

/* '$' hex prefix */
    case '$':
	radix=16;
	str++;
	break;

/* '+' decimal prefix */
    case '+':
/* '#' decimal prefix */
    case '#':
	radix=10;
	str++;
	break;

/* '@' octal prefix */
    case '@':
/* '&' octal prefix */
    case '&':
	radix=8;
	str++;
	break;

/* '%' binary prefix */
    case '%':
	radix=2;
	str++;
	break;

/* no special prefix, use default radix */
    default:
	break;
    }

/*
** convert the number
*/
    num=0;
    while((tkn=tolower(*str))) {
	num*=radix;

	if (tkn>='0' && tkn<='9')
	    digitvalue=tkn-'0';
	else if (tkn>='a' && tkn<='f')
	    digitvalue=tkn-'a'+10;
	else
	    return(-1);

	if (digitvalue>=radix)
	    return(-1);

	num+=digitvalue;
	str++;
    }

/*
** Check for bounds
*/
    if (num<lowvalue || num>highvalue)
	return(-1);

/*
** All ok, return number!
*/
    return(num);
}


