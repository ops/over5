
;**************************************************************************
;**
;** dsk_fdisk.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;** fast format routine (1541 part).
;**
;** FEATURES:
;**  - soft bump (i.e tries not to bump so much)
;**  - real verify (which can be turned off)
;**  - fairly fast, but very safe!
;**  - 24 seconds with verify, 17 seconds without 
;******


FMT_TRACKS	EQU	35
FMT_HDRBUFFER	EQU	$0300
fmt_sectortemp	EQU	$06ff	;$0628
fmt_retries	EQU	$06fe	;$0620
fmt_vfyretries	EQU	$06fd	;$0623

	RORG	$0400	
fdiskstart:

;**************************************************************************
;**
;** main format routine...
;** started by an execute job buffer 1.
;** just to put us running in FDC mode.
;**
;******
formatjob:
	lda	$51	;FTNUM
	bpl	fj_skp1

	lda	#%01100000	;headstep+drivemotor
	sta	$20	;DRVST


;*
;* Determine how many tracks to bump.
;* If we know the current track, just step in all tracks plus ~4 extra.
;* Otherwise (if DRVTRK=0) do normal bump.
;* Always make sure step bits in $1c00 become 00.
;*
	lda	$1c00
	and	#%00000011
	sta	$4a	;STEPS

	lda	$22	;DRVTRK
	bne	fj_skp2
	lda	#44
fj_skp2:
	and	#$7e
	eor	#$fe	;A=-A-2
	asl		;A=A*2
	ora	$4a	;A=TTTTTTSS
	sec
	sbc	#4
	sta	$4a	;STEPS


;*
;* Setup track
;*
	lda	#1
	sta	$22	;DRVTRK
	sta	$51	;FTNUM

	lda	#10
	sta	fmt_retries

;*
;* return to job loop
;*
	jmp	$f99c	;END



fj_skp1:
;*
;* Check if we really are on the right track.
;*
	ldy	#0
	cmp	($32),y		;HDRPNT
	beq	fj_skp3
	sta	($32),y		;HDRPNT
	jmp	$f99c	;END


fj_skp3:
;*
;* Check if write protected.
;*
	lda	$1c00
	and	#%00010000
	bne	fj_skp4
	lda	#$08	;26, 'write protect on'
	jmp	$fddb	;FMTE10


fj_skp4:
;*
;* start wipeing track with $55's
;* this happens automagically once started.
;*
	lda	$1c0c
	and	#$1f
	ora	#$c0
	sta	$1c0c	;set write mode
	lda	#$ff
	sta	$1c03	;port as output
	lda	#$55
	sta	$1c01	;wipe pattern

;*
;* calculate sectorheaders (while still wipeing track)
;*
	ldy	#0
	sty	fmt_sectortemp
fj_lp1:
	lda	$39	;HBID (always $08)
	sta	FMT_HDRBUFFER,y
	iny
	iny
	lda	fmt_sectortemp
	sta	FMT_HDRBUFFER,y
	iny
	lda	$51	;FTNUM
	sta	FMT_HDRBUFFER,y
	iny
	lda	$13	;DSKID+1
	sta	FMT_HDRBUFFER,y
	iny
	lda	$12	;DSKID
	sta	FMT_HDRBUFFER,y
	iny
	lda	#$0f
	sta	FMT_HDRBUFFER,y
	iny
	sta	FMT_HDRBUFFER,y
	iny

;* calculate header checksum
	lda	FMT_HDRBUFFER-6,y	;SECTOR
	eor	FMT_HDRBUFFER-5,y	;TRACK
	eor	FMT_HDRBUFFER-4,y	;ID2
	eor	FMT_HDRBUFFER-3,y	;ID1
	sta	FMT_HDRBUFFER-7,y	;CHKSUM

	inc	fmt_sectortemp
	lda	fmt_sectortemp
	cmp	$43	;SECTR
	bne	fj_lp1

;*
;* GCR code headers (while still wipeing track)
;*
	tya
	pha
	lda	#>FMT_HDRBUFFER
	sta	$31	;BUFPNT+1
	jsr	$fe30	;FBTOG  (always sets BUFPNT to 0)
	pla
	tay
	dey
	jsr	$fde5	;MOVUP
	jsr	$fdf5	;MOVOVR

