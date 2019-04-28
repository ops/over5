
;**************************************************************************
;**
;** cs_main.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

CARTRIDGE	EQU	1

	seg	code

	INCLUDE	cs_mem.i
	INCLUDE	cs_rev.i
	INCLUDE libdef.i
	INCLUDE macros.i
	INCLUDE	protocol.i
	INCLUDE	bl_mem.i

C_CTRL0	EQU	$de00
C_CTRL1	EQU	$de01
C_BANK	EQU	$de02


cart_checkromplace	EQU	$0110
jmpstore		EQU	$010e
	org	$8000
	
;**************************************************************************
;**
;** Cartridge init 
;**
;******
	dc.w	Reset			;Reset!
	dc.w	NMI			;Normal NMI
	dc.b	$c3,$c2,$cd,$38,$30	;CBM80

Jumptable:
Reset:
	jmp	ResetEntry
NMI:
	jmp	ResetEntry

;**************************************************************************
;**
;** Modules
;**
;******
	INCLUDE	pr_memtransfer.asm
	INCLUDE	pr_filetransfer.asm
	INCLUDE	pr_test.asm
	INCLUDE	pr_support.asm
	INCLUDE	bl_block.asm
	INCLUDE	dsk_disk.asm
	INCLUDE	pr_rawdisktransfer.asm



;**************************************************************************
;**
;** Start of the program! 
;**
;******
ResetEntry:
	sei
	ldx	#8
	stx	$d016
	ldx	#$fa
	txs		;FixaStack
;* Init IO (sets $dc00=$7f) *
	jsr	$fda3		;IOINIT
	lda	#$0b
	sta	$d011	;Blankaskärm
	lda	#$06
	sta	$d020	;Blååååå.

	lda	#MODEF_TURBO|MODEF_ROM
	sta	modeflags


;* Experimental *
	jsr	FixDF00


;* Go to monitor if CTRL is pressed *
	lda	$dc01
	and	#%00000100
	beq	re_DoMonitor

;* Do Reset if C= key is pressed *
	lda	$dc01
	and	#%00100000
	beq	re_DoReset

;* Go to menu if <- is pressed *
	lda	$dc01
	and	#%00000010
	beq	re_DoMenu

;* no special keys! run server *
	jmp	TheServer





;**************************************************************************
;**
;** FixDF00
;**
;******
FixDF00:
	lda	#$7e+$80
	sta	C_BANK
	ldx	#0
fd_lp1:
	lda	TheTail,x
	sta	$df00,x
	inx
	bne	fd_lp1
	lda	#$7e
	sta	C_BANK
	rts

;**************************************************************************
;**
;** Do Monitor! 
;**
;******
re_DoMonitor:

	jmp	ROM_GOMONITOR



;**************************************************************************
;**
;** Do Menu! 
;**
;******
re_DoMenu:
	ldx	#$ff
	txs
	lda	modeflags
	pha
	jsr	SystemInit
	pla
	sta	modeflags

	jmp	TheMenu


;**************************************************************************
;**
;** Do Normal reset! 
;**
;******
re_DoReset:
	ldx	#$ff
	txs
	lda	modeflags
	and	#MODEF_ROM
	php
	jsr	SystemInit

;*** set memory limits ***
	plp
	bne	dr_skp1
	ldx	#$00
	ldy	#$80
	jsr	$fd8c	;Set MemBounds
	jmp	$fcfb

;* running in cartridge *
dr_skp1:
;*** switch out cartridge ***
	ldx	#$fb	
	ldy	#$fc
	stx	jmpstore
	sty	jmpstore+1
;*** do basic reset... and exit ***
	jmp	ROM_SWITCHOUTJMP





;**************************************************************************
;**
;** Start of the program! 
;**
;******
TheServer:
	ldx	#$ff
	txs
	lda	modeflags
	pha
	jsr	SystemInit
	pla
	sta	modeflags

;*** show startup page ***
	jsr	InitSerial

	jsr	Server

	jsr	UninitSerial

	rts


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
	lda	BUFFER
	cmp	#TYPE_DISKCOMMAND
	beq	sv_disk
	lda	BUFFER
	cmp	#TYPE_RAWDISKTRANSFER
	beq	sv_rawdisk
	lda	BUFFER
	cmp	#TYPE_TESTCOMMAND
	beq	sv_test
	lda	BUFFER
	cmp	#TYPE_MEMTRANSFER
	beq	sv_mem

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
;*** handle filerequest ***
sv_rawdisk:
	jsr	RawdiskTransfer
	jmp	sv_lp1

;*** handle testrequest ***
sv_test:
	jsr	TestCommand
	jmp	sv_lp1
;*** handle memoryrequest ***
sv_mem:
	jsr	MemTransfer
	jmp	sv_lp1


;**************************************************************************
;**
;** Startpage
;**
;******
SystemInit:
;*** Do systeminitialization! ***
	sei
	cld
	jsr	$fda3	;Init interrupts /d418=0

;*** $fd50 Init Memory Subst ***
	lda	#0
	tay
