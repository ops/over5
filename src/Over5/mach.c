
/*************************************************************************
**
** mach.c
** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
**
******/

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>

/* There is is not a fnmatch.h in the Mingw32 distribution,
   but the function is included in libiberty.a */
#ifdef __MINGW32__
    #define FNM_PATHNAME    1
    #define FNM_NOESCAPE    2
    #define FNM_PERIOD      4
    #define FNM_LEADING_DIR 8
    #define FNM_CASEFOLD    16
    #define FNM_NOMATCH     1
    extern int fnmatch(const char *pattern, const char *string, int flags);
#else
    #include <fnmatch.h>
#endif

#include "main_rev.h"
#include "mach_include.h"
#include "main.h"
#include "mach.h"
#include "rdargs.h"
#include "block.h"

/*** machine dependent stuff ***/
#ifdef WIN32_VERSION
# include <windows.h>
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION
# include <dirent.h>
# include <limits.h>
# include <signal.h>
# include <sys/stat.h>
# include <unistd.h>
#endif /* LINUX_VERSION */

BOOL breakhandler(DWORD type);

int didrdargs=FALSE;

/*************************************************************************
**
** mach_startup
**
******/
void mach_startup(void)
{

    /* print title */
    puts(PROGRAM_NAME " " PROGRAM_VER
	 "  Copyright (c) 1995,1996 Daniel Kahlin." );

#ifdef WIN32_VERSION
    o5config.serdevice="COM1";
    if (!SetConsoleCtrlHandler(&breakhandler, TRUE))
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    o5config.serdevice=DEFAULT_PORT;
    if (signal(SIGINT, (void*)&breakhandler) == SIG_ERR)
#endif /* LINUX_VERSION */

	panic("couldn't set break trap");

}


/*************************************************************************
**
** mach_noerror
**
******/
void mach_noerror(void)
{
    return;
}

/*************************************************************************
**
** NAME  mach_rdargs()
**
** SYNOPSIS
**   ret=mach_rdargs(thetemplate, array, params)
**   int mach_rdargs(char *, int32_t *, char *)
**
** DESCRIPTION
**   parses the string params according to the template, and fills in
**   array.
**   the template consists of several entries separated by commas.
**   Every entry has a corresponding place in the array.
**   If a parameter is enclosed by quotes they will be stripped.
**   Abbreviations are allowed using "abbrev=option" (ex. "Q=QUICK")
**   The default option is String.
**
**   /S - Switch.  If present, array location will be non-zero.  Zero
**        otherwise.
**
**   /N - Number.  If present, array location will contain a pointer
**        to the longword.  Zero otherwise.
**
**   /A - Required. This option must be given a value, or an error is
**        given.
**
**   /M - Multiple strings. Will take any number of strings. array
**        location will contain a pointer to an array of strings.
**        If there are '/A' options after the '/M', they will be
**        filled from the end of the '/M' option.
**        Ex: Copy ("FROM/A/M,TO/A").  If you try COPY apa groda disk,
**        the first array location will contain a pointer to an array
**        with the strings 'apa' and 'groda'. The second array location
**        will contain a pointer to 'disk'.
**
** INPUTS
**   thetemplate- template describing how to parse.
**   array      - array to be filled.
**   params     - argument string to be parsed.
**
** RESULT
**   ret        - status TRUE is ok.
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_getargstr()
**
******/
int mach_rdargs(char *thetemplate, int32_t *array, int argc, char **argv)
{
    char *rdargs_status;

    rdargs_status = readargs(thetemplate, (ARR_T **)array, argc, argv);
    if (rdargs_status)
	panic(rdargs_status);
    didrdargs=TRUE;
    return(TRUE);
}


/*************************************************************************
**
** mach_closeall
**
******/
void mach_closeall(int ret)
{

#ifdef WIN32_VERSION
    SetConsoleCtrlHandler(&breakhandler, FALSE);
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    signal(SIGINT, SIG_DFL);
#endif /*  LINUX_VERSION */
    if (didrdargs)
	endreadargs();
}

