/*************************************************************************
**
** config.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "mach_include.h"
#include "main.h"
#include "mach.h"
#include "config.h"
#include "convert.h"

void handleline(char *ptr, struct ConfigTable configtab[]);
#define MAXLINE 256


/*************************************************************************
**
** readconfig
**
******/
void readconfig(char *configfile, struct ConfigTable configtab[])
{
    FILE *fp;
    char buf[MAXLINE];

    if (!(fp=fopen(configfile,"rb")))
	return;

    while (fgets(buf, MAXLINE, fp)) {
	handleline(buf,configtab);
    }

    fclose(fp);
    return; 

}

/*************************************************************************
**
** handleline
**
******/
void handleline(char *str, struct ConfigTable configtab[])
{
    int num,fail,number;
    char tkn;
    char *value,*tag,*tmp,*ptr;

    char *name;
    u_int32_t *dest = (void *)NULL;
    int type = 0;

    ptr=str;
/*
** Split line into 'tag' and 'value'
*/
    while(isspace(*str)) {
	str++;
    }
/* eol? */
    if (*str=='\0')
	return;

/* terminate if comment */
    if (*str==';' || *str=='#')
	return;

/* start of tag */
    tag=str;

/* find end of tag */
    while((tkn=*str)) {
	if (tkn=='=') break;
	str++;
    }

/* eol? */
    if (*str=='\0')
	panic("parse error in config file.\n%s\n",str);

    *str='\0';
    str++;

/* skip spaces before value */
    while(isspace(*str)) {
	str++;
    }
/* eol? */
    if (*str=='\0')
	panic("parse error in config file.\n%s\n",ptr);

    value=str;
/* find end of value */
    while(!isspace(*str)) {
	/* eol? */
	if (*str=='\0')
	    break;
	str++;
    }
    *str='\0';



/*
** match tag with keyword
*/
    num=0;
    fail=TRUE;
    while ((name=configtab[num].ct_name)) {
#ifndef LINUX_VERSION
	if (0==strnicmp(tag,name,strlen(name))) {
#else
	if (0==strncasecmp(tag,name,strlen(name))) {
#endif /* ! LINUX_VERSION */
	    type=configtab[num].ct_type;
	    dest=configtab[num].ct_dest;
	    fail=FALSE;
	    break;
	}
	num++;
    }
    if (fail)
	panic("parse error in config file.\n%s\n",ptr);

/*
** handle config data
** char *name;  (name of tag)
** int type;    (type of tag)
** void *dest;  (destination address)
** char *value; (the value string)
*/

    switch (type) {
    case CT_STRING:
	if (!(tmp=(char *) jalloc(strlen(value)+1)))
	    panic("no mem in config reader");
	strcpy(tmp,value);
	*dest=(u_int32_t)tmp;
	if (debug>=DBG_FULL)
	    printf("STRING: %s=%s\n",name,tmp);
	break;
    case CT_NUMBER:
	number=makenum(value,0,65535,10);
	if (number==-1)
	    panic("Illegal number in config file.\n%s\n",ptr);
	*dest=(u_int32_t)number;
	if (debug>=DBG_FULL)
	    printf("NUMBER: %s=%d\n",name,number);
	break;
    default:
	panic("internal error in config parser");
    }

    return; 

}