sa_lp1:
	sta	$0002,y
	sta	$0200,y
	sta	$0300,y
	iny
	bne	sa_lp1

	ldx	#$03
	lda	#$3c
	sta	$b2
	stx	$b3

	ldx	#$00
	ldy	#$a0
	jsr	$fd8c	;Set MemBounds


;*** $fd15 Init Vectors subst ***
	ldy	#$1f
sa_lp2:
	lda	$fd30,y
	sta	$0314,y
	dey
	bpl	sa_lp2

;*** Init VideoChip ***
	jsr	$ff5b	;Init video

	cli

;*** Initiera diverse ***
	jsr	$ffcc	;CLRCH
	lda	#0
	sta	$13	;Keyb input
	jsr	$ff90	;Program mode
	rts

;**************************************************************************
;**
;** TheMenu
;**
;******
TheMenu:
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
sp_lp1:
	jsr	$ffe4
	cmp	#" "
	beq	sp_server
	cmp	#"B"
	beq	sp_basic
	cmp	#"N"
	beq	sp_basicNormal
	cmp	#"M"
	beq	sp_monitor
	cmp	#"T"
	beq	sp_toggleturbo
	cmp	#"F"
	beq	sp_flushmem
	jmp	sp_lp1

;* run the server *
sp_server:
	jsr	WaitKeyRelease
	jmp	TheServer

;* run basic with extra commands *
sp_basic:
	jsr	WaitKeyRelease
	jmp	re_DoReset
;* run monitor *
sp_monitor:
	jsr	WaitKeyRelease
	jmp	re_DoMonitor
;* run basic normal *
sp_basicNormal:
	jsr	WaitKeyRelease
	jmp	re_DoReset

;* toggleturboflag *
sp_toggleturbo:
	lda	modeflags
	eor	#MODEF_TURBO
	sta	modeflags
	jmp	sp_lp2

;* flushmem *
sp_flushmem:
	sei
	inc	$d020
	ldx	#$33
	stx	$01

	ldy	#0
	sty	currzp
	lda	#$08
	sta	currzp+1
	tya
sfm_lp1:
	sta	(currzp),y
	iny
	bne	sfm_lp1
	inc	currzp+1
	bne	sfm_lp1

	ldx	#$37
	stx	$01

	dec	$d020
	cli
	jmp	TheMenu


WaitKeyRelease:
wkr_lp1:
	lda	197
	cmp	#$40
	bne	wkr_lp1
	rts


;**************************************************************************
;**
;** Show state of flags
;**
;******
sp_showflags:
	ldx	#<TurboOFF_MSG
	ldy	#>TurboOFF_MSG
	lda	modeflags
	and	#MODEF_TURBO
	beq	spsf_skp1
	ldx	#<TurboON_MSG
	ldy	#>TurboON_MSG
spsf_skp1:
	jmp	printstr




;**************************************************************************
;**
;** Code below may NOT at all use basic routines!!!!!!!!
;**
;******




;**************************************************************************
;**
;** Print a str
;** X,Y=PTR
;******
printstr:
	lda	#%0010
	sta	C_CTRL0

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
	lda	#%0000
	sta	C_CTRL0

	rts



;**************************************************************************
;**
;** Tail
;**
;******
TheTail:
	RORG	$df00
ROM_SWITCHOUTJMP:
	lda	#%0001
	sta	C_CTRL0
	jmp	(jmpstore)
ROM_GOMONITOR:
	sei
	lda	#%0100
	sta	C_CTRL0
	jmp	($8000)
	dc.b	"THE TAIL"
	REND

;**************************************************************************
;**
;** Startpage MESSAGES
;**
;******
TurboON_MSG:
	dc.b	19,13,13,13,13,13,13,13
	dc.b	"dISKTURBO enabled. ",0
TurboOFF_MSG:
	dc.b	19,13,13,13,13,13,13,13
	dc.b	"dISKTURBO disabled.",0

Startup_MSG:
	dc.b	147,8,14	;HOME, No togglecase, UPPERCASE
	dc.b	"cARTSLAVE "
	verrev
	dc.b	" "
	date
	dc.b	13
	dc.b	"sERIAL cART sERVER BY dANIEL kAHLIN.",13
	dc.b	"eMAIL: <TLR@STACKEN.KTH.SE>",13
	dc.b	"tRACK CODE BY pER aNDREAS aNDERSSON.",13
	dc.b	13
	dc.b	"bUFFER: $0334-$ffff (254 BLOCKS)",13
	IFCONST	PAL
	dc.b	"sPEED: 38400 8n2 (pal VERSION)",13
	ENDIF
	IFCONST	NTSC
	dc.b	"sPEED: 38400 8n2 (ntsc VERSION)",13
	ENDIF
	dc.b	13
	dc.b	13
	dc.b	"<t> TOGGLE DISKTURBO ON/OFF",13
	dc.b	"<b> EXITS TO BASIC WITH EXTRA COMMANDS",13
	dc.b	"<n> EXITS TO NORMAL BASIC",13
	dc.b	"<m> GOES TO MONITOR",13
	dc.b	"<f> FLUSH MEM $0800-$ffff",13
	dc.b	"<spacebar> ENTERS SERVER MODE",0

