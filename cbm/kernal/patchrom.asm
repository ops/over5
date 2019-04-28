;**************************************************************************
;*
;* FILE  patchrom.asm 
;* Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: patchrom.asm,v 1.2 2002/05/11 12:17:17 tlr Exp $
;*
;* DESCRIPTION
;*
;*
;******
	PROCESSOR 6502

	SEG.U	zeropage
	ORG	$2d
destendzp:
	ds.w	1
	ORG	$ac
basezp:
	ds.w	1
lenzp:
	ds.w	1
	ORG	$fb
srczp:
	ds.w	1
destzp:
	ds.w	1

; setup segments
	SEG	code
	ORG	$0801
;**************************************************************************
;*
;* Sysline
;*
;******
StartOfFile:
	dc.w	EndLine
SumStart:
	dc.w	2002
	dc.b	$9e,"2069 /T.L.R/",0
;	     2002 SYS2069 /T.L.R/
EndLine:
	dc.w	0
;**************************************************************************
;*
;* Start of the program! 
;*
;******
SysAddress:
	sei
	lda	#$37
	sta	$01

; clone $a000-$bfff (basic)
	lda	#$a0	;base page
	tay
	ldx	#$20	;number of pages
	jsr	copyself

	IF	0
; clone $e000-$ffff (kernel)
	lda	#$e0	;base page
	tay
	ldx	#$20	;number of pages
	jsr	copyself
	ENDIF

; apply the patch
	jsr	applypatch

; flip out roms
	lda	#$35
	sta	$01

	IFCONST	DEBUG
; clone $e000-$ffff to safe store at $4000 (kernel)
	lda	#$e0	;base page
	ldy	#$40	;dest page
	ldx	#$20	;number of pages
	jsr	copyself
	ENDIF

; install ram patch
	jsr	rampatch

; install reset handler
	jsr	installreset
	
; let lose!
	jmp	($fffc)

;**************************************************************************
;*
;* NAME  applypatch
;*
;* DESCRIPTION
;*   Install a patch
;*
;******
applypatch:
	lda	#<patch
	sta	srczp
	lda	#>patch
	sta	srczp+1
	lda	#<$e000
	sta	destzp
	lda	#>$e000
	sta	destzp+1
	lda	#<$0000
	sta	destendzp
	lda	#>$0000
	sta	destendzp+1

;* the header chunk *

; get (dummy) base
	jsr	ap_getbase
; get len
	jsr	ap_getlen

; skip the header chunk
	lda	srczp
	clc
	adc	lenzp
	sta	srczp
	lda	srczp+1
	adc	lenzp+1
	sta	srczp+1

;* main *
ap_lp1:
	jsr	ap_getbase
	jsr	ap_getlen

; if len is zero, we found the end.
	lda	lenzp
	ora	lenzp+1
	beq	ap_ex1

; otherwise, copy len bytes to base.

; fill up the space between the chunks
	jsr	ap_fillup
	bcs	ap_fl1

ap_lp2:
	jsr	ap_getbyte
	jsr	ap_putbyte

	lda	lenzp
	bne	ap_skp1
	dec	lenzp+1
ap_skp1:
	dec	lenzp

	lda	lenzp
	ora	lenzp+1
	bne	ap_lp2

	jmp	ap_lp1

ap_ex1:

; ok, fill up with data until end.
	lda	destendzp
	sta	basezp
	lda	destendzp+1
	sta	basezp+1
	jsr	ap_fillup
	bcs	ap_fl1

	clc
	rts

ap_fl1:
	sec
	rts

ap_fillup:
; if basezp > destzp, the copy data upto basezp.
; if basezp < destzp, there was an error!
	ldy	#0
apfu_lp1:
	lda	destzp
	cmp	basezp
	bne	apfu_skp1
	lda	destzp+1
	cmp	basezp+1
	beq	apfu_ex1

apfu_skp1:
	lda	(destzp),y
	jsr	ap_putbyte
	jmp	apfu_lp1

apfu_ex1:
	clc
	rts

		
ap_putbyte:
	sta	(destzp),y
	inc	destzp
	bne	appb_ex1
	inc	destzp+1
