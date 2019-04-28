;**************************************************************************
;**
;** dsk_Disk.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;** 
;**
;** TABLE OF CONTENTS
;**
;** diskkit/dsk_setmodeflags
;** diskkit/dsk_setstart
;** diskkit/dsk_setstartend
;** diskkit/dsk_setname
;** diskkit/dsk_writefile
;** diskkit/dsk_readfile
;** diskkit/dsk_getstatus
;** diskkit/dsk_diskcommand
;** diskkit/dsk_showdirectory
;** diskkit/dsk_writetracks
;** diskkit/dsk_readtracks
;** diskkit/dsk_sizetracks
;**
;******

	INCLUDE	dsk_mem.i

DMODE_TURBO	EQU	%00000001
DMODE_VERIFY	EQU	%00000010
DMODE_NOCOLOR	EQU	%00000100


;**************************************************************************
;**
;** NAME  dsk_setmodeflags
;**
;** DESCRIPTION
;**   sets the modeflags for the following diskkit operations.
;**
;** INPUTS
;**   A   - diskkit mode flags
;**
;** RESULT
;**   none
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   none
;**
;******
dsk_setmodeflags:
	sta	d_modeflags
	rts


;**************************************************************************
;**
;** NAME  dsk_setstart
;**
;** DESCRIPTION
;**   sets the start address for the following diskkit operations.
;**
;** INPUTS
;**   X/Y - start address
;**
;** RESULT
;**   none
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   dsk_setstartend
;**
;******
dsk_setstart:
	stx	d_currzp
	sty	d_currzp+1
	rts



;**************************************************************************
;**
;** NAME  dsk_setstartend
;**
;** DESCRIPTION
;**   sets the start and end for the following diskkit operations.
;**
;** INPUTS
;**   A   - pointer to zeropage location containing the start address
;**   X/Y - end address
;**
;** RESULT
;**   none
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   dsk_setstart
;**
;******
dsk_setstartend:
	stx	d_endzp
	sty	d_endzp+1
	tay
	lda	$00,y
	sta	d_currzp
	lda	$01,y
	sta	d_currzp+1
	rts


;**************************************************************************
;**
;** NAME  dsk_setname
;**
;** DESCRIPTION
;**   Set the name for the following disk operation
;**   Equivalent to SETNAM ($ffbd)
;**
;** INPUTS
;**   X/Y points to a null terminated string
;**
;** RESULT
;**   none
;**
;** BUGS
;**   If name is greater than 256 bytes, length will be set to 0
;**
;** SEE ALSO
;**   SETNAM, dsk_setstart, dsk_setstartend
;**
;******
dsk_setname:
mySetNam:
	jsr	dsk_setstart
	ldy	#0
msn_lp1:
	lda	(d_currzp),y
	beq	msn_skp1
	iny
	bne	msn_lp1
msn_skp1:
	tya
	ldx	d_currzp
	ldy	d_currzp+1
	jsr	$ffbd	;SETNAM
	rts




;**************************************************************************
;**
;** NAME  dsk_writefile
;**
;** DESCRIPTION
;**   writes a file starting at start address to end address minus one.
;**   The name and device number must have been set up before calling
;**   this function.
;**
;** INPUTS
;**   A   - pointer to zeropage location containing the start address
;**   X/Y - end address
;**
;** RESULT
;**   CARRY=0 OK, CARRY=1 fail!
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setname
;** 
;******
dsk_writefile:
	jsr	dsk_setstartend
WriteFile:
	lda	#1
	ldx	$ba
	ldy	#1
	jsr	$ffba	;SETLFS

	lda	d_modeflags
	and	#DMODE_TURBO
	beq	wf_noturbo

;*
;* TURBO mode
;*
	jmp	WriteFileFast

;*
;* NORMAL mode
;*
wf_noturbo:
	jmp	WriteFileNormal



;**************************************************************************
;**
;** NAME  dsk_readfile
;**
;** DESCRIPTION
;**   reads a file to address start address. 
;**   The name and device number must have been set up before calling
;**   this function.
;**
;** INPUTS
;**   X/Y - start address
;**
;** RESULT
;**   X/Y - end address
;**   CARRY=0 OK, CARRY=1 fail!
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setname
;** 
;******
dsk_readfile:
	jsr	dsk_setstart
ReadFile:

	lda	#1
	ldx	$ba
	ldy	#0
	jsr	$ffba	;SETLFS

	lda	d_modeflags
	and	#DMODE_TURBO
	beq	rf_noturbo

;*
;* TURBO mode,
;* skip to normal if we are about to read the directory.
;*
	ldy	#0
	lda	($bb),y
	cmp	#"$"
	beq	rf_noturbo

	jsr	ReadFileFast
	jmp	rf_ex1

