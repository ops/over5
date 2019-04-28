;**************************************************************************
;**
;** dsk_disknormal.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******



;**************************************************************************
;**
;** WriteFileNormal
;**
;** IN: d_currzp
;** RET: Carry=0 OK! 
;**
;******
WriteFileNormal:
	IFNCONST NOCOLOR
	jsr	dsk_savecolor
	ENDIF

	IFCONST CARTRIDGE
	jsr	dsk_installgetmem
	ENDIF

;*
;* initialize and open
;*
	lda	#$00
	sta	$90	;status
	lda	#$61
	sta	$b9	;secondary address
	jsr	$f3d5	;iec-open
	lda	$ba	;device number
	jsr	$ffb1	;LISTEN
	lda	$b9
	jsr	$ff93	;SECOND


;*
;* the main write loop
;*
wfn_lp2:

;*
;* get byte from memory (always from RAM)
;*
	ldy	#0
	IFNCONST CARTRIDGE
	sei
	ldx	#$34
	stx	$01
	lda	(d_currzp),y
	ldx	#$37
	stx	$01
	cli
	ELSE
	sei
	ldx	#$34
	jsr	dsk_getmem
	cli
	ENDIF

;*
;* write byte to IEC-bus
;*
	jsr	$ffa8	;CIOUT

;*
;* check status, exit if fail
;*
	lda	$90
	and	#%10000011
	bne	wfn_fl1

;*
;* increase address and check for end
;*
	inc	d_currzp
	bne	wfn_skp2
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF
	inc	d_currzp+1
wfn_skp2:
	lda	d_currzp
	cmp	d_endzp
	bne	wfn_lp2
	lda	d_currzp+1
	cmp	d_endzp+1
	bne	wfn_lp2

;*
;* Normal exit, clean up and CLEAR carry.
;*
	jsr	$ffae	;UNLSN
	jsr	$f642	;iec-close
	clc
	rts

;*
;* Failure exit, clean up and SET carry.
;*
wfn_fl1:
	jsr	$ffae	;UNLSN
	jsr	$f642	;iec-close
	sec
	rts




;**************************************************************************
;**
;** Read file to buffer...Normal
;**
;** IN: d_currzp
;** RET: d_endzp
;** Carry=0 OK! 
;**
;******
ReadFileNormal:
	IFNCONST NOCOLOR
	jsr	dsk_loadcolor
	ENDIF

;*
;* initialize and open
;*
	lda	#$00
	sta	$90	;status
	lda	#$60
	sta	$b9	;secondary address
	jsr	$f3d5	;iec-open
	lda	$ba	;device number
	jsr	$ffb4	;TALK
	lda	$b9
	jsr	$ff96	;TKSA


;*
;* the main read loop
;*
rfn_lp2:

;*
;* read byte from IEC-bus
;*
	jsr	$ffa5	;ACPTR
	tay

;*
;* check status, exit if fail
;*
	lda	$90
	and	#%10000011
	bne	rfn_fl1	

;*
;* store byte in memory (always in RAM)
;*
	tya
	sei
	IFNCONST CARTRIDGE
	ldx	#$34
	ELSE
	ldx	#$33
	ENDIF
	stx	$01
	ldy	#0
	sta	(d_currzp),y
	ldx	#$37
	stx	$01
	cli

;*
;* increase address 
;*
	inc	d_currzp
	bne	rfn_skp2

	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF
	inc	d_currzp+1
rfn_skp2:

;*
;* check for end of file
;*
	bit	$90
	bvc	rfn_lp2	;if not finished... loop!


;*
;* Normal exit, set end address, clean up and CLEAR carry.
;*
	lda	d_currzp
	sta	d_endzp
	lda	d_currzp+1
	sta	d_endzp+1

	jsr	$ffab	;UNTLK
	jsr	$f642	;iec-close
	clc
	rts

;*
;* Failure exit, clean up and SET carry.
;*
rfn_fl1:
	jsr	$ffab	;UNTLK
	jsr	$f642	;iec-close
	sec
	rts



;**************************************************************************
;**
;** Get Dosmessage...
;** Puts it in d_currzp, returns size in Y
;**
;******
GetStatusNormal:
	IFNCONST NOCOLOR
	jsr	dsk_statuscolor
	ENDIF

;*
;* initialize and open error channel
;*
	lda	#15
	tay
	ldx	$ba
	jsr	$ffba	;SETLFS
	lda	#0
	jsr	$ffbd	;SETNAM
	jsr	$ffc0	;OPEN
	ldx	#15
	jsr	$ffc6	;CHKIN

;*
;* get error string from drive
;*
	ldy	#0
gs_lp1:
	jsr	$ffcf	;CHRIN
	sta	(d_currzp),y
	iny
	cmp	#13
	bne	gs_lp1
	lda	#0
	dey
	sta	(d_currzp),y
	iny

;*
;* exit, clean up
;*
	jsr	$ffcc	;CLRCH
	jsr	$ffe7	;CLALL
	rts


;**************************************************************************
;**
;** Send DiskCommand...
;**
;******
DiskCommandNormal:

;*
;* initialize, open error channel and send command
;*
	lda	#15
	tay
	ldx	$ba
	jsr	$ffba	;SETLFS
	jsr	$ffc0	;OPEN

;*
;* exit, clean up
;*

	jsr	$ffe7	;CLALL

;	lda	#15
;	jsr	$ffc3	;CLOSE
	clc
	rts



;**************************************************************************
;**
;** ShowDirectory...
;**
;******
ShowDirectoryNormal:

;*
;* initialize and open
;*
	lda	#DnamLen
	ldx	#<Dnam
	ldy	#>Dnam
	jsr	$ffbd	;SETNAM
	lda	#1
	ldx	$ba
	ldy	#$60
	jsr	$ffba	;SETLFS
	jsr	$ffc0	;OPEN
	lda	$ba
	jsr	$ffb4	;TALK
	lda	$b9
	jsr	$ff96	;TKSA

	ldy	#$03
sd_lp1:
	sty	d_tempzp
sd_lp2:
	jsr	$ffa5	;ACPTR
	sta	d_tempptrzp
	jsr	$ffa5	;ACPTR
	sta	d_tempptrzp+1
	ldy	$90
	bne	sd_ex1
	dec	d_tempzp
	bne	sd_lp2
	jsr	sd_outputdecimal
	lda	#" "
	jsr	$ffd2	;CHROUT
sd_lp3:
	jsr	$ffa5	;ACPTR
	ldx	$90
	bne	sd_ex1
	cmp	#0
	beq	sd_skp1
	jsr	$ffd2	;CHROUT
	jmp	sd_lp3
sd_skp1:
	lda	#13
	jsr	$ffd2	;CHROUT
	ldy	#$02
sd_lp4:
	jsr	$ffe1	;STOP
	bne	sd_lp1

sd_ex1:

;*
;* exit, clean up
;*
	jsr	$ffab	;UNTLK
	lda	#1
	jsr	$ffc3	;CLOSE
	jsr	$ffe7	;CLALL
	clc
	rts
;***
Dnam:
	dc.b	"$0"
DnamLen	EQU	.-Dnam




;**************************************************************************
;**
;** output decimal
;**
;******
sd_outputdecimal:
	ldx	d_tempptrzp
	lda	d_tempptrzp+1
	jsr	$bdcd	;Output decimal number
	rts


