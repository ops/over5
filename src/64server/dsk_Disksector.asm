;**************************************************************************
;**
;** dsk_Disksector.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	INCLUDE	dsk_PitchTrack.asm


;**************************************************************************
;**
;** Calculate end address
;**
;** IN: Acc=Track x=numtracks
;** OUT: d_endzp,d_endzp+1 length of data
;**
;******
CalcEnd:
	stx	d_tempzp
	tax
	lda	#0
	sta	d_endzp
	sta	d_endzp+1

;* calulate end address *
ce_lp1:
	lda	d_endzp+1
	clc
	adc	maxsectors,x
	sta	d_endzp+1
	inx
	dec	d_tempzp
	bne	ce_lp1


	rts



;**************************************************************************
;**
;** WriteTrackFast:
;** IN: d_currzp,d_currzp+1 Buffer  d_trackzp=track  d_tempzp=numtracks
;**
;** Carry=0 OK! 
;**
;******
WriteTrackFast:
	jsr	initdrive

wtf_lp1:
	lda	#3
	sta	d_retries

	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF

wtf_lp2:

;*
;* write track
;*
	ldx	d_currzp
	ldy	d_currzp+1
	lda	d_trackzp
	jsr	sendtrack
	bcs	wtf_fl1

	lda	d_modeflags	;verify?
	and	#DMODE_VERIFY
	beq	wtf_skp1
;*
;* verify track
;*
	ldx	d_currzp
	ldy	d_currzp+1
	lda	d_trackzp
	jsr	verifytrack
	bcc	wtf_skp1

;*
;* failed... retry
;*
	IFNCONST NOCOLOR
	lda	#2	;fail color
	sta	$d020
	ENDIF
	dec	d_retries
	bne	wtf_lp2
	jmp	wtf_fl1

;*
;* ok...
;*
wtf_skp1:
	IFNCONST NOCOLOR
	lda	$d020
	and	#8
	ora	#SAVECOLOR	;normal color if success
	sta	$d020
	ENDIF

	ldx	d_trackzp
	lda	d_currzp+1
	clc
	adc	maxsectors,x
	sta	d_currzp+1

	inc	d_trackzp
	dec	d_tempzp
	bne	wtf_lp1

wtf_fl1:
	php
	jsr	resetdrive
	plp
	rts

;**************************************************************************
;**
;** ReadTrackFast:
;** IN: d_currzp,d_currzp+1 Buffer  d_trackzp=track  d_tempzp=numtracks
;**
;** Carry=0 OK! 
;**
;******
ReadTrackFast:
	jsr	initdrive
rtf_lp1:
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF
	ldx	d_currzp
	ldy	d_currzp+1
	lda	d_trackzp
	jsr	gettrack
	bcs	rtf_fl1

	ldx	d_trackzp
	lda	d_currzp+1
	clc
	adc	maxsectors,x
	sta	d_currzp+1

	inc	d_trackzp
	dec	d_tempzp
	bne	rtf_lp1

rtf_fl1:
	php
	jsr	resetdrive
	plp
	rts



;**************************************************************************
;**
;** WriteTrackNormal:
;** IN: d_currzp,d_currzp+1 Buffer  d_trackzp=track  d_tempzp=numtracks
;**
;** Carry=0 OK! 
;**
;******
WriteTrackNormal:
	IFCONST CARTRIDGE
	jsr	dsk_installgetmem
	ENDIF
	jsr	OpenCommandFiles
wts_lp2:

;*** write track ***
	ldx	#0
	stx	d_sectorzp
wts_lp1:
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF
	jsr	SendBPReset
	jsr	PutDiskBuffer
	jsr	SendWrite
	inc	d_currzp+1
	inc	d_sectorzp
	ldx	d_trackzp
	lda	maxsectors,x
	cmp	d_sectorzp
	bne	wts_lp1

;*** more tracks ? ***
	inc	d_trackzp
	dec	d_tempzp
	bne	wts_lp2	

;*** close down ***
	jsr	CloseCommandFiles

	clc
	rts
wts_fl1:
	sec
	rts




;**************************************************************************
;**
;** ReadTrackNormal
;** IN: d_currzp,d_currzp+1 Buffer  d_trackzp=track  d_tempzp=numtracks
;**
;** Carry=0 OK! 
;**
;******
ReadTrackNormal:
	jsr	OpenCommandFiles
rts_lp2:

;*** read track ***

	ldx	#0
	stx	d_sectorzp
