/*************************************************************************
 *
 * FILE  tlrdiff.c
 * Copyright (c) 2002 Daniel Kahlin
 * Written by Daniel Kahlin <daniel@kahlin.net>
 * $Id: tlrdiff.c,v 1.3 2002/11/17 00:19:40 tlr Exp $
 *
 * DESCRIPTION
 *   Handle diffs on binary files.
 *
 * TODO
 *   - switch to set cbm mode.  ($ instead of 0x, load address)
 *   - support for merging patches
 *   - support for ips output.
 *
 ******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdint.h>
/*#include <string.h> */
/*#include <unistd.h> */
#include <sys/types.h>
#include "util.h"

#define PROGRAM "tlrdiff"
#define PACKAGE_VER "(" PACKAGE ") " VERSION
char *_program=PROGRAM;
char *_package_ver=PACKAGE_VER;

#define BUFSIZE 8192
#define BUFBASE 0xe000

void dumpbytes(unsigned char *buf, int start, int end, int offset);
uint8_t dowcrc(uint8_t *data, int length, uint8_t crc);

int do_diff(int argc, char *argv[]);
int do_patch(int argc, char *argv[]);
int do_merge(int argc, char *argv[]);



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
    int ret=-1;
    switch (*argv[1]) {
    case 'd':
	argv++;
	argc--;
	ret = do_diff(argc,argv);
	break;
    case 'p':
	argv++;
	argc--;
	ret = do_patch(argc,argv);
	break;
    case 'm':
	argv++;
	argc--;
	ret = do_merge(argc,argv);
	break;
    default:
	break;
    }

    exit(ret);
}

int do_merge(int argc, char *argv[])
{

    return 0;
}    


int do_patch(int argc, char *argv[])
{
    char *file1, *patch, *outfile;
    uint8_t *buf1, tmpbuf[256];
    FILE *fp1,*fp_patch;
    uint16_t base,addr,len;
    int i;

    file1=argv[1];
    patch=argv[2];
    outfile=argv[3];

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
    if (!strcmp(tmpbuf,"PTCH"))
	panic("not a patch file");

/* traverse the chunks */
    i=0;
    while (1) {
	addr=fgetc(fp_patch);
	addr|=(fgetc(fp_patch)<<8);
	len=fgetc(fp_patch);
	len|=(fgetc(fp_patch)<<8);
	if (feof(fp_patch)) break;
	fread(&buf1[addr-base],1,len,fp_patch);
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


int do_diff(int argc, char *argv[])
{
    char *file1,*file2;
    int i;
    unsigned char *buf1,*buf2;
    FILE *fp1,*fp2;
    int start,end,total;
    uint16_t base;

    file1=argv[1];
    file2=argv[2];

    buf1=malloc(BUFSIZE);
    fp1=fopen(file1,"rb");
    base=fgetc(fp1);
    base|=(fgetc(fp1)<<8);
    fread(buf1,BUFSIZE,1,fp1);
    fclose(fp1);

    buf2=malloc(BUFSIZE);
    fp2=fopen(file2,"rb");
    base=fgetc(fp2);
    base|=(fgetc(fp2)<<8);
    fread(buf2,BUFSIZE,1,fp2);
    fclose(fp2);

/* find a range of differences */
/* This probably has a problem with runs that continue onto the last byte */
    start=end=-1;
    total=0;
    for (i=0; i < BUFSIZE; i++) {

	/* start of a new run? */
	if (buf1[i]!=buf2[i] && start==-1)
		start=i;

	/* end of a previously started run? */
	if (buf1[i]==buf2[i] && start!=-1) {
	    int len;
	    end=i;
	    len=end-start;
	    total+=len;

	    printf("--- ");
	    if (len==1)
		printf("$%04x (1 byte):\n",start+BUFBASE);
	    else
		printf("$%04x-$%04x (%d bytes):\n",start+BUFBASE,end+BUFBASE-1,len);

	    printf("<<<\n");
	    dumpbytes(buf1,start,end,BUFBASE);
	    printf(">>>\n");
	    dumpbytes(buf2,start,end,BUFBASE);
	    start=end=-1;
	}
    }
    printf("%d bytes differ\n",total); 

    free(buf1);
    free(buf2);

    return 0;
}

#define NUMPERLINE 16
void dumpbytes(unsigned char *buf, int start, int end, int offset)
{
    int i,n=0;
    for (i=start; i<end; i++) {
	if (n==NUMPERLINE) {
	    printf("\n");
	    n=0;
	}
	if (!n)
	    printf("%04x:",i+offset);
	printf(" %02x",buf[i]);
	n++;
    }
    printf("\n");
}


struct patch_entry {
    struct patch_entry *next;
    uint32_t addr;
    uint32_t len;
    uint8_t *data;
};

uint32_t patch_minaddr=0x0000;
uint32_t patch_maxaddr=0xffff;
static struct patch_entry *patch_head;

void patch_init(void)
{
    struct patch_entry *this, *next;

    if ((this=patch_head)) {
	while((next=this->next)) {
	    if (this->data)
		free(this->data);
	    free(this);
	    this=next;
	}
	patch_head=NULL;
    }
}


int patch_set(uint8_t *data, uint32_t len, uint32_t addr)
{
    if (addr < patch_minaddr || (addr+len) >= patch_maxaddr)
	return -1;	
//    memcpy(&patch_buffer[addr],data,len);
    return 0;
}    

int patch_get(int flag)
{
    return 0;
}

/*************************************************************************
 *
 * NAME  dowcrc()
 *
 * SYNOPSIS
 *   crc = dowcrc (data, length, crc)
 *   uint8_t dowcrc (uint8_t *, int, uint8_t)
 *
 * DESCRIPTION
 *   Calculate the dowcrc of the data (works with little endian)
 *
 * INPUTS
 *   data                - pointer to the data to be crc:ed
 *   length              - length of the data to be crc:ed
 *   crc                 - initial crc value
 *
 * RESULT
 *   crc                 - the resulting crc.
 *
 * KNOWN BUGS
 *   none
 *
 ******/
uint8_t dowcrc(uint8_t *data, int length, uint8_t crc)
{
    int i,j;
    for (i=0; i<length; i++) {
        for (j=0; j<8; j++) {
            crc=(crc>>1) ^ ((crc&1)?0x8c:0);
            crc^=((data[i]>>j)&0x1)?0x8c:0;
        }
    }

    return crc;
}


/* eof */
