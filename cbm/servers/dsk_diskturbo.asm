;**************************************************************************
;**
;** dsk_diskturbo.asm
;** adapted in 1995 by Daniel Kahlin <tlr@stacken.kth.se>
;**
;** Turbodisk LOAD/SAVE c64 part
;** Turbodisk FORMAT c64 part
;**
;** code was loopunrolled! should be ok!
;**
;******

	PROCESSOR 6502

turbotmp1zp	EQU	d_turbotmp1zp	;byte
turbotmp2zp	EQU	d_turbotmp2zp	;byte
turbotmp3zp	EQU	d_turbotmp3zp	;byte farligt! OBS.
turboptr1zp	EQU	d_turboptr1zp	;word
turboptr2zp	EQU	d_turboptr2zp	;word
fbuffer		EQU	BUFFER+$80
idbuffer	EQU	fbuffer+16


;**************************************************************************
;**
;** WriteFileFast
;** Carry=0 OK!
;**
;******
WriteFileFast:
	IFNCONST NOCOLOR
	jsr	dsk_savecolor
	ENDIF

	jsr	$f3d5	;iec-open

	jsr	TurboDiskSave
	rts

;**************************************************************************
;**
;** Read file to buffer...FAST
;** Carry=0 OK!
;**
;******
ReadFileFast:
	IFNCONST NOCOLOR
	jsr	dsk_loadcolor
	ENDIF

	jsr	$f3d5

	jsr	TurboDiskLoad

	lda	d_currzp
	sta	d_endzp
	lda	d_currzp+1
	sta	d_endzp+1
	rts




;**************************************************************************
;**
;** TURBODISKLOAD
;** start: currzp
;** Carry=0 OK!
;******
TurboDiskLoad:
	lda	#<ldisk
	ldy	#>ldisk
	sta	turboptr1zp
	sty	turboptr1zp+1
	lda	#<ldiskstart
	ldy	#>ldiskstart
	sta	turboptr2zp
	sty	turboptr2zp+1
	lda	#<ldiskend
	ldy	#>ldiskend
	sta	turbotmp2zp
	sty	turbotmp3zp
	jsr	CopyToDiskRam
	jsr	SendMEblank
	lda	#<LoadEntry
	jsr	$ffa8
	lda	#>LoadEntry
	jsr	$ffa8
	jsr	$ffae
	sei	
tdl_lp1:
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF

	jsr	tdl_getbyte
	bpl	tdl_skp1
	jmp	tdl_ex2
tdl_skp1:
	php	
	jsr	tdl_getbyte
	plp	
	bne	tdl_skp2
	tax	
	dex	
	stx	turbotmp1zp
	php	
	pla	
	ora	#$40
	pha	
	plp	
	bvs	tdl_skp3
tdl_skp2:
	clv	
	lda	#$fe
	sta	turbotmp1zp
tdl_skp3:
	ldy	#$00
	lda	$dd00
	ora	#$08
	sta	$dd00

tdl_lp2:
	lda	$dd00
	bpl	tdl_lp2
	lda	$dd00
	and	#$07
	sta	$dd00

	jsr	tdl_twelve
	jsr	tdl_twelve
	jsr	tdl_twelve
	jsr	tdl_twelve
	sta	d_slaskzp

tdl_lp4:
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop

	lda	turbotmp2zp
	IFNCONST CARTRIDGE
	ldx	#$34
	stx	$01
	sta	(d_currzp),y
	ldx	#$37
	stx	$01
	ELSE
	ldx	#$33
	stx	$01
	sta	(d_currzp),y
	ldx	#$37
	stx	$01
	ENDIF
	iny	
	sbne	tdl_lp4		;6 cycle stable branch

	php	
	clc	
	lda	turbotmp1zp
	adc	d_currzp
	sta	d_currzp
	bcc	tdl_skp4
	inc	d_currzp+1
tdl_skp4:
	plp	
	bvs	tdl_ex1
	jmp	tdl_lp1
tdl_ex1:
	lda	#$00
tdl_ex2:
	tay	
	jsr	tdl_cleanup
	lda	#$40
	sta	$90
	tya	
	bpl	tdl_ex3
	jmp	$f633	;error
tdl_ex3:
	jmp	$f52b


	IFCONST	CARTRIDGE
;**************************************************************************
;**
;** Special get memory routine
;**
;******
turbo_getmemsource:
	RORG	turbo_getmemplace
	ECHO	"turbo_getmem... ",.
turbo_getmem:
	sta	$01
	lda	(d_currzp),y
	pha	
	eor	turboptr2zp
	sta	turboptr2zp
	lda	#$37
	sta	$01
	pla	
	rts
	ECHO	"... ",.
turbo_getmemend:
	REND
	ENDIF

;**************************************************************************
;**
;** TURBODISKSAVE
;** start: currzp end: endzp
;** Carry=0 OK!
;******
TurboDiskSave:
	IFCONST	CARTRIDGE
	ldx	#0
