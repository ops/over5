/*************************************************************************
**
** cbm_zipcode.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
** NOT MACHINE DEPENDENT
**
******/

#include "config.h"

#include <stdio.h>
#include <string.h>

#include "util.h"

#include "cbm.h"


char *zippart(int num, char *basename, char *path, int starttrack,
	      int endtrack, u_int8_t *buffer);
void zipsector(FILE *outfp, int track, int sector, u_int8_t *trackptr);
void ziptrack(FILE *outfp, int track, int numsectors, u_int8_t *trackptr);

char *unzippart(int num, char *basename, char *path, int starttrack,
		int endtrack, u_int8_t *buffer);
void unziptrack(FILE *infp, int track, int numsectors, u_int8_t *buffer);
int unzipsector(FILE *infp, int track, int numsectors, u_int8_t *buffer);



/*************************************************************************
**
** do unzip
**
** '1!' + basename  tracks 1-8   skip first 4 bytes
** '2!' + basename  tracks 9-16  skip first 2 bytes
** '3!' + basename  tracks 17-25 skip first 2 bytes
** '4!' + basename  tracks 26-35 skip first 2 bytes
**
** Stored sector:
**  0x00  tracknum
**  0x01  sectornum
**  0x02  data*256
**  sizeof=0x102
**
** Filled sector:
**  0x00  tracknum | 0x40
**  0x01  sectornum
**  0x02  fillbyte
**  sizeof=0x03
**
** Packed sector:
**  0x00  tracknum | 0x80
**  0x01  sectornum
**  0x02  length
**  0x03  controlbyte
**   (0x00 ctrlbyte, 0x01 repnum, 0x02 repbyte)
**  0x04  data*length
**  sizeof=0x04+length
**
******/
void dounzip(char *basename, char *path, u_int8_t *buffer)
{

    unzippart(1,basename,path,1,8,buffer);
    unzippart(2,basename,path,9,16,buffer+43008);
    unzippart(3,basename,path,17,25,buffer+86016);
    unzippart(4,basename,path,26,35,buffer+130048);

}



/*************************************************************************
**
** unzippart
**
******/
char *unzippart(int num, char *basename, char *path, int starttrack, int endtrack, u_int8_t *buffer)
{
    int track,numsectors;
    FILE *infp;
    char namebuf[256],id1,id2;
    int addr,realaddr;
    char tmp[3];

    strncpy(namebuf,path,255);
    tmp[0]=num+0x30;
    tmp[1]='!';
    tmp[2]=0;
    strncat(namebuf,tmp,255);
    strncat(namebuf,basename,255);
    if (!(infp=fopen(namebuf,"rb")))
	panic("couldn't open file '%s'",namebuf);

    addr=getc(infp)+(getc(infp)<<8);

    if (num==1) {
	id1=getc(infp);
	id2=getc(infp);
	realaddr=0x03fe;
    } else {
	realaddr=0x0400;
    }

    if (addr!=realaddr)
	printf("Warning: bogus load address in '%s' $%04x ($%04x)!\n",namebuf,addr,realaddr);

    for (track=starttrack; track<=endtrack; track++) {
	numsectors=17+((track<18)?2:0)+((track<25)?1:0)+((track<31)?1:0);
	unziptrack(infp,track,numsectors,buffer);
	buffer+=0x100*numsectors;
    }

    fclose(infp);
    return(NULL);
}


/*************************************************************************
**
** unziptrack
**
******/
void unziptrack(FILE *infp, int track, int numsectors, u_int8_t *buffer)
{
    int i;
    char read[21];

/*** empty table ***/
    for (i=0; i<21; i++)
	read[i]=0;

/*** read 'numsectors' sectors ***/
    for (i=0; i<numsectors; i++)
	read[unzipsector(infp,track,numsectors,buffer)]++;

/*** check if all sectors have been depacked ***/
    for (i=0; i<numsectors; i++) {
	if (read[i]==0)
	    panic("missing sector %d on track %d",i,track);
	if (read[i]>1)
	    panic("duplicate sector %d on track %d",i,track);
    }

}

/*************************************************************************
**
** unzipsector
**
******/
int unzipsector(FILE *infp, int track, int numsectors, u_int8_t *trackptr)
{
    int thissector, thistrack, length, repchr,num,i,j;
    u_int8_t tkn,*ptr;

    thistrack=getc(infp);
    thissector=getc(infp);

    if ((thistrack&0x3f)!=track)
	panic("unexpected track");
    if ((thissector)>=numsectors)
	panic("unexpected sector");


    ptr=trackptr+0x100*thissector;

    switch (thistrack&0xc0) {

/*** stored sector ***/
    case 0x00:
	for (i=0; i<0x100; i++) {
	    *ptr++=getc(infp);
	}
	break;

/*** filled sector ***/
    case 0x40:
	tkn=getc(infp);
	for (i=0; i<0x100; i++) {
	    *ptr++=tkn;
	}
	break;

/*** packed sector ***/
    case 0x80:
	length=getc(infp);
	repchr=getc(infp);
	for (i=0; i<length; i++) {
	    tkn=getc(infp);
	    if (tkn==repchr) {
		i+=2;
		num=getc(infp);
		tkn=getc(infp);
		for(j=0; j<num; j++) {
		    *ptr++=tkn;
		}
	    } else {
		*ptr++=tkn;
	    }

	}

	break;

/*** unknown method ***/
    default:
	panic("unknown packtype track 0x%02x sector 0x%02x",thistrack,thissector);
	break;
    }

    return(thissector);
}