/*************************************************************************
**
** Handle break!
**
******/
BOOL breakhandler(DWORD type)
{
#ifdef WIN32_VERSION
    /* Win32's console output is not latin-1 */
    puts("***Br„„k!");
#else
    puts("***Brääk!");
#endif

    closeall(0);
    return TRUE;
}

/*************************************************************************
**
** NAME  mach_getargstr()
**
** SYNOPSIS
**   args=mach_getargstr()
**   char *mach_getargstr(void)
**
** DESCRIPTION
**   Returns a pointer to a string containing the arguments, excluding
**   the command itself.
**
** INPUTS
**   none
**
** RESULT
**   args       - pointer to a command line. 
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_rdargs()
**
******/
char *mach_getargstr(void)
{
    /* Now obsolete */
    return NULL;
}


/*************************************************************************
**
** NAME  mach_parsepattern()
**
** SYNOPSIS
**   mms=mach_parsepattern(patternstr)
**   struct mach_matchstruct *mach_parsepattern(char *)
**
** DESCRIPTION
**   Allocates and parses an pattern for use with mach_matchpattern()
**   later on.  Remember to free using mach_unparsepattern().
**
**   On the Amiga these patterns apply:
**
**----cut from the AmigaDOS dos.library autodocs--------------------------
**
**   ?       Matches a single character
**   #       Matches the following expression 0 or more times
**   (ab|cd) Matches any one of the items separated by '|'-
**   ~       Negates the following expression.  It matches all strings
**           that do not match the expression (i.e ~(foo) matches all
**           strings that are not exactly "foo").
**   [abc]   Character class: matches any of the characters in the class.
**   a-z     Character range (only within character classes).
**   %       Matches 0 characters always (useful in "(foo|bar|%)").
**   *       Synonym for "#?", not available by default. Available as an
**           option that can be turned on.
**
**------------------------------------------------------------------------
**
**   Under WIN32 these patterns apply:
**
**----cut from DJGPP's libc.inf-------------------------------------------
**
**   *       Matches zero of more characters.
**   ?       Matches exactly one character
**   [...]   Matches one character if it's in a range of characters.  If the
**           first character is `!', matches if the character is not in the
**           range.  Between the brackets, the range is specified by listing
**           the characters that are in the range, or two characters separated
**           by `-' to indicate all characters in that range.  For example,
**           `[a-d]' matches `a', `b', `c', or `d'.
**
**------------------------------------------------------------------------

** INPUTS
**   patternstr - the actual pattern to use for matching
**
** RESULT
**   mms        - pointer to a mach_matchstruct
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_unparsepattern(), mach_matchpattern()
**
******/
struct mach_matchstruct *mach_parsepattern(char *patternstr)
{
    struct mach_matchstruct *mms=NULL;

    mms=(struct mach_matchstruct *)jalloc(sizeof(struct mach_matchstruct));
    if (!mms)
	panic("no mem");

    mms->patternstr=(char *)jalloc((strlen(patternstr)+1)*sizeof(char));
    if (!mms->patternstr)
	panic("no mem");
    strcpy(mms->patternstr, patternstr);

    /*
       Check if the pattern includes wildcard characters.
       This may incorrectly indicate a non-wildcard pattern as being wild.
       This may cause a problem since copymatch() does not allow
       wildcards in the destination
    */
    if (strpbrk(patternstr, "?*[]"))
	mms->iswild=TRUE;
    else
	mms->iswild=FALSE;

    return(mms);
}

/*************************************************************************
**
** NAME  mach_unparsepattern()
**
** SYNOPSIS
**   mach_unparsepattern(mms)
**   void mach_unparsepattern(struct mach_matchstruct *)
**
** DESCRIPTION
**   frees up resources after using a mach_matchstruct (must be
**   previously allocated by mach_parsepattern())
**
** INPUTS
**   mms        - pointer to a mach_matchstruct
**
** RESULT
**   none
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_parsepattern(), mach_matchpattern()
**
******/
void mach_unparsepattern(struct mach_matchstruct *mms)
{
    if(mms) {
	if (mms->patternstr)
	    jfree(mms->patternstr);
	jfree(mms);
    }
}


