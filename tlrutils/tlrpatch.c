/*************************************************************************
 *
 * FILE  tlrpatch.c
 * Copyright (c) 2002 Daniel Kahlin
 * Written by Daniel Kahlin <daniel@kahlin.net>
 * $Id: tlrpatch.c,v 1.6 2002/05/12 11:32:16 tlr Exp $
 *
 * DESCRIPTION
 *   Handle patches on binary files.
 *
 ******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#include "config.h"
#include "util.h"

#define PROGRAM "tlrpatch"
#define PACKAGE_VER "(" PACKAGE ") " VERSION
char *_program=PROGRAM;
char *_package_ver=PACKAGE_VER;

static int verbose;

#define BUFSIZE 8192
#define BUFBASE 0xe000

int do_patch(char *file1, char *patch, char *outfile);
int do_merge(char *patch1, char *patch2, char *outfile);

/*************************************************************************
 *
 * NAME  main()
 *
 * SYNOPSIS
 *   ret = main (argc, argv)
 *   void warning (int, char **)
 *
 * DESCRIPTION
 *   The main entry point.
 *
 * INPUTS
 *   argc             - number of arguments
 *   argv             - a list of argument strings 
 *
 * RESULT
 *   ret              - status (0=ok)
 *
 * KNOWN BUGS
 *   none
 *
 ******/
int main(int argc, char *argv[])
{
    int c;
    int mergemode;
    int ret;
    char *file1,*patch,*outfile;

    /* defaults */
    mergemode=FALSE;


    /*
     * scan for valid options
     */
    while (EOF!=(c=getopt (argc, argv, "vVhm"))) {
        switch (c) {
	
	/* a missing parameter */
	case ':':
	/* an illegal option */
	case '?':
	    exit (1);

	/* print version */
	case 'v':
	    verbose=TRUE;
	    break;

	/* print version */
	case 'V':
	    fprintf (stdout, PROGRAM " " PACKAGE_VER "\n");
	    exit(0);

	/* print help */
	case 'h':
	    fprintf (stdout,
PROGRAM " " PACKAGE_VER "\n"
"Copyright (c) 2002 Daniel Kahlin\n"
"Written by Daniel Kahlin <daniel@kahlin.net>\n"
"\n"
"usage: " PROGRAM " [OPTION]... <infile> <patch> <outfile>\n"
"\n"
"Valid options:\n"
"    -m              merge patches\n"
"    -v              be verbose\n"
"    -h              displays this help text\n"
"    -V              output program version\n"
"\n"
"Examples:\n"
"    tlrpatch rawimage image.pch patchedimage\n"
"    tlrpatch -m patch1.pch patch2.pch merged.pch\n"
"\n"
"tlrpatch takes a binary file and a patch file to produce a patched output\n");
	    exit (0);
	  
	/* run in merge mode */
	case 'm':
	    mergemode=TRUE;
	    break;

	/* default behavior */
	default:
	    break;
	}
    }

    /*
     * optind now points at the first non option argument
     * we expect two more arguments (inname, outname)
     */
    if (argc-optind < 3)
        panic ("too few arguments");
    file1=argv[optind];
    patch=argv[optind+1];
    outfile=argv[optind+2];

    if (!mergemode)
	ret = do_patch(file1,patch,outfile);
    else
	ret = do_merge(file1,patch,outfile);


    exit(ret);
}

