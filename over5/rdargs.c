/*
  rdargs.c

  Command-line parser similar to Amiga ReadArgs() function,
  but takes argc and argv instead of a character string.

  TODO:
  - cleanup the code
  - make better checks for /A, /K and /S
  - make options with required keywords position-independent,
    so if you give the template "START/N/K,END/N/K" you should get
    the same results from "START=17 END=42" and "END=42 START=17".
    This will make you able to implement unix-style options
    with "-s/N/K,-e/N/K"
*/

#include "config.h"

#include <ctype.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "convert.h"

#include "rdargs.h"

/*
** Constants that mark the different types of options
*/
#define TPL_STRING    (1<<0)		/* default */
#define TPL_SWITCH    (1<<1)		/* S */
#define TPL_TOGGLE    (1<<2)		/* T */
#define TPL_NUMBER    (1<<3)		/* N */
#define TPL_MULTIPLE  (1<<4)		/* M */
#define TPL_REST      (1<<5)		/* F */
#define TPL_KEYWORD   (1<<6)		/* K */
#define TPL_REQUIRED  (1<<7)		/* A */
#define TPL_OPTION    (TPL_STRING | TPL_SWITCH | TPL_TOGGLE \
                       | TPL_NUMBER | TPL_MULTIPLE | TPL_REST)

/*
** Variables that will be allocated with malloc
** (Stored here so they can be freed with endreadargs)
*/
char *tscopy = NULL;			/* scratchpad copy of tplstr */
char **multarr = NULL;

/* Debugging function */
int print_ptpl(int *type, char **name, char **abbr, int nopt)
{
    int n;
    for (n=0; n<nopt; n++)
        printf("%d: %02X, %s, %s\n", n, type[n], abbr[n], name[n]);
    printf("\n");
    
    return 0;
}

/* Debugging function */
int printarray (ARR_T **argarr, int *type, int nopt)
{
    int n, i;
    for(n=0; n<nopt; n++)
    {
	if(type[n] & (TPL_STRING | TPL_REST))
	    printf("%d: %s\n", n, (char *) argarr[n]);
	if(type[n] & (TPL_SWITCH | TPL_TOGGLE))
	    printf("%d: %s\n", n, (char *) (argarr[n]?"True":"False"));
	if(type[n] & TPL_NUMBER)
	    printf("%d: %ld\n", n,
		   (type[n]&TPL_REQUIRED
		    ?(long) argarr[n]
		    :(long) (argarr[n]? *argarr[n] : -4711)));
	if(type[n] & TPL_MULTIPLE) {
	    if (argarr[n]) {
		for(i=0; argarr[n][i]; i++)
		    printf("%d.%d: %s\t%p\n", n, i, (char *) argarr[n][i],
			   (char *) argarr[n][i]);
	    }
	    else
		printf("0: (null)\n");
	}
		
    }
    return 0;
}

int parseflag(char c)
{
    switch(toupper(c)) {
    case 'A':
	return TPL_REQUIRED;
    case 'F':
	return TPL_REST;
    case 'K':
	return TPL_KEYWORD;
    case 'M':
	return TPL_MULTIPLE;
    case 'N':
	return TPL_NUMBER;
    case 'S':
	return (TPL_SWITCH | TPL_KEYWORD);
    case 'T':
	return (TPL_TOGGLE | TPL_KEYWORD);
    default:
	break;
    }
    return -1;
}

#define ERROR(s) {errstr=(s); goto end;}

