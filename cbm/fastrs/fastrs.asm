;**************************************************************************
;**
;** FILE  fastrs.asm
;** Copyright (c) 1995, 1996, 2002 Daniel Kahlin <daniel@kahlin.net>
;** Written by Daniel Kahlin <daniel@kahlin.net>
;** $Id: fastrs.asm,v 1.8 2002/11/17 02:01:54 tlr Exp $
;**
;** FastRS - (for serialcable)		38400 8N2
;** (conforms to the Over5 SIMPLEREAD/SIMPLEWRITE protocol)
;**
;** HISTORY:
;**  1.0  (950530) tlr - First real version
;**  1.1  (950531) tlr - Added restorekey!
;**  1.2  (950531) tlr - New version of the protocol!
;**  1.3  (950709) tlr - PAL/NTSC support.
;**  1.14 (960118) tlr - VIC-20 support (experimental 16KB only)
;**  1.21 (960120) tlr - enabled RESTORE for VIC-20.
;**  1.33 (960123) tlr - cleaned sourcecode
;**  1.35 (20020418) tlr - optimizations for the new millenium!
;**       (20020507  tlr - no more history in this file.
;**
;** SYS 700 (RECV)
;** SYS 703 (SEND)
;**
;******
	PROCESSOR 6502


; A vic20 reloc build is still a vic20 build
	IFCONST	VIC20_RELOC
VIC20	EQU	1
	ENDIF


	IFCONST	RELOC
RELOC1	EQU	$0000
	ENDIF

;**************************************************************************
;**
;** dasm -DPAL -DC64
;**
;** C64 PAL (985250 hz) 38400 8N2
;** <cycles per bit>  985250 / 38400 = 25.658
;**
;**          0     26    51    77   103   128   154   180   205   231
;** (cycles)
;**             26    25    26    26    25    26    26    25    26
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
	IFCONST	C64
	IFCONST	PAL
T1	EQU	26
T2	EQU	25
T3	EQU	26
T4	EQU	26
T5	EQU	25
T6	EQU	26
T7	EQU	26
T8	EQU	25
T9	EQU	26
	ENDIF
	ENDIF

;**************************************************************************
;**
;** dasm -DNTSC -DC64
;**
;** C64 NTSC (1022727 hz) 38400 8N2
;** <cycles per bit>  1022727 / 38400 = 26.634
;**
;**          0     27    53    80   107   133   160   186   213   240
;** (cycles)
;**             27    26    27    27    26    27    26    27    27
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
	IFCONST	C64
	IFCONST	NTSC
T1	EQU	27
T2	EQU	26
T3	EQU	27
T4	EQU	27
T5	EQU	26
T6	EQU	27
T7	EQU	26
T8	EQU	27
T9	EQU	27
	ENDIF
	ENDIF

;**************************************************************************
;**
;** dasm -DPAL -DVIC20
;**
;** VIC-20 PAL (1108405 hz) 38400 8N2
;** <cycles per bit>  1108405 / 38400 = 28.864
;**
;**          0     29    58    87   115   144   173   202   231   260
;** (cycles)
;**             29    29    29    28    29    29    29    29    29
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
	IFCONST	VIC20
	IFCONST	PAL
T1	EQU	29
T2	EQU	29
T3	EQU	29
T4	EQU	28
T5	EQU	29
T6	EQU	29
T7	EQU	29
T8	EQU	29
T9	EQU	29
	ENDIF
	ENDIF

;**************************************************************************
;**
;** dasm -DNTSC -DVIC20
;**
;** VIC-20 NTSC (1022727 hz) 38400 8N2
;** <cycles per bit>  1022727 / 38400 = 26.634
;**
;**          0     27    53    80   107   133   160   186   213   240
;** (cycles)
;**             27    26    27    27    26    27    26    27    27
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
	IFCONST	VIC20
	IFCONST	NTSC
T1	EQU	27
T2	EQU	26
T3	EQU	27
T4	EQU	27
T5	EQU	26
T6	EQU	27
T7	EQU	26
T8	EQU	27
T9	EQU	27
	ENDIF
	ENDIF


	INCLUDE "timing.i"

currzp		EQU	$ac
lastzp		EQU	$ae
startaddrzp	EQU	$fb
endaddrzp	EQU	$a3
stacktempzp	EQU	$fd
checksumzp	EQU	$fe
shiftregzp	EQU	$bd
tempzp		EQU	$02
ptempzp		EQU	$a5
pctempzp	EQU	$a7
slaskzp		EQU	$ff

; these are only used during the startup phase.
copysrczp	EQU	endaddrzp
copydestzp	EQU	ptempzp
reloczp		EQU	currzp
offsetzp	EQU	tempzp

	IFCONST	C64
	ORG	$0801
	ENDIF
	IFCONST	VIC20
	ORG	$1201
	ENDIF
;**************************************************************************
;**
;** Sysline
;**
;******
TOKEN_SYS	EQU	$9e
TOKEN_PEEK	EQU	$c2
TOKEN_PLUS	EQU	$aa
TOKEN_TIMES	EQU	$ac
StartOfFile:
	dc.w	EndLine
	IFCONST C64
	dc.w	2002
	dc.b	TOKEN_SYS,"2069 /T.L.R/",0
;	     2002 SYS2069 /T.L.R/
	ENDIF
	IFCONST VIC20
	IFNCONST VIC20_RELOC
	dc.w	2002
        dc.b    TOKEN_SYS,"4629 /T.L.R/",0
;            2002 SYS4629 /T.L.R/
	ELSE
	dc.w	2002
	dc.b	TOKEN_SYS,"(",TOKEN_PEEK,"(43)",TOKEN_PLUS,"256",TOKEN_TIMES,TOKEN_PEEK,"(44)",TOKEN_PLUS,"36) /T.L.R/",0
;	     2002 SYS(PEEK(43)+256*PEEK(44)+36) /T.L.R/
	ENDIF
	ENDIF
EndLine:
	dc.w	0


;**************************************************************************
;**
;** The Startup
;**
;******
SysAddress:

	IFCONST	VIC20_RELOC

; get memtop and calculate start-page
	sec
	jsr	$ff99	;MEMTOP
	tya
	sec
	sbc	#$04
	sta	offsetzp
; check that lowbyte is 0.  If it isn't allocate a page lower for us.
	txa
	beq	mt_skp1
	dec	offsetzp
mt_skp1:

; put new memtop back
	ldy	offsetzp
	ldx	#0
	clc
	jsr	$ff99	;MEMTOP

; setup pointers for relocate!
	lda	$2b
	sta	reloczp
	clc
	adc	#<[reloctable-StartOfFile]
	sta	copysrczp
	lda	$2c
	sta	reloczp+1
	adc	#>[reloctable-StartOfFile]
	sta	copysrczp+1

; relocate the actual data
	ldy	#0
rl_lp1:
	lda	(copysrczp),y
	beq	rl_done
	clc
	adc	reloczp
	sta	reloczp
	lda	reloczp+1
	adc	#0	
	sta	reloczp+1
	tya
	pha
	ldy	#0
	lda	(reloczp),y
	clc
	adc	offsetzp
	sta	(reloczp),y
	pla
	tay
	iny
	bne	rl_lp1

rl_done:

	lda	$2b
	clc
	adc	#<[[Jump_rel-1]-StartOfFile]
	sta	copysrczp
	lda	$2c
	adc	#>[[Jump_rel-1]-StartOfFile]
	sta	copysrczp+1

;*** install jumptable ***
	ldy	#Jump_end-Jump_st
sa_lp1:
	lda	(copysrczp),y
	sta	Jump_st-1,y
	dey
	bne	sa_lp1

;*** install Tranceiver ***

	lda	copysrczp
	clc
	adc	#<[Tranceiver_rel-[Jump_rel-1]]
	sta	copysrczp
	lda	copysrczp+1
	adc	#>[Tranceiver_rel-[Jump_rel-1]]
	sta	copysrczp+1
	ldx	#<Tranceiver_st
	ldy	#>Tranceiver_st
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
	cmp	#<Tranceiver_end
	bne	sa_lp2
	lda	copydestzp+1
	cmp	#>Tranceiver_end
	bne	sa_lp2

;*** Show Startup Message ***
	lda	$2b
	sta	startaddrzp
	clc
	adc	#<[Init_MSG-StartOfFile]
	tax
	lda	$2c
	sta	startaddrzp+1
	adc	#>[Init_MSG-StartOfFile]
	tay
	txa
	jsr	PrintStr
	lda	#0
	sta	endaddrzp
	lda	offsetzp
	sta	endaddrzp+1
	jsr	PrintRange
	lda	$2b
	clc
	adc	#<[Init2_MSG-StartOfFile]
	tax
	lda	$2c
	adc	#>[Init2_MSG-StartOfFile]
	tay
	txa
	jsr	PrintStr

	ELSE
;*** Show Startup Message ***
	ldx	#0
sa_lp3:
	lda.wx	Init_MSG,x
	beq	sa_skp3
	jsr	$ffd2
	inx
	bne	sa_lp3
sa_skp3:

;*** install jumptable ***
	ldx	#Jump_end-Jump_st
sa_lp1:
	lda.wx	Jump_rel-1,x
	sta	Jump_st-1,x
	dex
	bne	sa_lp1

;*** install Tranceiver ***

	ldx	#<Tranceiver_rel
	ldy	#>Tranceiver_rel
	stx	copysrczp
	sty	copysrczp+1
	ldx	#<Tranceiver_st
	ldy	#>Tranceiver_st
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
	cmp	#<Tranceiver_end
	bne	sa_lp2
	lda	copydestzp+1
	cmp	#>Tranceiver_end
	bne	sa_lp2
	ENDIF

	IFCONST	C64
;*** setup NMI vector ***
	ldx	#<Restore
	ldy	#>Restore
	stx	$fffa
	sty	$fffb
	ENDIF

;*** Exit to basic ***
	IFCONST	C64
	jsr	$a644	;NEW
	jmp	$a474	;READY (Exit to BASIC DIRECTMODE)
	ENDIF
	IFCONST	VIC20
	jsr	$c644	;NEW
	jmp	$c474	;READY (Exit to BASIC DIRECTMODE)
	ENDIF

;**************************************************************************
;**
;** The StartupMessage
;**
;******

	IFCONST	C64
Init_MSG:
;		 0000000000111111111122222222223333333333
;		 0123456789012345678901234567890123456789

	dc.b	147,142		;Cls, uppercase
	dc.b	"’√√√√√√√√√√√√√√√√√√√√√√√√√√√√√√…",13
	dc.b	"¬FASTRS/"
	dc.b	PACKAGE
	dc.b	" "
	dc.b	VERSION
	dc.b	"    "
	IFCONST	PAL
	dc.b	" C64/PAL"
	ENDIF
	IFCONST	NTSC
	dc.b	"C64/NTSC"
	ENDIF
	dc.b	"¬",13
	dc.b	"¬ COPYRIGHT (C) 1995,1996,2002 ¬",13
	dc.b	"¬            ... DANIEL KAHLIN ¬",13
	dc.b	"¬HANDLES PROGRAMS $0801-$FC00. ¬",13
	dc.b	"¬READ: SYS 700   WRITE: SYS 703¬",13
	dc.b	" √√√√√√√√√√√√√√√√√√√√√√√√√√√√√√À"
	dc.b	0
	ENDIF


	IFCONST VIC20
Init_MSG:
;		 0000000000111111111122
;		 0123456789012345678901

	dc.b	147,142		;Cls, uppercase
	dc.b	" ’¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿…",13
	dc.b	" ›FASTRS/"
	dc.b	PACKAGE
	dc.b	" "
	dc.b	VERSION
	dc.b	"›",13
	dc.b	" ›38400   "
	IFCONST	PAL
	dc.b	" VIC20/PAL"
	ENDIF
	IFCONST	NTSC
	dc.b	"VIC20/NTSC"
	ENDIF
	dc.b	"›",13
	dc.b	" ›(C) 1995,1996,2002›",13
	dc.b	" › ... DANIEL KAHLIN›",13
	dc.b	" ›HANDLES PROGRAMS  ›",13
	IFCONST VIC20_RELOC
	dc.b	" › FROM ",0
Init2_MSG:
	dc.b	".›",13
	ELSE
	dc.b	" › FROM $1201-$5C00.›",13
	ENDIF
	dc.b	" ›READ:  SYS 700    ›",13
	dc.b	" ›WRITE: SYS 703    ›",13
	dc.b	"  ¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿¿À"
	dc.b	0
	ENDIF



;**************************************************************************
;**
;** Jump table
;**
;******
Jump_rel:
	RORG	700
Jump_st:
;*** Receive Entry ***
recv:
	jmp	r
;*** Send Entry ***
send:
	sei
	IFCONST	C64
	ldx	#$35
	stx	$01
	ENDIF
	jsr	Send
	IFCONST	C64
	ldx	#$37
	stx	$01
	ENDIF
	cli
	rts
r:
	sei
	IFCONST	C64
	ldx	#$35
	stx	$01
	ENDIF
	jsr	Receive
	IFCONST	C64
	ldx	#$37
	stx	$01
	ENDIF
	cli
	rts

	IFCONST	C64
;*** Print a char ***
Pchar:
	php
	sta	pctempzp
	lda	$01
	pha
	lda	#$37
	sta	$01
	lda	pctempzp
	jsr	$ffd2	;CHROUT
	sei
	pla
	sta	$01
	lda	pctempzp
	plp
	rts
;*** Do Basic WarmStart ***
Restore:
	sei
	lda	#$37
	sta	$01
	jmp	$fe69	;Restore basic!
	ENDIF
	IFCONST	VIC20
Pchar	EQU	$ffd2	;CHROUT
	ENDIF

Jump_end:
	REND
	echo	"Jump ",Jump_st,Jump_end



;**************************************************************************
;**
;** TheTranceiver part
;**
;******
Tranceiver_rel:
	IFCONST	C64
	RORG	$fc00
	ENDIF
	IFCONST	VIC20
	IFNCONST RELOC1
	RORG	$5c00
	ELSE
	RORG	RELOC1
	ENDIF	
	ENDIF
Tranceiver_st:

;**************************************************************************
;**
;** Receiver
;**
;******
Receive:
;* preserve color
	IFCONST	C64
	lda	$d020
	pha
	ENDIF
	IFCONST	VIC20
	lda	$900f
	pha
	ENDIF

;* preserve stackpointer
	tsx
	stx	stacktempzp


	lda	#<Waiting_msg
	ldy	#>Waiting_msg
	jsr	PrintStr

	jsr	Init


	lda	#$00		;reset checksum
	sta	shiftregzp
	sta	checksumzp

	jsr	GetByte38400	;Get HEAD
	cmp	#$e7
	bne	r_fl1

	jsr	GetByte38400	;Get Start address low byte
	sta	startaddrzp
	sec
	sbc	#1
	sta	currzp
	php
	jsr	GetByte38400
	sta	startaddrzp+1	;Get Start address high byte
	plp
	sbc	#0
	sta	currzp+1

	jsr	GetByte38400	;Get End address low byte
	sta	endaddrzp
	sec
	sbc	#1
	sta	lastzp
	php
	jsr	GetByte38400	;Get End address high byte
	sta	endaddrzp+1
	plp
	sbc	#0
	sta	lastzp+1

	jsr	GetByte38400	;Get header checksum
	cmp	checksumzp
	bne	r_fl1

	lda	#$00		;reset checksum
	sta	shiftregzp
	sta	checksumzp

	jsr	GetBody38400

	jsr	GetByte38400
	pha	;checksum to stack

;*** show start and end! ***


	ldx	endaddrzp
	lda	endaddrzp+1
	stx	$ae
	sta	$af
	stx	$2d
	sta	$2e

	jsr	PrintTransferred

	pla	;checksum from stack
	eor	checksumzp
	bne	r_fl1

	lda	#<ok_msg
	ldy	#>ok_msg
	jsr	PrintStr
	jmp	r_ex1

r_fl1:
	lda	#<checksumerror_msg
	ldy	#>checksumerror_msg
	jsr	PrintStr

r_ex1:
	IFCONST	C64
	lda	#$1b
	sta	$d011
	ENDIF

;* restore stackpointer
	ldx	stacktempzp
	txs

;* restore color
	IFCONST	C64
	pla
	sta	$d020
	ENDIF
	IFCONST	VIC20
	pla
	sta	$900f
	ENDIF
	rts



;**************************************************************************
;** 
;** GETBIT macro  (11 cycles)
;**
;******
	MAC	GETBIT		;11
	IFCONST	VIC20
	lda	$9110		;4
	lsr			;2
	ror	shiftregzp	;5
	ENDIF
	IFCONST	C64
	lda	$dd01		;4
	lsr			;2
	ror	shiftregzp	;5
	ENDIF
	ENDM

;**************************************************************************
;**
;** Receive a byte	38400 8N2
;**
;******
GetByte38400:
	lda	#%00000001
gb_lp1:
	IFCONST	C64
	bit	$dd01		;4
	ENDIF
	IFCONST	VIC20
	bit	$9110		;4
	ENDIF
	bne	gb_lp1		;2

	lda	shiftregzp	;3
	eor	checksumzp	;3
	sta	checksumzp	;3

;\/ T1 cycles  (startbit)
	lda	shiftregzp	;3
	IFCONST	C64
	sta	$d020		;4
	ENDIF
	IFCONST	VIC20
	sta	$900f		;4
	ENDIF
	DELAY	T1-7

;\/ T2 cycles  (bit 1)
	GETBIT			;11
	DELAY	T2-11

;\/ T3 cycles  (bit 2)
	GETBIT			;11
	DELAY	T3-11

;\/ T4 cycles  (bit 3)
	GETBIT			;11
	DELAY	T4-11

;\/ T5 cycles  (bit 4)
	GETBIT			;11
	DELAY	T5-11

;\/ T6 cycles  (bit 5)
	GETBIT			;11
	DELAY	T6-11

;\/ T7 cycles  (bit 6)
	GETBIT			;11
	DELAY	T7-11

;\/ T8 cycles  (bit 7)
	GETBIT			;11
	DELAY	T8-11

;\/ T9 cycles  (bit 8)
	GETBIT			;11

	lda	shiftregzp	;3
	rts



;**************************************************************************
;**
;** Receive a block	38400 8N2
;**
;** $ac/$ad = start-1
;** $ae/$af = end-1
;**
;******
GetBody38400:
	ldy	#0
gbo_lp1:
	lda	#%00000001	;2
gbo_lp2:
	IFCONST	C64
	bit	$dd01		;4
	ENDIF
	IFCONST	VIC20
	bit	$9110		;4
	ENDIF
	bne	gbo_lp2		;2

	lda	shiftregzp	;3
	eor	checksumzp	;3
	sta	checksumzp	;3

;\/ T1 cycles  (startbit)
	lda	shiftregzp	;3
	IFCONST	C64
	sta	$d020		;4
	ENDIF
	IFCONST	VIC20
	sta	$900f		;4
	ENDIF
	DELAY	T1-7

;\/ T2 cycles  (bit 1)
	GETBIT			;11
	DELAY	T2-11

;\/ T3 cycles  (bit 2)
	GETBIT			;11
	DELAY	T3-11

;\/ T4 cycles  (bit 3)
	GETBIT			;11
	lda	currzp		;3
	clc			;2
	adc	#1		;2
	sta	currzp		;3
	php			;3
	DELAY	T4-24

;\/ T5 cycles  (bit 4)
	GETBIT			;11
	plp			;4
	lda	currzp+1	;3
	adc	#0		;2
	sta	currzp+1	;3
	DELAY	T5-23

;\/ T6 cycles  (bit 5)
	GETBIT			;11
	sec			;2
	lda	currzp		;3
	sbc	lastzp		;3
	php			;3
	DELAY	T6-22

;\/ T7 cycles  (bit 6)
	GETBIT			;11
	plp			;4
	lda	currzp+1	;3
	sbc	lastzp+1	;3
	php			;3
	DELAY	T7-24

;\/ T8 cycles  (bit 7)
	GETBIT			;11
	IFCONST	C64
	DELAY	T8-13
	ldx	#$34		;2
	ENDIF
	IFCONST	VIC20
	DELAY	T8-11
	ENDIF

;\/ T9 cycles  (bit 8)
	GETBIT			;11
	IFCONST	C64
	stx	$01		;3
	ENDIF
	IFCONST	VIC20
	DELAY	3		;3
	ENDIF
	lda	shiftregzp	;3
	sta	(currzp),y	;6
	IFCONST	C64
	ldx	#$35		;2
	stx	$01		;3
	ENDIF
	IFCONST	VIC20
	DELAY	5		;5
	ENDIF
	plp			;4
	bcs	gbo_ex1		;2
	jmp	gbo_lp1		;3
gbo_ex1:
	rts


;**************************************************************************
;**
;** Timing!
;**
;******


Twentythree:
	nop		;2
Twentyone:
	nop		;2
Nineteen:
	nop		;2
Seventeen:
	nop		;2
Fifteen:
	sta	slaskzp	;3
	rts

Twentytwo:
	nop		;2
Twenty:
	nop		;2
Eighteen:
	nop		;2
Sixteen:
	nop		;2
Fourteen:
	nop		;2
Twelve:
	rts


;**************************************************************************
;**
;** Initialize ports!
;**
;******
Init:
	sei

	IFCONST	C64
	lda	#%01111111
	sta	$dd0d	;no CIA#2 NMI interrupts
	lda	$dd0d
	ENDIF
	IFCONST	VIC20
;	lda	#%01111111
;	sta	$911e	;no VIA#1 NMI interrupts
;	sta	$911d
	ENDIF

	IFCONST	C64
	lda	$dd02	
	ora	#%00000100
	sta	$dd02	;RS232 Data dir (bit 2=TxD)
	lda	#%00000110
	sta	$dd03	;RS232 Data dir (bit 0=RxD)
	ENDIF
	IFCONST	VIC20
	lda	#%00000110
	sta	$9112	;RS232 Data dir (bit 0=RxD)
	ENDIF

	IFCONST	C64
	lda	$dd00	;set Txd HI
	and	#%11111011
	ora	#%00000100
	sta	$dd00
	ENDIF
	IFCONST	VIC20
	lda	$911c	;set Txd HI
	ora	#%11100000
	sta	$911c
	ENDIF

	IFCONST C64
	lda	#%00001000
	sta	$dd0e	;Timer off
	lda	#%00001000
	sta	$dd0f	;Timer off
	ENDIF

	IFCONST	C64
	ldy	#255
	ldx	#0
i_lp1:
	inx
	bne	i_lp1
	dey
	bne	i_lp1
	
	jmp	BlankScreen
	ENDIF
	IFCONST	VIC20
	rts
	ENDIF


	IFCONST	C64
;**************************************************************************
;**
;** Blank the screen
;**
;******
BlankScreen:
	lda	#%00000000
	sta	$d015	;No sprites
	lda	#$0b
	sta	$d011	;No screen

;*** wait 3 frames for good measure ***
	ldx	#3
bs_lp1:
bs_lp2:
	lda	$d011
	bpl	bs_lp2
bs_lp3:
	lda	$d011
	bmi	bs_lp3
	dex
	bne	bs_lp1
	rts
	ENDIF

;**************************************************************************
;**
;** Print info about transfer
;**
;******
PrintTransferred:
	lda	#<transferred_msg
	ldy	#>transferred_msg
	jsr	PrintStr

PrintRange:
	lda	#"$"
	jsr	Pchar
	lda	startaddrzp+1
	jsr	PrintHex
	lda	startaddrzp
	jsr	PrintHex
	lda	#"-"
	jsr	Pchar
	lda	#"$"
	jsr	Pchar
	lda	endaddrzp+1
	jsr	PrintHex
	lda	endaddrzp
	jmp	PrintHex
	
;**************************************************************************
;**
;** Printstr
;** Acc,Y=address
;**
;******
PrintStr:
	sta	ptempzp
	sty	ptempzp+1
	ldy	#0
ps_lp1:
	lda	(ptempzp),y
	beq	ps_ex1
	jsr	Pchar
	iny
	jmp	ps_lp1
ps_ex1:
	rts


;**************************************************************************
;**
;** PrintHex
;** Acc=byte
;**
;******
PrintHex:
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	ph_skp1
	pla
ph_skp1:
	and	#$0f
	tax
	lda	hex_msg,x
	jmp	Pchar

;**************************************************************************
;**
;** Strings
;**
;******
Waiting_msg:
	dc.b	"WAITING...",0
Sending_msg:
	dc.b	"SENDING...",0
ok_msg:
	dc.b	13,"CHECKSUM OK!",0
checksumerror_msg:
	dc.b	13,"?CHECKSUM ERROR",0
transferred_msg:
	IFCONST C64
	dc.b	13,"TRANSFERRED: ",0
	ENDIF
	IFCONST VIC20
	dc.b	13,"TRANSFER: ",0
	ENDIF
hex_msg:
	dc.b	"0123456789ABCDEF"



;**************************************************************************
;**
;** Sender
;**
;******
Send:
;* preserve color
	IFCONST	C64
	lda	$d020
	pha
	ENDIF
	IFCONST	VIC20
	lda	$900f
	pha
	ENDIF

;* preserve stackpointer
	tsx
	stx	stacktempzp

	lda	#<Sending_msg
	ldy	#>Sending_msg
	jsr	PrintStr

	jsr	Init


	lda	#$00		;reset checksum
	sta	shiftregzp
	sta	checksumzp

	lda	#$e7
	jsr	SendByte38400	;Send HEAD
	lda	$2b
	sta	currzp
	sta	startaddrzp
	jsr	SendByte38400	;Send Start Ad low
	lda	$2c
	sta	currzp+1
	sta	startaddrzp+1
	jsr	SendByte38400	;Send Start Ad high
	lda	$2d
	sta	lastzp
	sta	endaddrzp
	jsr	SendByte38400	;Send End Ad low
	lda	$2e
	sta	lastzp+1
	sta	endaddrzp+1
	jsr	SendByte38400	;Send End Ad high

	lda	checksumzp
	jsr	SendByte38400	;Send Header checksum


	lda	#$00		;reset checksum
	sta	shiftregzp
	sta	checksumzp

;*** send body ***
	ldy	#0
s_lp1:
	IFCONST	C64
	ldx	#$34		;2
	stx	$01		;3
	ENDIF
	lda	(currzp),y	;5*
	IFCONST	C64
	ldx	#$35		;2
	stx	$01		;3
	ENDIF
	jsr	SendByte38400	;12
	inc	currzp		;5
	bne	s_skp1		;3
	inc	currzp+1
s_skp1:
	sec			;2
	lda	currzp		;3
	sbc	lastzp		;3
	lda	currzp+1	;3
	sbc	lastzp+1	;3
	bcc	s_lp1		;3

	lda	checksumzp
	jsr	SendByte38400		;Send body checksum

	IFCONST	C64
	lda	#$1b
	sta	$d011
	ENDIF
	jsr	PrintTransferred

;* restore stackpointer
	ldx	stacktempzp
	txs

;* restore color
	IFCONST	C64
	pla
	sta	$d020
	ENDIF
	IFCONST	VIC20
	pla
	sta	$900f
	ENDIF

	rts



;**************************************************************************
;** 
;** SENDBIT macro  (20 cycles)
;**
;******
	MAC	SENDBIT		;20
	IFCONST	VIC20
	sta	$911c		;4
	lda	#0		;2
	lsr	shiftregzp	;5
	ror			;2
	ror			;2
	ror			;2
	ora	tempzp		;3
	ENDIF
	IFCONST	C64
	sta	$dd00		;4
	lda	#0		;2
	lsr	shiftregzp	;5
	rol			;2
	rol			;2
	rol			;2
	ora	tempzp		;3
	ENDIF
	ENDM

;**************************************************************************
;** 
;** Send a byte	38400 8N2
;**
;******
SendByte38400:
	sta	shiftregzp	;3
	IFCONST	C64
	sta	$d020		;4
	ENDIF
	IFCONST	VIC20
	sta	$900f		;4
	ENDIF
	eor	checksumzp	;3
	sta	checksumzp	;3


	IFCONST	C64
	lda	$dd00		;4
	and	#%11111011	;2
	ENDIF
	IFCONST	VIC20
	lda	$911c		;4
	and	#%11011111	;2
	ENDIF
	sta	tempzp		;3

;\/ T1 cycles  (startbit)
	SENDBIT			;20
	DELAY	T1-20

;\/ T2 cycles  (bit 1)
	SENDBIT			;20
	DELAY	T2-20

;\/ T3 cycles  (bit 2)
	SENDBIT			;20
	DELAY	T3-20

;\/ T4 cycles  (bit 3)
	SENDBIT			;20
	DELAY	T4-20

;\/ T5 cycles  (bit 4)
	SENDBIT			;20
	DELAY	T5-20

;\/ T6 cycles  (bit 5)
	SENDBIT			;20
	DELAY	T6-20

;\/ T7 cycles  (bit 6)
	SENDBIT			;20
	DELAY	T7-20

;\/ T8 cycles  (bit 7)
	SENDBIT			;20
	DELAY	T8-20

;\/ T9 cycles  (bit 8)
	IFCONST	C64
	sta	$dd00		;4
	ENDIF
	IFCONST	VIC20
	sta	$911c		;4
	ENDIF

	lda	tempzp		;3
	IFCONST	C64
	ora	#%00000100	;2
	ENDIF
	IFCONST	VIC20
	ora	#%00100000	;2
	ENDIF
	DELAY	T9-9

;\/ 52 cycles (2 stopbits)
	IFCONST	C64
	sta	$dd00		;4
	ENDIF
	IFCONST	VIC20
	sta	$911c		;4
	ENDIF
	jsr	Fourteen	;14
	jsr	Fourteen	;14
	jsr	Fourteen	;14
	jsr	Fourteen	;14

	jsr	Fourteen	;14

	rts


Tranceiver_end:
	REND
	echo	"Tranceiver ",Tranceiver_st,Tranceiver_end

	IFCONST	VIC20_RELOC
reloctable:
	IFCONST RELOC
	INCBIN	"reloc_tmp"
	ENDIF
	ENDIF
; eof