;*
;* do the actual formatting of a track.
;*

	lda	#0
	sta	$32	;HDRPNT
fj_lp2:
	jsr	writesector
	dec	fmt_sectortemp
	bne	fj_lp2

fj_lp3:
	bvc	fj_lp3
	clv

	jsr	$fe00	;KILL  (go to readmode)

;*
;* Verify the track.
;*
	lda	fmt_vfyflag	;no verify?
	beq	fj_skp6

	lda	#0
	sta	$32	;HDRPNT
	lda	#200
	sta	fmt_vfyretries

	lda	$43	;SECTR
	sta	fmt_sectortemp
fj_lp4:
	jsr	verifysect
	bcc	fj_skp5
	dec	fmt_vfyretries
	bne	fj_lp4
	lda	#$06	;24, 'read error'
	jmp	fj_fl1

fj_skp5:
	dec	fmt_sectortemp
	bne	fj_lp4


fj_skp6:
;*
;* are we done with the disk?
;*
	inc	$51	;FTNUM
	lda	$51	;FTNUM
	cmp	#FMT_TRACKS+1
	beq	fj_ex1		;yes, exit

;*
;* no! go to job loop.
;*
	jmp	$f99c	;END



fj_ex1:
;*
;* format ok!
;*
	lda	#$01
	jmp	fj_ex2


fj_fl1:
;*
;* format failure... decrease retries
;*
	dec	fmt_retries
	bne	fj_ex2
	jmp	$f99c	;END

fj_ex2:
;*
;* set FTNUM to default value.  Set GCRFLAG so that noone will
;* try to convert from GCR to BIN after we have left.
;*
	jmp	$fddb	;FMTE10

;**************************************************************************
;**
;** writesector
;** must be run from FDC mode!
;**
;******
writesector:

;*
;* write leading sync
;*
	jsr	writesync

;*
;* write sector header
;*
	ldy	$32	;HDRPNT
	ldx	#10
wse_lp1:
	bvc	wse_lp1
	clv
	lda	FMT_HDRBUFFER,y
	sta	$1c01
	iny
	dex
	bne	wse_lp1
	sty	$32	;HDRPNT

;*
;* write gap
;*
	lda	#$55
	ldx	#9
wse_lp2:
	bvc	wse_lp2
	clv
	sta	$1c01
	dex
	bne	wse_lp2

;*
;* write sector sync
;*
	jsr	writesync

;*
;* write the actual data block
;*		
	ldy	#4
wse_lp3:
	bvc	wse_lp3
	clv
	lda	emptygcr1,y
	sta	$1c01
	dey
	bpl	wse_lp3

	ldx	#$40
wse_lp4:
	ldy	#4
wse_lp5:
	bvc	wse_lp5
	clv
	lda	emptygcr2,y
	sta	$1c01
	dey
	bpl	wse_lp5
	dex
	bne	wse_lp4

;*
;* write intersector gap
;*
	lda	#$55
	ldx	#8
wse_lp6:
	bvc	wse_lp6
	clv
	sta	$1c01
	dex
	bne	wse_lp6
;*
;* wrote! 
;*
	rts



;**************************************************************************
;**
;** verifysect
;** must be run from FDC mode!
;**
;******
verifysect:
;*
;* find sync. 
;*
	jsr	$f556	;SYNC


;*
;* verify header
;*
	ldx	#10
	ldy	$32	;HDRPNT
vfs_lp1:
	bvc	vfs_lp1
	clv
	lda	$1c01
	cmp	FMT_HDRBUFFER,y
	bne	vfs_fl1
	iny
	dex
	bne	vfs_lp1

	sty	$32	;HDRPNT

;*
;* find sync
;*
	jsr	$f556	;SYNC



;*
;* verify the actual data block
;*
	ldy	#4
vfs_lp2:
	bvc	vfs_lp2
	clv
	lda	$1c01
	cmp	emptygcr1,y
	bne	vfs_fl1
	dey
	bpl	vfs_lp2

	ldx	#$40
vfs_lp3:
	ldy	#4
vfs_lp4:
	bvc	vfs_lp4
	clv
	lda	$1c01
	cmp	emptygcr2,y
	bne	vfs_fl1
	dey
	bpl	vfs_lp4
	dex
	bne	vfs_lp3

	clc
	rts

vfs_fl1:
	sec
	rts