appb_ex1:
	rts

ap_getbase:
	jsr	ap_getbyte
	sta	basezp
	jsr	ap_getbyte
	sta	basezp+1
	rts
ap_getlen:
	jsr	ap_getbyte
	sta	lenzp
	jsr	ap_getbyte
	sta	lenzp+1
	rts
ap_getbyte:
	ldy	#0
	lda	(srczp),y
	inc	srczp
	bne	apgb_ex1
	inc	srczp+1
apgb_ex1:
	rts


;**************************************************************************
;*
;* NAME  rampatch
;*
;* DESCRIPTION
;*   Install a patch to make the kernal runnable from ram.
;*
;******
rampatch:
; patch in memtest

; fd67 4c 88 fd  jmp $fd88
	lda	#$4c
	sta	$fd67
	lda	#$88
	sta	$fd68
	lda	#$fd
	sta	$fd69

; fd88 a2 00     ldx #$00
; fd8a a0 a0     ldy #$a0 
	lda	#$a2
	sta	$fd88
	lda	#$00
	sta	$fd89
	lda	#$a0
	sta	$fd8a
	sta	$fd8b

; patch to disable test for cartridge
; original:
; FD02 A2 05      LDX #$05
; FD04 BD 0F FD   LDA $FD0F,X
; FD07 DD 03 80   CMP $8003,X
; FD0A D0 03      BNE $FD0F
; FD0C CA         DEX
; FD0D D0 F5      BNE $FD04
; FD0F 60         RTS
;
; patch:
; fd04 a9 ff      lda #$ff
; fd06 60         rts

	lda	#$a9
	sta	$fd04
	lda	#$ff
	sta	$fd05
	lda	#$60
	sta	$fd06

; patch where $01 gets loaded.
; original:
;   FDD5 A9 E7     LDA #$E7
;   FDD7 85 01     STA $01
;   FDD9 A9 2F     LDA #$2F 
;   FDDB 85 00     STA $00
;
; replaced with:
;   fdd5 a9 xx     lda #$xx
;   fdd7 8d 00 a0  sta $a000
;   fdda ea        nop
;   fddb ea        nop
;   fddc ea        nop

	lda	#$a9
	sta	$fdd5
	lda	$a000
	sta	$fdd6
	lda	#$8d
	sta	$fdd7
	lda	#$00
	sta	$fdd8
	lda	#$a0
	sta	$fdd9
	lda	#$ea
	sta	$fdda
	sta	$fddb
	sta	$fddc
	rts

;**************************************************************************
;*
;* NAME  installreset
;*
;* DESCRIPTION
;*   Install a resident reset handler.
;*
;******
installreset:
; install the resetter
	ldx	#resetpatch_end-resetpatch_st
ir_lp1:
	lda	resetpatch_st-1,x
	sta	resetpatch-1,x
	dex
	bne	ir_lp1
	rts

resetpatch_st:
	RORG	$8000
resetpatch:
	dc.w	Reset			;Reset!
	dc.w	NMI			;Normal NMI
	dc.b	$c3,$c2,$cd,$38,$30	;CBM80
Reset:
	lda	#$e5
	sta	$01
	lda	#$2f
	sta	$00
; do reset again!
	jmp	($fffc)

NMI:
	lda	#$35
	sta	$01
; continue NMI (call check for cartridge again in case this was patched)
	jmp	$fe56	
	REND
resetpatch_end:

;**************************************************************************
;*
;* NAME  copyself
;* in: a=src start page, y=dest start page, x=num pages
;*
;******
copyself:
	sta	srczp+1
	sty	destzp+1
	ldy	#0
	sty	srczp
	sty	destzp
cs_lp1:
	lda	(srczp),y
	sta	(destzp),y
	iny
	bne	cs_lp1
	inc	srczp+1
	inc	destzp+1
	dex
	bne	cs_lp1
	rts

;**************************************************************************
;*
;* Here the patches should follow.
;* They must be sequential, and 0,0,0,0 terminated. (for example by running
;* tlrpatch -m on them)
;*
;******
patch:
; eof