/*************************************************************************
**
** NAME  mach_matchpattern()
**
** SYNOPSIS
**   ret=mach_matchpattern(mms,str)
**   int mach_matchpattern(struct mach_matchstruct *mms, char *str)
**
** DESCRIPTION
**   match a pattern with a string, and return TRUE if it matches.
**   This function is not case sensitive!
**   Pattern must have been allocated using mach_parsepattern().
**
** INPUTS
**   mms        - pointer to a mach_matchstruct
**   str        - string to match.
**
** RESULT
**   ret        - TRUE if it's a match.  FALSE otherwise.
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_parsepattern(), mach_unparsepattern()
**
******/
int mach_matchpattern(struct mach_matchstruct *mms, char *str)
{
    int ret;

#ifdef WIN32_VERSION
    ret=fnmatch(mms->patternstr, str, FNM_PATHNAME|FNM_CASEFOLD|FNM_NOESCAPE);
#else
    ret=fnmatch(mms->patternstr, str, FNM_PATHNAME|FNM_NOESCAPE);
#endif /* WIN32_VERSION */

    return(ret!=FNM_NOMATCH ? TRUE : FALSE);
}




/*************************************************************************
**
** NAME  mach_lockdir()
**
** SYNOPSIS
**   mdl=mach_lockdir(path)
**   struct mach_dirlock *mach_lockdir(char *)
**
** DESCRIPTION
**   Allocates a mach_dirlock for use with mach_examine(), remember to
**   free using mach_unlock().
**
** INPUTS
**   path       - path to be examined. "" means the current directory
**
** RESULT
**   mdl        - a pointer to a mach_dirlock 
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_unlockdir(), mach_examine()
**
******/
struct mach_dirlock *mach_lockdir(char *path)
{
    struct mach_dirlock *mdl=NULL;

    if (!(mdl=(struct mach_dirlock *)jalloc(sizeof(struct mach_dirlock))))
	panic("no mem");

    if (!(mdl->path=(char *)jalloc(sizeof(char)*(strlen(path)+2))))
	panic("no mem");

#ifdef WIN32_VERSION

    sprintf(mdl->path, "%s*", path);
    mdl->handle=NULL;

#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION

    /* Workaround. I don't think passing "" to this function is fair :) */
    if (path == NULL || path[0] == '\0') {
      sprintf(mdl->path, ".");
    } else {
      sprintf(mdl->path, "%s", path);
    }

#ifdef PRINTF_DEBUG
      printf("mach_dirlock-> mdl->path = %s\n", mdl->path);
#endif

    if ((mdl->dir = opendir(mdl->path)) == NULL)
	panic("no mem or directory not found");
#endif /* LINUX_VERSION */

    return(mdl);
}


/*************************************************************************
**
** NAME  mach_unlockdir()
**
** SYNOPSIS
**   mach_unlockdir(mdl)
**   void mach_unlockdir(struct mach_dirlock *)
**
** DESCRIPTION
**   frees up resources after using a mach_dirlock (must be previously
**   allocated by mach_lockdir())
**
** INPUTS
**   mdl        - a pointer to a mach_dirlock obtained by mach_lockdir()
**
** RESULT
**   none
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_lockdir(), mach_examine()
**
******/
void mach_unlockdir(struct mach_dirlock *mdl)
{

#ifdef WIN32_VERSION
    FindClose(mdl->handle);
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    closedir(mdl->dir);
#endif /* LINUX_VERSION */
    if (mdl)
	jfree(mdl->path);

    jfree(mdl);
}

/*************************************************************************
**
** NAME  mach_examine()
**
** SYNOPSIS
**   mde=mach_examine(mdl)
**   struct mach_direntry *mach_examine(struct mach_dirlock *)
**
** DESCRIPTION
**   examines the next entry of the directory locked by mach_lockdir()
**   if no more entries are found a NULL pointer is returned.
**
** INPUTS
**   mdl        - a pointer to a mach_dirlock obtained by mach_lockdir()
**
** RESULT
**   mde        - a pointer to a mach_direntry, or NULL
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_lockdir(), mach_unlockdir()
**
******/
struct mach_direntry *mach_examine(struct mach_dirlock *mdl)
{

#ifdef WIN32_VERSION
    int res;
    DWORD lasterror = 0;