tdsc_lp1:
	lda	turbo_getmemsource,x
	sta	turbo_getmem,x
	inx
	cpx	#turbo_getmemend-turbo_getmem
	bne	tdsc_lp1
	ENDIF
	lda	#<sdisk
	ldy	#>sdisk
	sta	turboptr1zp
	sty	turboptr1zp+1
	lda	#<sdiskstart
	ldy	#>sdiskstart
	sta	turboptr2zp
	sty	turboptr2zp+1
	lda	#<sdiskend
	ldy	#>sdiskend
	sta	turbotmp2zp
	sty	turbotmp3zp
	jsr	CopyToDiskRam
	jsr	SendMEblank
	lda	$dd00
	and	#$07
	asl
	asl
	asl
	asl
	sta	turbotmp3zp
	lda	#<SaveEntry
	jsr	$ffa8
	lda	#>SaveEntry
	jsr	$ffa8
	jsr	$ffae
	sei	
tds_lp1:
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF

	lda	#$00
	sta	turboptr2zp
	jsr	tds_sendnumblocks
	jsr	tdl_getbyte
	bmi	tds_skp1
tds_lp2:
	ldy	#$00
	IFNCONST CARTRIDGE
	lda	#$34
	sta	$01
	lda	(d_currzp),y
	pha	
	eor	turboptr2zp
	sta	turboptr2zp
	lda	#$37
	sta	$01
	pla	
	ELSE
	lda	#$34
	jsr	turbo_getmem
	ENDIF	
	jsr	tds_sendbyte
	inc	d_currzp
	bne	tds_skp4
	inc	d_currzp+1
tds_skp4:
	dex	
	bne	tds_lp2
	lda	turboptr2zp
	jsr	tds_sendbyte
	bvs	tds_skp2
	bvc	tds_lp1
tds_skp1:
	bmi	tds_skp3
	bpl	tds_lp2
tds_skp2:
	jsr	tds_sendbyte
	jsr	tdl_getbyte
tds_skp3:
	php	
	jsr	tdl_cleanup
	lda	#$00
	sta	$90
	plp	
	bpl	tds_ex1
	sec	
	rts	
tds_ex1:
	clc	
	rts	

;**************************************************************************
;**
;** Send Code to driveram
;**
;******
CopyToDiskRam:
ctdr_lp1:
	jsr	SendM
	lda	#"W"
	jsr	$ffa8
	lda	turboptr2zp
	jsr	$ffa8
	lda	turboptr2zp+1
	jsr	$ffa8
	lda	#$1e
	jsr	$ffa8
	ldy	#$00
ctdr_lp2:
	lda	(turboptr1zp),y
	jsr	$ffa8
	iny	
	cpy	#$1e
	bcc	ctdr_lp2
	jsr	$ffae
	clc	
	lda	turboptr1zp
	adc	#$1e
	sta	turboptr1zp
	bcc	ctdr_skp1
	inc	turboptr1zp+1
	clc	
ctdr_skp1:
	lda	turboptr2zp
	ldx	turboptr2zp+1
	adc	#$1e
	sta	turboptr2zp
	bcc	ctdr_skp2
	inc	turboptr2zp+1
ctdr_skp2:
	cpx	turbotmp3zp
	bcc	ctdr_lp1
	cmp	turbotmp2zp
	bcc	ctdr_lp1
	rts

;**************************************************************************
;**
;** Send Memory execute
;**
;******
SendMEblank:
	lda	$d011
	and	#$ef
	sta	$d011
SendME:
	jsr	SendM
	lda	#"E"
	jmp	$ffa8


;**************************************************************************
;**
;** Send number of needed blocks to drive
;**
;******
tds_sendnumblocks:
	sec	
	lda	d_endzp
	sbc	d_currzp
	tax	
	tay	
	lda	d_endzp+1
	sbc	d_currzp+1
	bne	tds_snb_skp1
	cpx	#$ff
	bcs	tds_snb_skp1
	iny	
	tya	
	bne	tds_snb_skp2
tds_snb_skp1:
	ldx	#$fe
	lda	#$00
	clv	
	beq	tds_snb_ex1
tds_snb_skp2:
	php	
	pla	
	ora	#$40
	pha	
	plp	
	tya	
tds_snb_ex1:
	jmp	tds_sendbyte


;**************************************************************************
;**
;** Get a byte from drive
;**
;******
tdl_getbyte:
	lda	$dd00
	and	#$07
	ora	#$08
	sta	$dd00
tdl_gb_lp1:
	lda	$dd00
	bpl	tdl_gb_lp1
	lda	$dd00
	and	#$07
	sta	$dd00

	jsr	tdl_twelve
	jsr	tdl_twelve
	jsr	tdl_twelve

	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	sta	d_slaskzp
	lda	$dd00
	asl
	rol
	ror	turbotmp2zp
	lsr
	ror	turbotmp2zp
	nop	
	nop
	ldy	#0

	lda	turbotmp2zp
	eor	#$ff
tdl_twelve:
	rts	


;**************************************************************************
;**
;** Send listen to drive
;**
;******
SendListen:
	lda	$ba	;drive #
	jsr	$ffb1
	lda	#$6f
	jmp	$ff93


