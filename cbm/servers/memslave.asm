;**************************************************************************
;**
;** ms_main.asm 
;** Copyright (c) 1995,1996,2002 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

initial_address	EQU	$c500

	seg	code

copysrczp	EQU	$fb
copydestzp	EQU	$fd

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


TheStart:
;*** install Slave ***

	ldx	#<Slave_st
	ldy	#>Slave_st
	stx	copysrczp
	sty	copysrczp+1
	ldx	#<initial_address
	ldy	#>initial_address
	stx	copydestzp
	sty	copydestzp+1


	ldy	#0
sa_lp2:
	lda	(copysrczp),y
	sta	(copydestzp),y
	inc	copysrczp
	bne	sa_skp1
	inc	copysrczp+1
sa_skp1:
	inc	copydestzp
	bne	sa_skp2
	inc	copydestzp+1
sa_skp2:
	lda	copysrczp
	cmp	#<Slave_end
	bne	sa_lp2
	lda	copysrczp+1
	cmp	#>Slave_end
	bne	sa_lp2
	jmp	initial_address

Slave_st:
	INCBIN	"memslave_tmp"
Slave_end:
	ECHO	Slave_st,Slave_end
	REND




; eof
