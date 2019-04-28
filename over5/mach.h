/*************************************************************************
**
** mach.h
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/


/*************************************************************************
**
** public function declarations
**
******/
void mach_startup(void);
void mach_noerror(void);
int mach_rdargs(char *thetemplate, int32_t *array, int argc, char **argv);
void mach_closeall(int ret);
char *mach_getargstr(void);

struct mach_matchstruct *mach_parsepattern(char *patternstr);
void mach_unparsepattern(struct mach_matchstruct *mms);
int mach_matchpattern(struct mach_matchstruct *mms, char *str);

struct mach_dirlock *mach_lockdir(char *path);
void mach_unlockdir(struct mach_dirlock *mdl);
struct mach_direntry *mach_examine(struct mach_dirlock *mdl);
int mach_isdir(struct mach_direntry *mde);

char *mach_getpath(char *fileref, char *path, int maxsize);
void mach_addpart(char *path, char *name, int size);

char *mach_getconfigfile(char *buffer, int size);

#define MACH_FILENAMELEN  108
#define MACH_PATHLEN  108
#define MACH_FILEREFLEN 255


/*************************************************************************
**
** internal declarations
**
******/

#ifdef WIN32_VERSION

#include "rdargs.h"
#include <windows.h>

#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION

#include "rdargs.h"
#include <dirent.h>
#include <sys/stat.h>

#endif /* LINUX_VERSION */

/*************************************************************************
**
** mach definitions
**
******/
struct mach_matchstruct {
    char iswild;
#ifdef WIN32_VERSION
    char *patternstr;
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    char *patternstr;
#endif /* LINUX_VERSION */
};

struct mach_direntry {
    char *name;
#ifdef WIN32_VERSION
    int32_t size;
    int32_t sizeH;
    int32_t type;
    int32_t wintype;
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    int32_t size;
    int32_t type;
    struct stat attribs;
#endif /* LINUX_VERSION */
};

struct mach_dirlock {
#ifdef WIN32_VERSION
    HANDLE handle;
    char *path;
    WIN32_FIND_DATA wfd;
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    char *path;
    DIR *dir;
    struct dirent *dir_ent;
#endif /* LINUX_VERSION */
    struct mach_direntry direntry;
};


/*************************************************************************
**
** Configuration definitions
**
******/

/*
** configuration structure!
*/
struct O5Config {
    int device;       /* cbm device number */
    char *serdevice;
};

#define CT_NUMBER 0x01
#define CT_STRING 0x02

struct ConfigTable {
    char *ct_name;
    int ct_type;
    u_int32_t *ct_dest;
};

extern struct ConfigTable configtable[];

/* eof */