;**************************************************************************
;**
;** Send  'M-' to drive
;**
;******
SendM:
	jsr	SendListen
	lda	#"M"
	jsr	$ffa8
	lda	#"-"
	jmp	$ffa8


;**************************************************************************
;**
;** Send a byte of data
;**
;******
tds_sendbyte:
	sta	turbotmp2zp
	lda	$dd00
	and	#$07
	ora	#$08
	sta	$dd00
tds_sb_lp1:
	lda	$dd00
	bpl	tds_sb_lp1
	lda	$dd00
	and	#$07
	sta	$dd00
	nop

	lda	turbotmp3zp
	lsr	turbotmp2zp
	ror
	lsr	turbotmp2zp
	ror
	lsr
	lsr
	sta	$dd00
	nop
	sta	d_slaskzp
	lda	turbotmp3zp
	lsr	turbotmp2zp
	ror
	lsr	turbotmp2zp
	ror
	lsr
	lsr
	sta	$dd00
	nop
	sta	d_slaskzp
	lda	turbotmp3zp
	lsr	turbotmp2zp
	ror
	lsr	turbotmp2zp
	ror
	lsr
	lsr
	sta	$dd00
	nop
	sta	d_slaskzp
	lda	turbotmp3zp
	lsr	turbotmp2zp
	ror
	lsr	turbotmp2zp
	ror
	lsr
	lsr
	sta	$dd00
	nop
	nop

	nop
	nop
	ldy	#0
	rts	

;**************************************************************************
;**
;** RESTORE bits open screen!
;**
;******
tdl_cleanup:
	lda	#%00000111
	sta	$dd00
	lda	$d011
	ora	#$10
	sta	$d011
	cli	
	clc	
	rts	


;**************************************************************************
;**
;** TURBOFORMAT
;** IN: $bb,$bc COMMAND  $b7=LEN
;** Carry=0 OK!  Carry=1 (couldn't format)
;**
;******
TurboFormat:

;* null len ? *
	lda	$b7
	beq	tf_fl1

	ldy	#0
;* check if format (N) *
	lda	($bb),y
	cmp	#"N"
	bne	tf_fl1
	iny
	cpy	$b7
	beq	tf_fl1

;* find and skip ':' *
tf_lp1:
	lda	($bb),y
	iny
	cpy	$b7
	beq	tf_fl1
	cmp	#":"	
	bne	tf_lp1


;* fill with default ($a0's) *
	ldx	#18-1
tf_lp5:
	lda	#$a0
	sta	fbuffer,x
	dex
	bpl	tf_lp5


;* build name string *
	ldx	#0
tf_lp2:
	lda	($bb),y
	cmp	#","
	beq	tf_skp1
	sta	fbuffer,x
	inx
	iny
	cpy	$b7
	beq	tf_fl1
	cpx	#16	
	bne	tf_lp2
tf_skp1:
;* get id chars *
	ldx	#0
tf_lp3:
	iny
	cpy	$b7
	beq	tf_skp2
	lda	($bb),y
	sta	idbuffer,x
	inx
	cpx	#2	
	bne	tf_lp3

;* Do the format *
tf_skp2:
	jsr	DoTurboFormat

	clc
	rts

tf_fl1:
	sec
	rts

;**************************************************************************
;**
;** DoTurboFormat
;** Carry=0 OK!
;**
;******
DoTurboFormat:
;*** install code ***
	lda	#<fdisk
	ldy	#>fdisk
	sta	turboptr1zp
	sty	turboptr1zp+1
	lda	#<fdiskstart
	ldy	#>fdiskstart
	sta	turboptr2zp
	sty	turboptr2zp+1
	lda	#<fdiskend
	ldy	#>fdiskend
	sta	turbotmp2zp
	sty	turbotmp3zp
	jsr	CopyToDiskRam

;*** write name and id ***
	jsr	SendM
	lda	#"W"
	jsr	$ffa8
	lda	#<fnameid
	jsr	$ffa8
	lda	#>fnameid
	jsr	$ffa8
	lda	#19
	jsr	$ffa8
	ldy	#$00
dtf_lp1:
	lda	fbuffer,y
	jsr	$ffa8
	iny	
	cpy	#18
	bne	dtf_lp1

;*
;* send fmt_vfyflag
;*
	ldx	#$ff
	lda	d_modeflags
	and	#DMODE_VERIFY
	bne	dtf_skp1
	ldx	#$00
dtf_skp1:
	txa
	jsr	$ffa8

	jsr	$ffae


;*** do format ***
	jsr	SendME
	lda	#<FormatEntry
	jsr	$ffa8
	lda	#>FormatEntry
	jsr	$ffa8
	jsr	$ffae



	jsr	$ffe7

	clc
	rts



;**************************************************************************
;**
;** DRIVECODE
;**
;******
ldisk:
	INCLUDE	dsk_ldisk.asm
sdisk:
	INCLUDE	dsk_sdisk.asm
fdisk:
	INCLUDE	dsk_fdisk.asm

