;**************************************************************************
;*
;* FILE  testrom.asm 
;* Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: testrom.asm,v 1.4 2002/05/11 10:17:37 tlr Exp $
;*
;* DESCRIPTION
;*
;*
;******
	PROCESSOR 6502

	SEG.U	zeropage
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

; clone $e000-$ffff (kernel)
	lda	#>startkernal	;base page
	ldy	#$e0	
	ldx	#$20	;number of pages
	jsr	copyself

; flip out roms
	lda	#$35
	sta	$01

; install ram patch
	jsr	rampatch

; install reset handler
	jsr	installreset
	
; let lose!
	jmp	($fffc)

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

	ALIGN	256
	ds.b	254
startkernal	EQU	.+2
	INCBIN	"kernal_c64_ram"
endkernal:
; eof






