
;**************************************************************************
;**
;** copytail.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

;>> ORDER MUST NOT BE CHANGED!! <<
PAR_SRC_L	EQU	$0
PAR_SRC_H	EQU	$1
PAR_DEST_L	EQU	$2
PAR_DEST_H	EQU	$3
PAR_END_L	EQU	$4
PAR_END_H	EQU	$5
PAR_PAGES	EQU	$6

;zeropage definitions
srczp		EQU	$fb
destzp		EQU	$fd
relzp		EQU	$ae
rtsaddr		EQU	$fb


	org	$c000	;this shouldn't matter at all since we are PC rel!


;**************************************************************************
;**
;** copytail
;** Fully relocatable & machine independant code.
;**
;******
copytail:
	sei

;* special code for relative addressing 
;* fucks up if NMI occurs somewhere
	lda	#$60
	sta	rtsaddr
	jsr	rtsaddr
reladdr:
	tsx
	lda.wx	$0100-1,x
	sta	relzp
	lda.wx	$0100,x
	sta	relzp+1

;* preserve $01 (in case this is not a C64)
	lda	$01
	pha

;* switch mem on C64 (harmless on others)
	lda	#$36
	sta	$01

	ldy	#PAR_OFFSET

;* get PAR_SRC_L & PAR_SRC_H
	lda	(relzp),y
	sta	srczp
	iny
	lda	(relzp),y
	sta	srczp+1
	iny

;* get PAR_DEST_L & PAR_DEST_H
	lda	(relzp),y
	sta	destzp
	iny
	lda	(relzp),y
	sta	destzp+1
	iny

;* get PAR_END_L & PAR_END_H
;* set basic end pointer
	lda	(relzp),y
	sta	$2d
	iny
	lda	(relzp),y
	sta	$2e
	iny

;* get PAR_PAGES
	lda	(relzp),y
	tax

;* copy X-reg number of pages to dest
	ldy	#0
ct_lp1:
	lda	(srczp),y
	sta	(destzp),y
	iny
	bne	ct_lp1
	inc	srczp+1
	inc	destzp+1
	dex
	bne	ct_lp1

;* restore $01 
	pla
	sta	$01
	cli

;* print nice message
	ldy	#MSG_OFFSET
ct_lp2:
	lda	(relzp),y
	beq	ct_ex1
	jsr	$ffd2	
	iny
	bne	ct_lp2	;always!
ct_ex1:

;* exit
	rts

;* messages
ok_MSG:
	dc.b	13,"OK, NOW SAVE TO DISK OR TAPE",13,0
params:

;* offsets
PAR_OFFSET	EQU	[params-reladdr]+1
MSG_OFFSET	EQU	[ok_MSG-reladdr]+1