;*
;* NORMAL mode
;*
rf_noturbo:
	jsr	ReadFileNormal

;*
;* exit
;*
rf_ex1:
	ldx	d_endzp
	ldy	d_endzp+1
	rts


;**************************************************************************
;**
;** NAME  dsk_getstatus
;**
;** DESCRIPTION
;**   gets status from drive.  
;**   The device number must have been set up before calling this function.
;**
;** INPUTS
;**   X/Y - start pointer
;**
;** RESULT
;**   Y   - length of status message
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setname
;**
;******
dsk_getstatus:
	jsr	dsk_setstart
	jsr	GetStatusNormal
	rts



;**************************************************************************
;**
;** NAME  dsk_diskcommand
;**
;** DESCRIPTION
;**   sends a diskcommand.
;**   The device number must have been set up before calling this function.
;**
;** INPUTS
;**   X/Y - start pointer
;**
;** RESULT
;**   none
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   none
;**
;******
dsk_diskcommand:
DiskCommand:
	jsr	dsk_setname
dsk_diskcommand2:
DiskCommand2:
	IFNCONST NOCOLOR
	jsr	dsk_commandcolor
	ENDIF

;* turbo ? *
	lda	d_modeflags
	and	#DMODE_TURBO
	beq	dc2_noturbo

;* null filename *
	lda	$b7
	beq	dc2_noturbo

;* format ? *
	ldy	#0
	lda	($bb),y
	cmp	#"N"
	bne	dc2_noturbo

;* if ',' do FastFormat *
	ldy	$b7
	dey
dc2_lp1:
	lda	($bb),y
	cmp	#","
	beq	dc2_turbo
	dey
	bpl	dc2_lp1

;* do normal command *
dc2_noturbo:
	jsr	DiskCommandNormal
	rts

dc2_turbo:
	jmp	TurboFormat





;**************************************************************************
;**
;** NAME  dsk_showdirectory
;**
;** DESCRIPTION
;**   shows the disk directory on screen.  
;**   The device number must have been set up before calling this function.
;**
;** INPUTS
;**   none
;**
;** RESULT
;**   CARRY=0 OK, CARRY=1 fail!
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setname
;**
;******
dsk_showdirectory:
	jsr	ShowDirectoryNormal
	rts




;**************************************************************************
;**
;** NAME  dsk_writetracks
;**
;** DESCRIPTION
;**   writes X tracks starting at track A from memory to disk. 
;**   The start address and device number must have been set up before
;**   calling this function.
;**
;** INPUTS
;**   A   - start track
;**   X   - number of tracks
;**
;** RESULT
;**   CARRY=0 OK, CARRY=1 fail!
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setstart
;** 
;******
dsk_writetracks:
	stx	d_tempzp
	sta	d_trackzp
	beq	wt_fl1

	IFNCONST NOCOLOR
	jsr	dsk_savecolor
	ENDIF

	lda	d_modeflags
	and	#DMODE_TURBO
	beq	wt_noturbo
	jmp	WriteTrackFast
wt_noturbo:
	jmp	WriteTrackNormal
wt_fl1:
	sec
	rts

;**************************************************************************
;**
;** NAME  dsk_readtracks
;**
;** DESCRIPTION
;**   reads X tracks starting at track A from disk to memory. 
;**   The start address and device number must have been set up before
;**   calling this function.
;**
;** INPUTS
;**   A   - start track
;**   X   - number of tracks
;**
;** RESULT
;**   CARRY=0 OK, CARRY=1 fail!
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setstart
;** 
;******
dsk_readtracks:
	stx	d_tempzp
	sta	d_trackzp
	beq	rtr_fl1

	IFNCONST NOCOLOR
	jsr	dsk_loadcolor
	ENDIF

	lda	d_modeflags
	and	#DMODE_TURBO
	beq	rtr_noturbo
	jmp	ReadTrackFast
rtr_noturbo:
	jmp	ReadTrackNormal
rtr_fl1:
	sec
	rts


;**************************************************************************
;**
;** NAME  dsk_sizetracks
;**
;** DESCRIPTION
;**   calculates the size of X tracks starting at track A, and
;**   returns it in X/Y. 
;**
;** INPUTS
;**   A   - start track
;**   X   - number of tracks
;**
;** RESULT
;**   X/Y - length of data
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   SETLFS, SETNAM, dsk_setstart
;** 
;******
dsk_sizetracks:
	jsr	CalcEnd
	ldx	d_endzp
	ldy	d_endzp+1
	clc
	rts




;**************************************************************************
;**
;** modules
;**
;******
	INCLUDE	dsk_support.asm
        INCLUDE dsk_disknormal.asm
        INCLUDE dsk_diskturbo.asm
        INCLUDE dsk_disksector.asm
