;**************************************************************************
;**
;** intro.asm 
;** Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;**
;******

	PROCESSOR 6502

	seg	code

currzp	EQU	$fb

	ORG	$0801
;**************************************************************************
;**
;** Sysline
;**
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
;**
;** Start of the program! 
;**
;******
SysAddress:
	jsr	Startpage
sa_lp1:
	jmp	sa_lp1

;**************************************************************************
;**
;** Startpage
;**
;******
Startpage:
	lda	#5
	sta	$d020
	sta	$d021
	lda	#13
	sta	646

	ldx	#<Startup_MSG
	ldy	#>Startup_MSG
	jsr	printstr

	jsr	drawframe


	rts


drawframe:
	lda	#97	;left
	sta	1024+40

	lda	#225	;right
	sta	1027+40

	lda	#226	;upper
	sta	1025
	sta	1026

	lda	#98	;lower
	sta	1025+80
	sta	1026+80

	lda	#236	;upperleftcorner
	sta	1024

	lda	#251	;upperrightcorner
	sta	1027

	lda	#252	;lowerleftcorner
	sta	1024+80

	lda	#254	;lowerrightcorner
	sta	1027+80

	
	rts

;**************************************************************************
;**
;** Print a str
;** X,Y=PTR
;**
;******
printstr:
	stx	currzp
	sty	currzp+1
	ldy	#0
ps_lp1:
	lda	(currzp),y	
	beq	ps_ex1
	jsr	$ffd2
	iny
	bne	ps_lp1
	inc	currzp+1
	jmp	ps_lp1
ps_ex1:

	rts


;**************************************************************************
;**
;** Startpage MESSAGES
;**
;******
Startup_MSG:
	dc.b	147,8,14	;HOME, No togglecase, UPPERCASE
	dc.b	"dISKSLAVE "
	dc.b	"0.712"
	dc.b	" "
	dc.b	13
	dc.b	"sERIAL dISK sERVER BY dANIEL kAHLIN.",13
	dc.b	"eMAIL: <TLR@STACKEN.KTH.SE>",13
	dc.b	13
	dc.b	"bUFFER: $3000-$fff8 (209 BLOCKS)",13
	dc.b	"sPEED: 38400 8n2 (pal VERSION)",13
	dc.b	13
	dc.b	13
	dc.b	"<t> TOGGLE DISKTURBO ON/OFF",13
	dc.b	"<v> TOGGLE VERIFY ON/OFF",13
	dc.b	"<x> EXIT TO basic",13
	dc.b	"<spacebar> ENTERS SERVER MODE",0


; eof
