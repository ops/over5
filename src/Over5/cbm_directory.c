/*************************************************************************
**
** cbm_directory.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDANT
**
******/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "mach_include.h"
#include "main.h"
#include "block.h"
#include "o5protocol.h"
#include "protocol.h"
#include "main.h"
#include "convert.h"
#include "cbm.h"

#include "mach.h"


/*************************************************************************
**
** cbm_lockdir
**
******/
struct cbm_dirlock *cbm_lockdir(int device)
{
    struct cbm_dirlock  *cdl=NULL;

    if (!(cdl=(struct cbm_dirlock *)jalloc(sizeof(struct cbm_dirlock))))
	panic("no mem");

    bl_recvdir("$",(u_int8_t **) &(cdl->buffer),&(cdl->len),device);

    cdl->ptr=cdl->buffer+2;

/* get the header line */
    cbm_examine(cdl);

    return(cdl);
}


/*************************************************************************
**
** cbm_unlockdir
**
******/
void cbm_unlockdir(struct cbm_dirlock *cdl)
{
    jfree(cdl->buffer);
    jfree(cdl);
    return;
}

/*************************************************************************
**
** cbm_examine
**
******/
struct cbm_direntry *cbm_examine(struct cbm_dirlock *cdl)
{
    u_int8_t *ptr, *text, *tmp, *name, *type;
    int line, namelen;

    ptr=cdl->ptr;

    if (*ptr|*(ptr+1)) {
	line=*(ptr+2)+*(ptr+3)*256;
	text=ptr+4;

	cdl->direntry.blocks=line;
	cdl->direntry.size=line*254;

/*
** if text begins with RVS ON and 'line'
** is null this is the HEADER
*/
	if (*text==0x12 && line==0)
	    cdl->direntry.type=CDET_HEADER;

/*
** skip spaces and test character
*/
	tmp=text;
	while(isspace(*tmp))
	    tmp++;
	if (*tmp=='\0')
	    panic("unexpected eol in cbm directory");

	if (*tmp=='\"') {
/*
** Is file.
** We have to convert the filename, and
** detect the filetype and protection.
*/
	    cdl->direntry.type=CDET_UNKNOWNFILE;
	    cdl->direntry.protection=CDEP_NONE;
/*
**  iceolate name
*/
	    tmp++;
	    name=tmp;
	    while (*tmp!='\"') {
		if (*tmp=='\0')
		    panic("unexpected eol in cbm directory");
		tmp++;
	    }
	    namelen=tmp-name;
	    petscii2str(name,cdl->direntry.name,namelen);
	    cdl->direntry.name[namelen]='\0';
	    tmp++;

/*
** skip spaces after name
*/
	    while(isspace(*tmp))
		tmp++;
/*
** detect if file is unclosed.
*/
	    if (*tmp=='*') {
		cdl->direntry.protection|=CDEP_NOTCLOSED;
		tmp++;
	    }
	    if (*tmp=='\0')
		panic("unexpected eol in cbm directory");
/*
** check file type
*/
	    type=tmp;
	    if (!strncmp("DEL",tmp,3))
		cdl->direntry.type=CDET_DEL;
	    if (!strncmp("SEQ",tmp,3))
		cdl->direntry.type=CDET_SEQ;
	    if (!strncmp("PRG",tmp,3))
		cdl->direntry.type=CDET_PRG;
	    if (!strncmp("USR",tmp,3))
		cdl->direntry.type=CDET_USR;
	    if (!strncmp("REL",tmp,3))
		cdl->direntry.type=CDET_REL;

	    if (cdl->direntry.type!=CDET_UNKNOWNFILE) {
		tmp+=3;
		if (*tmp=='<')
		    cdl->direntry.protection|=CDEP_READONLY;
	    }
	    //printf("%s\n",type);
	    //printf("p: %d \"%s\" %02x %02x\n",cdl->direntry.blocks,cdl->direntry.name,cdl->direntry.type, cdl->direntry.protection);

	} else if (*tmp=='B')
	    cdl->direntry.type=CDET_BLOCKSFREE;

	sprintf(cdl->direntry.printable,"%d %s",line,text);
/*
** Update ptr in dirlock so we find the next item
** when called again;
*/
	ptr=ptr+(strlen(text)+5);
	cdl->ptr=ptr;

/* test if this is a file on line */
	if (cdl->direntry.type==CDET_BLOCKSFREE)
	    return(NULL);
	else
	    return(&(cdl->direntry));
    } else
	return(NULL);
}

