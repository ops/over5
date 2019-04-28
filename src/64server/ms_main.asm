;**************************************************************************
;**
;** ms_main.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502


	seg	code

	INCLUDE	ms_mem.i
	INCLUDE	ms_rev.i
	INCLUDE libdef.i
	INCLUDE	Protocol.i
	INCLUDE	bl_mem.i


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
	dc.w	1996
	dc.b	$9e,"2069 /T.L.R/",0
;	     1996 SYS2069 /T.L.R/
EndLine:
	dc.w	0


	IFCONST	ATC800
TheStart:
;*** install Slave ***

	ldx	#<Slave_rel
	ldy	#>Slave_rel
	stx	copysrczp
	sty	copysrczp+1
	ldx	#<Slave_st
	ldy	#>Slave_st
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
	lda	copydestzp
	cmp	#<Slave_end
	bne	sa_lp2
	lda	copydestzp+1
	cmp	#>Slave_end
	bne	sa_lp2
	jmp	SysAddress

Slave_rel:
	RORG	$c800
	ENDIF
Slave_st:
;**************************************************************************
;**
;** Start of the program! 
;**
;******
SysAddress:

;*** show startup page ***
	jsr	Startpage

	jsr	InitSerial

	jsr	Server
bug:
	inc	$d020
	jmp	bug



;**************************************************************************
;**
;** Server
;**
;******
Server:
sv_lp1:
	lda	#<BUFFER
	sta	bl_currzp
	lda	#>BUFFER
	sta	bl_currzp+1

;*** receive command ***
	jsr	ReadBlockNoTimeout
	bcs	sv_fl1
	lda	bl_channelzp
	cmp	#15
	bne	sv_fl1

	lda	BUFFER
	cmp	#TYPE_MEMTRANSFER
	beq	sv_mem


	lda	#RESP_NOTSUPPORTED
	jsr	SendResp


sv_fl1:
	jmp	sv_lp1

;*** handle memoryrequest ***
sv_mem:
	jsr	MemTransfer
	jmp	sv_lp1




;**************************************************************************
;**
;** Modules
;**
;******
	INCLUDE	pr_MemTransfer.asm
	INCLUDE	pr_Support.asm
	INCLUDE	bl_Block.asm

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

	lda	#<Startup_MSG
	ldy	#>Startup_MSG
	jsr	$ab1e
sp_lp1:
	jsr	$ffe4
	cmp	#" "
	bne	sp_lp1
	rts



;**************************************************************************
;**
;** Startpage MESSAGES
;**
;******
Startup_MSG:
	dc.b	147,8,14	;HOME, No togglecase, UPPERCASE
	dc.b	"mEMSLAVE "
	verrev
	dc.b	" "
	date
	dc.b	13
	dc.b	"sERIAL mEMORY sERVER BY dANIEL kAHLIN.",13
	dc.b	"eMAIL: <TLR@STACKEN.KTH.SE>",13
	dc.b	13
	IFCONST	AT0801
	dc.b	"rESIDENT AT $0801-$1000",13
	ENDIF
	IFCONST	ATC800
	dc.b	"rESIDENT AT $c800-$d000",13
	ENDIF
	IFCONST	PAL
	dc.b	"sPEED: 38400 8n2 (pal VERSION)",13
	ENDIF
	IFCONST	NTSC
	dc.b	"sPEED: 38400 8n2 (ntsc VERSION)",13
	ENDIF
	dc.b	13
	dc.b	"<spacebar> ENTERS SERVER MODE",0


;**************************************************************************
;**
;** Buffers
;**
;******
BUFFER		EQU	.

FileBufferStart	EQU	$2000	;bonus

	ECHO	"Slave ",Slave_st,"-",.

Slave_end:
	IFCONST	ATC800
	REND
	ENDIF