rts_lp1:
	IFNCONST NOCOLOR
	jsr	dsk_togglecolor
	ENDIF
	jsr	SendRead
	jsr	SendBPReset
	jsr	GetDiskBuffer
	inc	d_currzp+1
	inc	d_sectorzp
	ldx	d_trackzp
	lda	maxsectors,x
	cmp	d_sectorzp
	bne	rts_lp1

;*** more tracks ? ***
	inc	d_trackzp
	dec	d_tempzp
	bne	rts_lp2	

;*** close down ***
	jsr	CloseCommandFiles

	clc
	rts
rts_fl1:
	sec
	rts



;**************************************************************************
;**
;** OpenCommandFiles
;**
;******
OpenCommandFiles:
	jsr	$ffe7	;CLALL

	lda	#15
	ldx	$ba
	ldy	#15
	jsr	$ffba
	lda	#$00
	jsr	$ffbd
	jsr	$ffc0

	lda	#1
	ldx	$ba
	ldy	#8
	jsr	$ffba
	lda	#1
	ldx	#<buffer_msg
	ldy	#>buffer_msg
	jsr	$ffbd
	jsr	$ffc0

	rts


;**************************************************************************
;**
;** CloseCommandFiles
;**
;******
CloseCommandFiles:
	jsr	$ffcc	;CLCHN
	lda	#1
	jsr	$ffc3	;Close
	lda	#15
	jsr	$ffc3	;CLose
	jsr	$ffe7	;CLALL
	rts

;**************************************************************************
;**
;** SendRead, SendWrite
;**
;******
SendRead:
	lda	#$31
	bne	sw_skp1
SendWrite:
	lda	#$32
sw_skp1:
;*** send command ***
	pha
	ldx	#15
	jsr	$ffc9
	lda	#"U"
	jsr	$ffd2
	pla
	jsr	$ffd2
	lda	#" "
	jsr	$ffd2
;*** send channel ***
	lda	#$38
	jsr	$ffd2
	lda	#" "
	jsr	$ffd2
;*** send zero ***
	lda	#"0"
	jsr	$ffd2
	lda	#" "
	jsr	$ffd2
;*** send track ***
	lda	d_trackzp
	asl
	tax
	lda	decimaltab,x
	jsr	$ffd2
	inx
	lda	decimaltab,x
	jsr	$ffd2
	lda	#","
	jsr	$ffd2
;*** send sector ***
	lda	d_sectorzp
	asl
	tax
	lda	decimaltab,x
	jsr	$ffd2
	inx
	lda	decimaltab,x
	jsr	$ffd2
;*** end line ***
	lda	#13
	jsr	$ffd2
	jsr	$ffcc	;CLCHN
	rts

;**************************************************************************
;**
;** CloseCommandFiles
;**
;******
SendBPReset:
	ldx	#15
	jsr	$ffc9
	ldx	#$00
sbpr_lp1:
	lda	bpreset_msg,x
	jsr	$ffd2
	inx
	cmp	#$0d
	bne	sbpr_lp1
	jsr	$ffcc	;CLCHN
	rts

;**************************************************************************
;**
;** Get Data from diskbuffer
;**
;******
GetDiskBuffer:
	ldx	#1
	jsr	$ffc6
	ldy	#$00
gdb_lp1:
	jsr	$ffcf
	sei
	IFNCONST CARTRIDGE
	ldx	#$34
	ELSE
	ldx	#$33
	ENDIF
	stx	$01
	sta	(d_currzp),y
	ldx	#$37
	stx	$01
	cli
	iny
	bne	gdb_lp1
	jsr	$ffcc	;CLCHN
	rts

;**************************************************************************
;**
;** Put data in disk buffer
;**
;******
PutDiskBuffer:
	ldx	#1
	jsr	$ffc9
	ldy	#$00
pdb_lp1:
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
	jsr	$ffd2
	iny
	bne	pdb_lp1
	jsr	$ffcc	;CLCHN
	rts



;**************************************************************************
;**
;** Strings
;**
;******
bpreset_msg:
	dc.b	"B-P:8 0",13,0
buffer_msg:
	dc.b	"#"
decimaltab:
	dc.b	"00010203040506070809101112131415"
	dc.b	"16171819202122232425262728293031"
	dc.b	"3233343536"
maxsectors:
	dc.b	0
	dc.b	21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21
	dc.b	19,19,19,19,19,19,19
	dc.b	18,18,18,18,18,18
	dc.b	17,17,17,17,17