/*************************************************************************
**
** dozip
**
******/
void dozip(char *basename, char *path, u_int8_t *buffer)
{

    zippart(1,basename,path,1,8,buffer);
    zippart(2,basename,path,9,16,buffer+43008);
    zippart(3,basename,path,17,25,buffer+86016);
    zippart(4,basename,path,26,35,buffer+130048);

}

/*************************************************************************
**
** zippart
**
******/
char *zippart(int num, char *basename, char *path, int starttrack, int endtrack, u_int8_t *buffer)
{
    int track,numsectors;
    FILE *outfp;
    char namebuf[256],id1,id2;
    char tmp[3];

    strncpy(namebuf,path,255);
    tmp[0]=num+0x30;
    tmp[1]='!';
    tmp[2]=0;
    strncat(namebuf,tmp,255);
    strncat(namebuf,basename,255);
    if (!(outfp=fopen(namebuf,"wb")))
	panic("couldn't open file '%s'",namebuf);

    if (num==1) {
	id1=*(buffer+91392+0xa2);
	id2=*(buffer+91392+0xa3);

	putc(0xfe,outfp);
	putc(0x03,outfp);
	putc(id1,outfp);
	putc(id2,outfp);
    } else {
	putc(0x00,outfp);
	putc(0x04,outfp);
    }


    for (track=starttrack; track<=endtrack; track++) {
	numsectors=17+((track<18)?2:0)+((track<25)?1:0)+((track<31)?1:0);
	ziptrack(outfp,track,numsectors,buffer);
	buffer+=0x100*numsectors;
    }

    fclose(outfp);
    return(NULL);
}

/*************************************************************************
**
** ziptrack
**
** track 01:  00 11 01 12 02 13 03 14 04 15 05 16 06 17 07 18 08 19 09 20 10
** track 18:  00 10 01 11 02 12 03 13 04 14 05 15 06 16 07 17 08 18 09
** track 25:  00 09 01 10 02 11 03 12 04 13 05 14 06 15 07 16 08 17
** track 31:  00 09 01 10 02 11 03 12 04 13 05 14 06 15 07 16 08
**
******/
void ziptrack(FILE *outfp, int track, int numsectors, u_int8_t *trackptr)
{
    int i,j,sector;
    char written[21];
    int intrl;

/*** empty table ***/
    for (i=0; i<21; i++)
	written[i]=0;

    intrl=(numsectors+1)/2;

    sector=0;
/*** write 'numsectors' sectors ***/
    for (i=0; i<numsectors; i++) {
	zipsector(outfp,track,sector,trackptr);
	written[sector]=1;

	/*** find next empty sector ***/
	sector=(sector+intrl)%numsectors;
	for (j=0; j<numsectors; j++) {
	    if (written[sector])
		sector=(sector+1)%numsectors;
	}

    }

}

/*************************************************************************
**
** zipsector
**
******/
void zipsector(FILE *outfp, int track, int sector, u_int8_t *trackptr)
{
    int packedlen, first, rep,i,j,k;
    u_int8_t *ptr;                 /* !! was signed */
    u_int8_t chr[256];
    u_int8_t packbuf[256+20]; /* safety */
    int codebyte=-1;
    int same;

    ptr=trackptr+0x100*sector;

/*** are all bytes the same? ***/
    first=ptr[0];
    same=1;
    for (i=0; i<0x100; i++) {
	if (ptr[i]!=first) {
	    same=0;
	    break;
	}
    }
/*** if they were, write a 'fill' sector ***/
    if (same) {
	putc(track|0x40,outfp);
	putc(sector,outfp);
	putc(first,outfp);
	return;
    }


/*** count bytes ***/
    for (i=0; i<0x100; i++)
	chr[i]=0;
    for (i=0; i<0x100; i++)
	chr[ptr[i]]++;

/*** find codebyte ***/
    for (i=0; i<0x100; i++) {
	if (chr[i]==0) {
	    codebyte=i;
	    break;
	}
    }

    packedlen=256; /* initial */
/*** pack ***/
    if (codebyte!=-1) { 
	i=0;
	j=0;
	while(i<0x100) {
	    /*** check for repeat ***/
	    first=ptr[i];
	    rep=0;
	    for (k=i; k<0x100; k++) {
		if (ptr[k]!=first)
		    break;
		rep++;
	    }

	    if (rep>256) panic("internal zippacker overflow 1");

	    /*** check ***/
	    if (rep>3) {
		packbuf[j]=codebyte;
		packbuf[j+1]=rep;
		packbuf[j+2]=first;
		j+=3;
	    } else {
		for (k=0; k<rep; k++) {
		    packbuf[j]=first;
		    j++;
		}
	    }
	    i+=rep;
	    if (j>256+20) panic("internal zippacker overflow 2");
	}
	packedlen=j;
    }

/*** check what to do ***/

    if ((packedlen+4) < (2+0x100)) {
	/*** packed sector ***/
	putc(track|0x80,outfp);
	putc(sector,outfp);
	putc(packedlen,outfp);
	putc(codebyte,outfp);
	for (i=0; i<packedlen; i++)
	    putc(packbuf[i],outfp);

    } else {
	/*** stored sector ***/
	putc(track,outfp);
	putc(sector,outfp);
	for (i=0; i<0x100; i++)
	    putc(ptr[i],outfp);
    }


}