;**************************************************************************
;**
;** writesync
;** writes 5*$ff to the disk.
;** must be run from FDC mode!
;**
;******
writesync:
	ldx	#5
	lda	#$ff
wsy_lp1:
	bvc	wsy_lp1
	clv
	sta	$1c01
	dex
	bne	wsy_lp1
	rts


;**************************************************************************
;**
;** format data
;**
;******

;*
;* written:
;*     1 * emptygcr1
;*   $40 * emptygcr2
;* will result in (when GCR uncoded)
;* $07 followed by 259 $00 bytes.
;*
;* $07 is the data block identifier
;* $00 * 256 is the data bytes
;* $00 is the data block checksum
;* $00 * 2 is the off bytes.
;*
;* the GCR code is stored in reverse byte order
;*
;* emptygcr1:
;*   01010 10111 01010 01010 01010 01010 01010 01010
;*     \     /     \     /     \     /     \     /
;*       $07         $00         $00         $00
;*
;* emptygcr2: (repeat $40 times)
;*   01010 01010 01010 01010 01010 01010 01010 01010
;*     \     /     \     /     \     /     \     /
;*       $00         $00         $00         $00
;*
emptygcr1:
	dc.b	$4a,$29,$a5,$d4,$55
emptygcr2:
	dc.b	$4a,$29,$a5,$94,$52


;**************************************************************************
;**
;** here is where we enter first.
;** started using a M-E command.
;** Now we are in IP mode.
;**
;******
FormatEntry:

;*
;* set initial formatting parameters
;*
	lda	#$ff
	sta	$51	;FTNUM
	lda	#0
	sta	$7f
	lda	fmt_id
	sta	$12
	lda	fmt_id+1
	sta	$13

;*
;* led on, clear all channels
;*
	jsr	$c100	;SETLDA

	jsr	$d307	;CLRCHN

;*
;* do execute job
;*
	lda	#1
	sta	$08	;HDRS1
	lda	#0
	sta	$09	;HDRS1+1

	lda	#$e0	;JOB: execute
	sta	$01	;in buffer #1 ($0400)
fe_lp1:
	lda	$01
	bmi	fe_lp1

	cmp	#$02
	bcc	fe_ex1

	lda	#$03	;21, 'read error'
	ldx	#$00
	jmp	$e60a	;ERROR

fe_ex1:

;*
;* prepare a new BAM
;*
	jsr	$f005	;CLRBAM
	jsr	$eeb7	;NEWMAP

;*
;* wipe name and id area with $a0
;*
	ldy	#$90
	lda	#$a0
fe_lp2:
	sta	($6d),y
	iny
	cpy	#$ab
	bne	fe_lp2


;*
;* store 1541 format identifier
;*
	lda	#$41
	sta	$0101
	ldy	#$02
	sta	($6d),y
	ldy	#$a6
	sta	($6d),y
	dey
	lda	#"2"
	sta	($6d),y

;*
;* copy name
;*
	ldy	#$90
	ldx	#0
fe_lp3:
	lda	fmt_name,x
	sta	($6d),y
	iny
	inx
	cpx	#16
	bne	fe_lp3

;*
;* copy id
;*
	lda	fmt_id
	ldy	#$a2
	sta	($6d),y
	iny
	lda	fmt_id+1
	sta	($6d),y


;*
;* Mark sectors 18,00 and 18,01 as used in BAM
;*
	lda	#18
	sta	$80
	lda	#1
	sta	$81
	jsr	$ef93	;USEDTS
	dec	$81
	jsr	$ef93	;USEDTS

;*
;* write BAM to disk
;*
	jsr	$eeff	;SCRBAM


;*
;* prepare and write out the 18,01 sector
;*
	jsr	$f005	;CLRBAM
	ldy	#1
	lda	#$ff
	sta	($6d),y
	inc	$81
	jsr	$d464	;DRTWRT

;*
;* do init to read back BAM
;*
	jsr	$d042	;DRINIT

;*
;* return to 1541 DOS.
;*
	jmp	$c194

;**************************************************************************
;**
;** data
;** must be filled in by master program.
;**
;******
fnameid:
fmt_name:
	ds.b	16
fmt_id:
	ds.b	2
fmt_vfyflag:
	dc.b	$ff


fdiskend:
	REND


	ECHO	"FDISK: ", fdiskstart,fdiskend
