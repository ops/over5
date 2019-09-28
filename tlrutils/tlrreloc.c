/*************************************************************************
 *
 * FILE  tlrreloc.c
 * Copyright (c) 2002 Daniel Kahlin
 * Written by Daniel Kahlin <daniel@kahlin.net>
 * $Id: tlrreloc.c,v 1.3 2002/05/08 00:29:32 tlr Exp $
 *
 * DESCRIPTION
 *   Tries to extract reloc information.
 *
 ******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
/*#include <string.h> */
#include <unistd.h>
#include <sys/types.h>

#include "config.h"
#include "util.h"

#define PROGRAM "tlrreloc"
#define PACKAGE_VER "(" PACKAGE ") " VERSION
char *_program=PROGRAM;
char *_package_ver=PACKAGE_VER;


int verbose;

int findreloc(char *file1, uint16_t base1, char *file2, uint16_t base2, char *outfile, int relativemode, int bytemode);

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
    int ret;
    char *file1,*file2,*outfile;
    int relativemode,bytemode;


    /* defaults */
    relativemode=FALSE;
    bytemode=FALSE;


    /*
     * scan for valid options
     */
    while (EOF!=(c=getopt (argc, argv, "vVhrb"))) {
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
"usage: " PROGRAM " [OPTION]... <file1> <file2> <outfile>\n"
"\n"
"Valid options:\n"
"    -r              output in relative mode\n"
"    -b              restrict output to byte offsets (only with -r)\n"
"    -v              be verbose\n"
"    -h              displays this help text\n"
"    -V              output program version\n"
"\n"
"Examples:\n"
"    tlrreloc -r -b fastrs20_0000 fastrs20_0100 reloc_tmp\n"
"\n"
"tlrreloc takes two binary files and tries to find relocation information\n");
	    exit (0);
	  
	/* run in relative mode */
	case 'r':
	    relativemode=TRUE;
	    break;

	/* run in byte mode */
	case 'b':
	    bytemode=TRUE;
	    break;

	/* default behavior */
	default:
	    break;
	}
    }

    /*
     * optind now points at the first non option argument
     * we expect three more arguments (file1, file2, outfile)
     */
    if (argc-optind < 3)
        panic ("too few arguments");
    file1=argv[optind];
    file2=argv[optind+1];
    outfile=argv[optind+2];

    ret = findreloc(file1,0x0001,file2,0x0101,outfile,relativemode,bytemode);

    exit(ret);
}

int findreloc(char *file1, uint16_t base1, char *file2, uint16_t base2, char *outfile, int relativemode, int bytemode)
{
    FILE *file1_fp,*file2_fp,*outfile_fp;
    uint8_t *buf1, *buf2;
    int len1, len2, len;
    uint16_t loadaddr1,loadaddr2;
    uint8_t msboffset,msbdiff,lsbdiff;
    uint8_t diff;
    int i,last,rel;

    file1_fp=fopen(file1,"rb");
    loadaddr1=fgetc(file1_fp);
    loadaddr1|=(fgetc(file1_fp)<<8);
    fseek(file1_fp,0,SEEK_END);
    len1=ftell(file1_fp)-2;
    fseek(file1_fp,2,SEEK_SET);
    buf1=malloc(len1);
    fread(buf1,len1,1,file1_fp);
    fclose(file1_fp);

    file2_fp=fopen(file2,"rb");
    loadaddr2=fgetc(file2_fp);
    loadaddr2|=(fgetc(file2_fp)<<8);
    fseek(file2_fp,0,SEEK_END);
    len2=ftell(file2_fp)-2;
    fseek(file2_fp,2,SEEK_SET);
    buf2=malloc(len2);
    fread(buf2,len2,1,file2_fp);
    fclose(file2_fp);

/* basic test, file lengths must match */
    if (len1 != len2)
	panic("lengths differ, cannot extract relocation information");
    len=len1;

/* calculate the differences of msb and lsb */
    msbdiff=(base2>>8) - (base1>>8);
    lsbdiff=(base2&0xff) - (base1&0xff);
    msboffset=base1>>8;
    if (lsbdiff != 0x00)
	panic("lsb difference is not 0, cannot extract relocation information");

    if (msbdiff == 0x00)
	panic("msb difference is 0, cannot extract relocation information");

    if (msboffset)
	warning("must use msboffset 0x%02x",msboffset);

/* open output */
    outfile_fp=fopen(outfile,"wb");

/* scan for differing bytes */
    last=0;
    for (i=0; i<len; i++) {
	if ((diff=buf2[i]-buf1[i])) {
	    if (diff==msbdiff) {
		printf("msbreloc @ 0x%04x\n",i);
		if (!relativemode) {
		    fputc((i&0xff),outfile_fp);
		    fputc((i>>8),outfile_fp);
		} else {
		    rel=i-last;
		    if (rel>255) {
			if (bytemode)
			    panic("offset too big ($%04x)",rel);
			fputc(0x00,outfile_fp);
			fputc((rel&0xff),outfile_fp);
			fputc((rel>>8),outfile_fp);
		    } else 
			fputc(rel,outfile_fp);
		    last=i;
		}
	    } else
		panic("invalid difference (0x%02x) @ 0x%04x, cannot extract relocation information",diff,i);		
	}
    }

    if (!relativemode) {
	fputc(0x00,outfile_fp);
	fputc(0x00,outfile_fp);
    } else {
	fputc(0x00,outfile_fp);
	fputc(0x00,outfile_fp);
	fputc(0x00,outfile_fp);
    }
    fclose(outfile_fp);

    free(buf1);
    free(buf2);
    return 0;
}    

/* eof */