/*
** Returns NULL on success, an error string on failure.
*/
char *readargs(char *tplstr, ARR_T **argarr, int argc, char **argv)
{
    char *errstr=NULL;
    char *ts;
    int nopt;
    int n;
    int a;
    int t;
    int num;
    int multnum;
    int m0;
    int mt;         /* the number of the option that is multiple (if any) */
    char **name = NULL;
    char **abbr = NULL;
    int *type = NULL;
    int *uarg = NULL;           /* array that marks which argv's are used */
  

    /* Check that the tplstr isn't empty */
    if (!tplstr || !*tplstr)
	ERROR("no template");

    /* Give user help if he wants to (kludge) */
    if (argc == 1 && !strcmp(argv[0], "?"))
	return (tplstr);	/* return template string for Over5 to print */


    /* Count the entries in tplstr */
    nopt=1;
    for (ts = tplstr; *ts; ts++)
        if (*ts == ',')
           nopt++;

    name = (char **) malloc(nopt*sizeof(char *));
    abbr = (char **) malloc(nopt*sizeof(char *));
    type = (int *) malloc(nopt*sizeof(int));
    uarg = (int *) malloc(argc*sizeof(int));
    if (!name || !abbr || !type || !uarg)
	ERROR("out of memory");

    /* Go through tplstr and fill in tpl */
    tscopy = strdup(tplstr);
    if (!tscopy) ERROR("out of memory");
    ts = tscopy;
    for (n=0; n<nopt; n++) {
        type[n] = 0;
        abbr[n] = ts;
        name[n] = ts;

        while (*ts != '/' && *ts != ',' && *ts != '\0') {
            if (*ts == '=') {
                *ts = '\0';
                name[n] = ++ts;
            }
            ts++;
        }

        while (*ts=='/') {
            *ts++ = '\0';

	    if((num=parseflag(*ts)) == -1)
		ERROR("illegal char");

	    type[n] |= num;
	    
            ts++;
        }
        if (*ts == ',')
            *ts++ = '\0';
        else if (!*ts)
            break;

        /* Make sure type is set to TPL_STRING as default */
        if(!(type[n] & TPL_OPTION))
            type[n] |= TPL_STRING;
    }

/* Debugging output */
/*
    print_ptpl(type, name, abbr, nopt);
*/

    /*
      If there are no arguments but the template has flagged some as
       required, report an error. Otherwise, just return.
    */
    if (argc == 0)
    {
	for (n=0; n<nopt; n++)
	    if (type[n] & TPL_REQUIRED)
		ERROR("missing argument");
        return NULL;
    }
        
    for (a=0; a<argc; a++)
        uarg[a] = -1;


    /*
      First parse through argv from left. If the current argv
      does not match the current template entry, go to next
      template entry. At this stage a /M template entry will
      eat every argv it sees. If there are arguments that were
      supposed to belong to other template entries, these are
      matched to the correct entry at the next stage.
    */
    t=0;
    for(a=0; a<argc; a++)
    {
	for(n=t; n<nopt; n++)
	{
	    /* /M matches everything */
	    if (type[n] & TPL_MULTIPLE)
	    {
		uarg[a]=n;
		t=n;           /* Retry */
		break;
	    }	      
	    
            /* /F matches everything */
	    if (type[n] & TPL_REST)
	    {
		uarg[a]=n;
		t=n;           /* Retry */
		break;
	    }
	    
	    if (type[n] & TPL_NUMBER)
	    {
#ifndef LINUX_VERSION
		if (!strnicmp(name[n], argv[a], strlen(name[n]))
		    || !strnicmp(abbr[n], argv[a], strlen(abbr[n])))
#else
		if (!strncasecmp(name[n], argv[a], strlen(name[n]))
		    || !strncasecmp(abbr[n], argv[a], strlen(abbr[n])))
#endif /* ! LINUX_VERSION */
		{
		    uarg[a]=n;
		    t=n;      /* Retry */
		    break;
		}	      
		else if ((num=makenum(argv[a], 0, LONG_MAX, 10)) != -1)
		{
		    /*
		      If the number is required, it is placed directly
		       into the array. Otherwise, a pointer to a allocated
		       number is placed in the array. 
		    */
		    if (type[n] & TPL_REQUIRED)
			argarr[n] = (ARR_T *) num;
		    else {
			argarr[n] = (ARR_T *) malloc(sizeof(long));
			if (!argarr[n])
			    fprintf (stderr, "Out of memory");
			*argarr[n] = (ARR_T) num;
		    }
		    uarg[a]=n;
		    t=n+1;    /* Go to next option */
		    break;
		}	      
		else
		    continue;
	    }
	    
            /* should use stricmp? */
	    if (type[n] & (TPL_SWITCH | TPL_TOGGLE))
	    {
#ifndef LINUX_VERSION
		if (!strnicmp(name[n], argv[a], strlen(name[n]))
		    || !strnicmp(abbr[n], argv[a], strlen(abbr[n])))
#else
		if (!strncasecmp(name[n], argv[a], strlen(name[n]))
		    || !strncasecmp(abbr[n], argv[a], strlen(abbr[n])))
#endif /* ! LINUX_VERSION */
		{
		    if (type[n] & TPL_SWITCH)
			argarr[n] = (ARR_T *) 1;
		    else
			argarr[n] = (ARR_T *) !argarr[n];		    
		    uarg[a]=n;
		    t=n+1;
		    break;
		}	      
		else
		    continue;
	    }

	    /* string matches everything */
	    argarr[n] = (ARR_T *) argv[a];
	    uarg[a]=n;
	    if (type[n] & TPL_REQUIRED)
	    {
		t=n+1;             /* Go to next option */
		break;
	    }
//	    else
//		if (t+1 < nopt && (type[n+1] & TPL_STRING
//				   && !(type[n+1] & TPL_REQUIRED)))
//		{		
//		    /* Next argument is also a non-required string, so
//		       there is no point retrying */
//		    t=n+1;
//		    break;
//		}
	    t=n+1;
	}

	if (n>nopt) {
	    /* printf("Argument %d didn't match\n", a); */
	    break;
	}

    }
    
    /* Do some error checking */
//    if (a != argc)
//	printf("Unmatched arguments left from argument %d\n", a);

    /*
      See if any argument was matched as a string and then grabbed
      by a later argument and in that case, null out the string
    */
    for (n=0; n<nopt; n++)
	if (type[n] & TPL_STRING && !(type[n] & TPL_REQUIRED))
	{
	    for (a=0; a<argc; a++)
		if (uarg[a] == n)
		    break;
	    if (a==argc)
		argarr[n] = NULL;
	}
    
    /*
      If there are /M options, the last argv always belongs to that option
    */
    mt = (type[uarg[argc-1]] & TPL_MULTIPLE) ? uarg[argc-1] : nopt;

    /*
      Now parse through the arguments from right and steal arguments
      that do not belong to the /M entry.
    */
    t=nopt-1;
    for (a=argc-1; a>=0; a--)
    {
	
	/* check if we have reached the /M option */
	if(uarg[a] < mt)
	    break;

	for (n=t; n>=0; n--)
	{
            /* printf ("%X %s=%s\n", type[n], abbr[n], name[n]); */
	    if (type[n] & TPL_MULTIPLE)
		break;                  /* We're done now */

	    if (type[n] & TPL_REST)
	    {
		/*argarr[n] = (ARR_T *) argv[a];*/
		uarg[a]=n;
		t=n;
	    }
	    /*break;*/
	    
	    if (type[n] & TPL_NUMBER)
	    {
#ifndef LINUX_VERSION
		if (!strnicmp(name[n], argv[a], strlen(name[n])) 
		    || !strnicmp(name[n], argv[a], strlen(abbr[n])))
#else
		if (!strncasecmp(name[n], argv[a], strlen(name[n])) 
		    || !strncasecmp(name[n], argv[a], strlen(abbr[n])))
#endif /* ! LINUX_VERSION */
		{
		    uarg[a]=n;
		    t=n-1;
		    break;
		}
		if ((num=makenum(argv[a], 0, LONG_MAX, 10)) != -1)
		{
		    if (type[n] & TPL_REQUIRED)
			argarr[n] = (ARR_T *) num;
		    else {
			argarr[n] = (ARR_T *) malloc(sizeof(long));
			if (!argarr[n])
			    ERROR("out of memory");
			*argarr[n] = (ARR_T) num;
		    }
		    uarg[a]=n;
		    /* 
		       This checks if the argument to the left
		       is NAME or ABBR and grabs it in that case,
		       otherwise it is left to the entry to the left.
		       Requires a perfect keyword match, so it uses
		       stricmp()
		    */
		    if (a>0 
			&& (uarg[a-1] == mt)
#ifndef LINUX_VERSION
			&& (!stricmp(name[n], argv[a]) 
			    || !stricmp(name[n], argv[a])))
#else
			&& (!strcasecmp(name[n], argv[a]) 
			    || !strcasecmp(name[n], argv[a])))
#endif /* ! LINUX_VERSION */
		    {
			uarg[a-1]=n;
			a--;
		    }		    
		    t=n-1;
		    break;
		}
	    }

	    if (type[n] & (TPL_SWITCH | TPL_TOGGLE))
	    {
#ifndef LINUX_VERSION
		if (!strnicmp(name[n], argv[a], strlen(name[n])) 
		    || !strnicmp(name[n], argv[a], strlen(abbr[n])))
#else
		if (!strncasecmp(name[n], argv[a], strlen(name[n])) 
		    || !strncasecmp(name[n], argv[a], strlen(abbr[n])))
#endif /* ! LINUX_VERSION */
		{
		    if (type[n] & TPL_SWITCH)
			argarr[n] = (ARR_T *) 1;
		    else
			argarr[n] = (ARR_T *) !argarr[n];
		    uarg[a]=n;
		    t=n-1;
		    break;
		}
	    }
	    
	    /* string */
	    if (type[n] & TPL_STRING)
	    {
		argarr[n] = (ARR_T *) argv[a];
		uarg[a]=n;
		t=n-1;
		break;
	    }
	}
    }

    /*
      Now it's time to fill in the /M arguments.
    */

    /* Count the number of /M arguments and remember which was first */
    multnum = 0;
    m0 = -17;
    for (a=0;a<argc;a++)
	if (type[uarg[a]] & TPL_MULTIPLE) {
	    multnum++;
	    if (m0 == -17)
		m0=a;
	}

    /* Make a list of the /M arguments and put it in the array */
    if(multnum) {
	multarr = (char **) malloc((multnum+1)*sizeof(char *));
	if (!multarr)
	    ERROR("out of memory");
	
	for (a=0; a < multnum; a++)
	    multarr[a]=argv[a+m0];
	multarr[multnum]=NULL;
	argarr[mt] = (ARR_T *) multarr;
    }

/* Debugging output */
/*   
    printarray(argarr, type, nopt);
*/

    /* Stupid check if some /A entries were missing */
    for (n=0; n<nopt; n++) {
	if (type[n] & TPL_REQUIRED) {
	    for (a=0; a<argc; a++) {
		if (uarg[a]==n)
		    break;
	    }
	    if (a>=argc) {
		/* None of uarg[] equalled n */
		ERROR("missing argument");
	    }
	}
    }


    /* This is where ERROR jumps */
  end:
    if(name) free(name);
    if(abbr) free(abbr);
    if(type) free(type);
    if(uarg) free(uarg);

    return errstr;
}


/*
** Frees memory that has been allocated during the parsing
*/
int endreadargs(void)
{
    if(tscopy) free(tscopy);
    if(multarr) free(multarr);
    return 0;
}

/* eof */