    if (!mdl->handle) {
	mdl->handle=FindFirstFile(mdl->path, &mdl->wfd);
	res=(mdl->handle==INVALID_HANDLE_VALUE ? 0 : 1);
	if (!res)
	    lasterror=GetLastError();
    } else {
	res=FindNextFile(mdl->handle, &mdl->wfd);
    }
    if (res) {
	mdl->direntry.size=mdl->wfd.nFileSizeLow;
	mdl->direntry.sizeH=mdl->wfd.nFileSizeHigh;
	mdl->direntry.name=(mdl->wfd.cFileName);
	mdl->direntry.wintype=mdl->wfd.dwFileAttributes;
	mdl->direntry.type=
	  (mdl->direntry.wintype&FILE_ATTRIBUTE_DIRECTORY)?1:-1;
	return(&mdl->direntry);
    }
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION

    if ((mdl->dir_ent = readdir(mdl->dir)) != NULL) {
      mdl->direntry.name = mdl->dir_ent->d_name;

      stat(mdl->dir_ent->d_name, &mdl->direntry.attribs);
      mdl->direntry.size = mdl->direntry.attribs.st_size;

#ifdef PRINTF_DEBUG
      printf("mach_examine-> name = %s  size = %u\n",
	     mdl->dir_ent->d_name, mdl->direntry.size);
#endif

      if (S_ISREG(mdl->direntry.attribs.st_mode)) {
	mdl->direntry.type = FILE_ATTRIBUTE_NORMAL;
#ifdef PRINTF_DEBUG
      printf("mach_examine-> REGULAR_FILE\n");
#endif
      } else if (S_ISDIR(mdl->direntry.attribs.st_mode)) {
	mdl->direntry.type = FILE_ATTRIBUTE_DIRECTORY;
#ifdef PRINTF_DEBUG
      printf("mach_examine-> DIRECTORY\n");
#endif
      }
      return(&mdl->direntry);
    }

#endif /* LINUX_VERSION */

    return(NULL);
}

/*************************************************************************
**
** NAME  mach_isdir()
**
** SYNOPSIS
**   ret=mach_isdir(mde)
**   int mach_isdir(struct mach_direntry *)
**
** DESCRIPTION
**   returns true if the direntry (obtained from mach_examine() )
**   is a directory
**
** INPUTS
**   mde        - a pointer to a mach_direntry
**
** RESULT
**   ret        - TRUE if the entry is a directory, FALSE otherwise
**
** BUGS
**   I really don't know what's in  the Amiga mde->type field.
**
** SEE ALSO
**   mach_examine()
**
******/
int mach_isdir(struct mach_direntry *mde)
{
#ifdef LINUX_VERSION
  struct stat file_attributes;
#endif /* LINUX_VERSION */

  if (mde !=NULL) {
#ifdef WIN32_VERSION
	if (mde->wintype & FILE_ATTRIBUTE_DIRECTORY) {
	    //printf ("\t%s is dir\n", mde->name);
	    return TRUE;
	}
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION

#ifdef PRINTF_DEBUG
	  printf("File %s is type %d\n", mde->name, mde->type);
#endif

	if (mde->type == FILE_ATTRIBUTE_DIRECTORY) {
	  return TRUE;
	}

#endif /* LINUX_VERSION */
  }
  /* printf ("\t%s is not dir\n", mde->name); */
  return FALSE;
}


/*************************************************************************
**
** NAME  mach_getpath()
**
** SYNOPSIS
**   filename=mach_getpath(fileref,path,maxsize)
**   char *mach_getpath(char *, char *, int)
**
** DESCRIPTION
**   copies the pathpart of fileref to path, and returns a pointer to
**   the filename.
**
** INPUTS
**   fileref    - the complete path & filename to be splitted
**   path       - where the path is copied
**   maxsize    - total max size of the path buffer (including '\0')
**
** RESULT
**   filename   - pointer to where the filename starts in the
**                original string.
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_addpart()
**
******/
char *mach_getpath(char *fileref, char *path, int maxsize)
{
    char *name;
    int len;
    char tkn;
    int i;

    len=strlen(fileref);

    if (len==0)
	return(NULL);

    for (i=len-1; i>=0; i--) {
	tkn=fileref[i];
	if (tkn=='/' || tkn==':')
	    break;
	if (tkn=='\\')
	    break;
    }

    if (i>0) {
	if (i>=maxsize)
	    panic("string to big in mach_getpath (%d)",i);

	name=&fileref[i+1];
	strncpy(path,fileref,i+1);
	path[i+1]=0;
	return(name);
    } else {
	name=&fileref[0];
	path[0]=0;
	return(name);
    }
}


