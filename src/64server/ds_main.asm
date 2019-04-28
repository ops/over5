;**************************************************************************
;**
;** ds_main.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

	seg	code

	INCLUDE	ds_mem.i
	INCLUDE	ds_rev.i
	INCLUDE macros.i
	INCLUDE libdef.i
	INCLUDE	Protocol.i
	INCLUDE	bl_mem.i
	INCLUDE ds_mem.i


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
;**************************************************************************
;**
;** Start of the program! 
;**
;******
SysAddress:
	tsx
	stx	stacktempzp

;*
;* enable turbo and verify by default
;*
	lda	#MODEF_TURBO|MODEF_VERIFY
	sta	modeflags



sa_entry:
;*
;* setup NMI vectors
;*
	ldx	#<restoreroutine
	ldy	#>restoreroutine
	stx	$0318
	sty	$0319
	stx	$fffa
	sty	$fffb

;*
;* show startup page
;*
	jsr	Startpage


;*
;* exit to basic
;*
	jsr	$ff5b
	ldx	#<exit_MSG
	ldy	#>exit_MSG
	jsr	printstr

	ldx	stacktempzp
	txs
	cli
	jmp	$a474


;**************************************************************************
;**
;** NMI entry point! 
;**
;******
restoreroutine:
	sei
	lda	#$37
	sta	$01
	jsr	$fd15
	jsr	$fda3
	jsr	$e518
	ldx	stacktempzp
	txs
	jmp	sa_entry


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
	cmp	#TYPE_FILETRANSFER
	beq	sv_file
	cmp	#TYPE_DISKCOMMAND
	beq	sv_disk
	cmp	#TYPE_RAWDISKTRANSFER
	beq	sv_rawdisk
	cmp	#TYPE_TESTCOMMAND
	beq	sv_test

	lda	#RESP_NOTSUPPORTED
	jsr	SendResp

sv_fl1:
	jmp	sv_lp1

;*** handle filerequest ***
sv_file:
	jsr	FileTransfer
	jmp	sv_lp1

;*** handle filerequest ***
sv_disk:
	jsr	DiskCommands
	jmp	sv_lp1

;*** handle rawdiskrequest ***
sv_rawdisk:
	jsr	RawdiskTransfer
	jmp	sv_lp1

;*** handle testrequest ***
sv_test:
	jsr	TestCommand
	jmp	sv_lp1



;**************************************************************************
;**
;** Modules
;**
;******
	INCLUDE	pr_FileTransfer.asm
	INCLUDE	pr_Test.asm
	INCLUDE	pr_Support.asm
	INCLUDE	pr_rawdiskTransfer.asm
	INCLUDE	bl_Block.asm
	INCLUDE	dsk_Disk.asm

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
sp_lp2:
	jsr	sp_showflags


;*
;* set turboflag
;*
	ldx	#0
	lda	modeflags
	lsr
	lsr
	lsr
	lsr
	jsr	dsk_setmodeflags

;*
;* check keys
;*
sp_lp1:
	jsr	$ffe4
	cmp	#" "
	beq	sp_server
	cmp	#"X"
	beq	sp_ex1
	cmp	#"T"
	beq	sp_toggleturbo
	cmp	#"V"
	beq	sp_toggleverify
	jmp	sp_lp1

sp_ex1:
	rts

sp_toggleturbo:
	lda	modeflags
	eor	#MODEF_TURBO
	sta	modeflags
	jmp	sp_lp2

sp_toggleverify:
	lda	modeflags
	eor	#MODEF_VERIFY
	sta	modeflags
	jmp	sp_lp2


sp_server:
	jsr	InitSerial
	jsr	Server
	jsr	UninitSerial
	jmp	sp_lp2

;**************************************************************************
;**
;** Show state of flags
;**
;******
sp_showflags:
	lda	modeflags
	and	#MODEF_TURBO
	php
	ldx	#<TurboOFF_MSG
	ldy	#>TurboOFF_MSG
	plp
	beq	spsf_skp1
	ldx	#<TurboON_MSG
	ldy	#>TurboON_MSG
spsf_skp1:
	jsr	printstr

	lda	modeflags
	and	#MODEF_VERIFY
	php
	ldx	#<VerifyOFF_MSG
	ldy	#>VerifyOFF_MSG
	plp
	beq	spsf_skp2
	ldx	#<VerifyON_MSG
	ldy	#>VerifyON_MSG
spsf_skp2:
	jsr	printstr
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
TurboON_MSG:
	dc.b	19,13,13,13,13,13,13,13
	dc.b	"dISKTURBO on.  ",0
TurboOFF_MSG:
	dc.b	19,13,13,13,13,13,13,13
	dc.b	"dISKTURBO off. ",0
VerifyON_MSG:
	dc.b	"  vERIFY on. ",0
VerifyOFF_MSG:
	dc.b	"  vERIFY off.",0
exit_MSG:
	dc.b	"RESTART DISKSLAVE WITH ",34,"SYS2069",34,".",13,0
Startup_MSG:
	dc.b	147,8,14	;HOME, No togglecase, UPPERCASE
	dc.b	"dISKSLAVE "
	verrev
	dc.b	" "
	date
	dc.b	13
	dc.b	"sERIAL dISK sERVER BY dANIEL kAHLIN.",13
	dc.b	"eMAIL: <TLR@STACKEN.KTH.SE>",13
	dc.b	"tRACK CODE BY pER aNDREAS aNDERSSON.",13
	dc.b	13
	dc.b	"bUFFER: $3000-$fff8 (209 BLOCKS)",13
	IFCONST	PAL
	dc.b	"sPEED: 38400 8n2 (pal VERSION)",13
	ENDIF
	IFCONST	NTSC
	dc.b	"sPEED: 38400 8n2 (ntsc VERSION)",13
	ENDIF
	dc.b	13
	dc.b	13
	dc.b	"<t> TOGGLE DISKTURBO ON/OFF",13
	dc.b	"<v> TOGGLE VERIFY ON/OFF",13
	dc.b	"<x> EXIT TO basic",13
	dc.b	"<spacebar> ENTERS SERVER MODE",0


;**************************************************************************
;**
;** Buffers
;**
;******
BUFFER		EQU	$2f00
FileBufferStart	EQU	$3000	;.
FileBufferEnd	EQU	$fff8