int do_patch(char *file1, char *patch, char *outfile)
{
    uint8_t *buf1, tmpbuf[256];
    FILE *fp1,*fp_patch;
    uint16_t base,addr,len;
    int i;

    buf1=malloc(BUFSIZE);
    fp1=fopen(file1,"rb");

    base=fgetc(fp1);
    base|=(fgetc(fp1)<<8);
    fread(buf1,BUFSIZE,1,fp1);
    fclose(fp1);
    base=0xe000;

    fp_patch=fopen(patch,"rb");

/* skip start addr */
    fgetc(fp_patch);
    fgetc(fp_patch);
    len=fgetc(fp_patch);
    len|=(fgetc(fp_patch)<<8);
    fread(tmpbuf,1,4,fp_patch);
    if (strncmp(tmpbuf,"PTCH",4))
	panic("not a patch file");

/* traverse the chunks */
    i=0;
    while (1) {
	addr=fgetc(fp_patch);
	addr|=(fgetc(fp_patch)<<8);
	len=fgetc(fp_patch);
	len|=(fgetc(fp_patch)<<8);
	if (feof(fp_patch) || len==0) break;
	fread(&buf1[addr-base],1,len,fp_patch);
	if (verbose)
	    printf("patch %d: $%04x-$%04x (%d bytes)\n",i,addr,addr+len-1,len);
	i++;
    }
    fclose(fp_patch);

    fp1=fopen(outfile,"wb");
    fputc((base&0xff),fp1);
    fputc((base>>8),fp1);
    fwrite(buf1,BUFSIZE,1,fp1);
    fclose(fp1);

    free(buf1);

    return 0;
}    

int do_merge(char *patch1, char *patch2, char *outfile)
{
    int16_t patchbuffer[BUFSIZE];
    int16_t tmp;
    int start,end,total;
    uint8_t tmpbuf[256];
    FILE *fp_patch,*fp_out;
    uint16_t base,addr,len;
    int i,j,k;
    char *patchname;
    char *patcharray[]={patch1,patch2,NULL};


    base=0xe000;

/* clean out the patch buffer */
    for (i=0; i<BUFSIZE; i++) {
	patchbuffer[i]=-1;
    }


    k=0;
    while ((patchname=patcharray[k])) {

	/* open patch file */
	if (!(fp_patch=fopen(patchname,"rb")))
	    panic("couldn't open file '%s'",patchname);

	/* skip start addr */
	fgetc(fp_patch);
	fgetc(fp_patch);
	len=fgetc(fp_patch);
	len|=(fgetc(fp_patch)<<8);
	fread(tmpbuf,1,4,fp_patch);
	if (strncmp(tmpbuf,"PTCH",4))
	    panic("not a patch file '%s'",patchname);

	/* traverse the chunks */
	i=0;
	while (1) {
	    addr=fgetc(fp_patch);
	    addr|=(fgetc(fp_patch)<<8);
	    len=fgetc(fp_patch);
	    len|=(fgetc(fp_patch)<<8);
	    if (feof(fp_patch) || len==0) break;
	    for (j=0; j<len; j++) {
		tmp=fgetc(fp_patch);
		patchbuffer[(addr-base)+j]=tmp;
	    }
	    if (verbose)
		printf("patch %d: $%04x-$%04x (%d bytes)\n",i,addr,addr+len-1,len);
	    i++;
	}
	fclose(fp_patch);
	k++;
    }


    fp_out=fopen(outfile,"wb");
    fputc(0x00,fp_out);
    fputc(0x00,fp_out);
    fputc(0x04,fp_out);
    fputc(0x00,fp_out);
    fputc('P',fp_out);
    fputc('T',fp_out);
    fputc('C',fp_out);
    fputc('H',fp_out);

/* find a range of differences */
/* This probably has a problem with runs that continue onto the last byte */
    start=end=-1;
    total=0;
    for (i=0; i < BUFSIZE; i++) {

	/* start of a new run? */
	if (patchbuffer[i]!=-1 && start==-1)
		start=i;

	/* end of a previously started run? */
	if (patchbuffer[i]==-1 && start!=-1) {
	    int len;
	    end=i;
	    len=end-start;
	    total+=len;

	    fputc(((start+base)&0xff),fp_out);
	    fputc(((start+base)>>8),fp_out);
	    fputc((len&0xff),fp_out);
	    fputc((len>>8),fp_out);
	    for (j=0; j<len; j++)
		fputc(patchbuffer[start+j],fp_out);

	    if (verbose) {
		printf("--- ");
		if (len==1)
		    printf("$%04x (1 byte):\n",start+base);
		else
		    printf("$%04x-$%04x (%d bytes):\n",start+base,end+base-1,len);
	    }
	    start=end=-1;
	}
    }

/* end patch with the optional empty chunk */
    fputc(0,fp_out);
    fputc(0,fp_out);
    fputc(0,fp_out);
    fputc(0,fp_out);

    fclose(fp_out);

    return 0;
}

/* eof */
