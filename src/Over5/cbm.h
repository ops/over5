
/*************************************************************************
**
** cbm.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

/* cbm_zipcode.c */
void dounzip(char *basename, char *path, u_int8_t *buffer);
void dozip(char *basename, char *path, u_int8_t *buffer);


/* cbm_directory.c */

#define CDET_UNKNOWNFILE  0xfd
#define CDET_HEADER       0xfe
#define CDET_BLOCKSFREE   0xff
#define CDET_DEL          0x00
#define CDET_PRG          0x01
#define CDET_SEQ          0x02
#define CDET_USR          0x03
#define CDET_REL          0x04

#define CDEP_NONE         0x00
#define CDEP_READONLY     0x80
#define CDEP_NOTCLOSED    0x40

struct cbm_direntry {
  int32_t  size;
  int32_t  blocks;
  char  name[40];
  int32_t  type;
  int32_t  protection;
  char printable[40];
};

struct cbm_dirlock {
  char *buffer;
  u_int32_t len;
  char *ptr;
  struct cbm_direntry direntry;
};

struct cbm_dirlock *cbm_lockdir(int device);
void cbm_unlockdir(struct cbm_dirlock *cdl);
struct cbm_direntry *cbm_examine(struct cbm_dirlock *mdl);