/*************************************************************************
**
** NAME  mach_addpart()
**
** SYNOPSIS
**   mach_addpart(path,name,size)
**   void mach_addpart(char *, char *, int)
**
** DESCRIPTION
**   Appends the name to the path string, if nessecary inserts a '/'.
**
** INPUTS
**   path       - path string on which name is to be appended
**   name       - name string which is to be appended.
**   size       - total max size of the path buffer (including '\0')
**
** RESULT
**   none
**
** BUGS
**   none known
**
** SEE ALSO
**   mach_getpath()
**
******/
void mach_addpart(char *path, char *name, int size)
{
    char  tkn;

/*
** If string is not empty and ends with a
** character other that '/' or ':', append a '/'.
** 
*/
    if (strlen(path)) {
	tkn=path[strlen(path)-1];

	if (!(tkn=='/' || tkn==':' || tkn=='\\'))
	    strncat(path,"/",size);
    }

/*
** append name to path
*/
    strncat(path,name,size);
    return;
}


/*************************************************************************
**
** NAME  mach_getconfigfile()
**
** SYNOPSIS
**   filename=mach_getconfigfile(buffer, size)
**   char *mach_getconfigfile(char *, int)
**
** DESCRIPTION
**   Copies the path and filename of the configuration file to
**   buffer and returns a pointer to buffer.
**
** INPUTS
**   buffer     - address of buffer which receives the path and filename
**   size       - total max size of the path buffer (including '\0')
**
** RESULT
**   filename   - pointer to buffer
**
** BUGS
**   none known
**
** SEE ALSO
**
******/
char *mach_getconfigfile(char *buffer, int size)
{

#ifdef AMIGA_VERSION
    strncpy(buffer, "PROGDIR:Over5.config", size);
#endif /* AMIGA_VERSION */

#ifdef WIN32_VERSION
    if (!SearchPath(NULL, "OVER5.CFG", NULL, size, buffer, NULL))
	return NULL;
#endif /* WIN32_VERSION */

#ifdef LINUX_VERSION

    char *temp_ptr;

    if ((temp_ptr = getenv("HOME")) != NULL) {
      strncpy(buffer, temp_ptr, size);
      mach_addpart(buffer, CFG_FILE, size);
      if (access(buffer, R_OK) == 0) {
	/* OK, the file's probably there and is readable */
	return buffer;
      }
    }
    if (FALSE) {
      /* Do some spiffy thing to find out where the executable is */
      /* located and look for the config file there */

      if (access(buffer, R_OK) == 0) {
	/* OK, the file's probably there and is readable */
	return buffer;
      }
    }

    /* Since nothing else seems to work, just try CFG_FILE in the */
    /* current dir instead */
    strncpy(buffer, CFG_FILE, size);
    if (access(buffer, R_OK) != 0) {
      /* Oh crap, the file's not there or not readable */
      return NULL;
    }

#endif /* LINUX_VERSION */

    return buffer;
}


/*
** Table for the config reader!
*/
struct ConfigTable configtable[]={
    {"DEVICE",       CT_NUMBER, (u_int32_t *)&o5config.device},
#ifdef AMIGA_VERSION
    {"SERIALDEVICE", CT_STRING, (u_int32_t *)&o5config.serdevice},
    {"SERIALUNIT",   CT_NUMBER, (u_int32_t *)&o5config.serunitnum},
#endif /* AMIGA_VERSION */
#ifdef WIN32_VERSION
    {"SERIALDEVICE", CT_STRING, (u_int32_t *)&o5config.serdevice},
#endif /* WIN32_VERSION */
#ifdef LINUX_VERSION
    {"SERIALDEVICE", CT_STRING, (u_int32_t *)&o5config.serdevice},
#endif /* LINUX_VERSION */
    {NULL,           0,         0}
};


