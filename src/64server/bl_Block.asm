;**************************************************************************
;**
;** bl_Block.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;** blocktransfer routines for serialcable 38400 8N2
;**
;******

;**************************************************************************
;**
;** InitSerial
;** (initialize all serial stuff and blank screen)
;**
;******
;** ReadBlock, ReadBlockLong
;** (Read a block)
;** IN: Acc=Initial timeout (0=no timeout) bl_currzp=BUFFER
;** UT: bl_channelzp=CHANNEL, bl_blocksizezp=BLOCKSIZE, Carry=status(0=ok)
;**
;******
;** WriteBlock
;** (Write a block)
;** IN: bl_currzp=BUFFER, bl_channelzp=CHANNEL, bl_blocksizezp=BLOCKSIZE
;** UT: Carry=status(0=ok)
;**
;******




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
;	IFCONST	C64
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
;	ENDIF

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
;	IFCONST	C64
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
;	ENDIF



	INCLUDE timing.i


;NOTIMEOUT	EQU	0

	IFNCONST	UNDERKERNAL
NORMALMEM	EQU	$37
	ELSE
NORMALMEM	EQU	$35
	ENDIF

HEAD		EQU	$7e
ST_MASK		EQU	$f0
ST_OK		EQU	$10
ST_RESEND	EQU	$20

RETRIES		EQU	3



TIMEOUTSHORT	EQU	12	;0.8 s
TIMEOUTLONG	EQU	480	;30 s

TIMERA		EQU	$ffff
TIMERB		EQU	$3

;**************************************************************************
;**
;** Read a block	38400 8N2
;**
;** IN: Acc=Initial timeout (0=no timeout) bl_currzp=BUFFER
;** UT: bl_channelzp=CHANNEL, bl_blocksizezp=BLOCKSIZE, Carry=status(0=ok)
;** 
;******
ReadBlockNoTimeout:
	jsr	ShortTimeout
	lda	#$00
	sta	bl_timeoutzp
	IFNCONST NOCOLOR
	lda	#STANDBYCOLOR
	sta	$d020
	ENDIF
	IFNCONST NOTIMEOUT
	lda	#%01011001	;oneshot count timer A 0's
	sta	$dc0f
	ENDIF
	jmp	rdb_skp2

ReadBlockLong:
	jsr	LongTimeout
	jmp	rdb_skp3
ReadBlock:
	jsr	ShortTimeout
rdb_skp3:
	lda	#$ff
	sta	bl_timeoutzp
	IFNCONST NOCOLOR
	lda	$d020
	and	#$08
	eor	#$08
	ora	#READCOLOR
	sta	$d020
	ENDIF
rdb_skp2:
	tsx
	stx	bl_timeoutstack
	lda	#<rdb_timeout
	sta	bl_timeoutroutine
	lda	#>rdb_timeout
	sta	bl_timeoutroutine+1


	lda	#RETRIES
	sta	bl_retries
rdb_lp1:
	lda	#ERR_NONE	;NO ERRORS (yet!)
	sta	bl_errorzp

	lda	bl_timeoutzp
	beq	rdb_skp1
	IFNCONST NOTIMEOUT
	jsr	SetTimeout
	ENDIF
rdb_skp1:
	jsr	ReceiveBlock
	bcc	rdb_ex1
	lda	#ST_RESEND
	jsr	SendAck

	lda	#ERR_FAILED
	sta	bl_errorzp

	lda	#$ff
	sta	bl_timeoutzp
	jsr	ClearTimeout

rdb_timeout:
	jsr	ShortTimeout

	dec	bl_retries
	bne	rdb_lp1

;* exit FAIL
	sec
	rts

;* exit OK
rdb_ex1:
	jsr	ClearTimeout
	lda	#ST_OK
	jsr	SendAck
	clc
	rts


;**************************************************************************
;**
;** Write a block	38400 8N2
;**
;** IN: bl_currzp=BUFFER, bl_channelzp=CHANNEL, bl_blocksizezp=BLOCKSIZE
;** UT: Carry=status(0=ok)
;**
;******
WriteBlock:
	jsr	ShortTimeout
	IFNCONST NOCOLOR
	lda	$d020
	and	#$08
	eor	#$08
	ora	#WRITECOLOR
	sta	$d020
	ENDIF

	inc	bl_sendblocknumzp
	lda	bl_sendblocknumzp
	and	#$0f
	sta	bl_sendblocknumzp

	tsx
	stx	bl_timeoutstack
	lda	#<wrb_timeout
	sta	bl_timeoutroutine
	lda	#>wrb_timeout
	sta	bl_timeoutroutine+1

	lda	#RETRIES
	sta	bl_retries
wrb_lp1:
	lda	#ERR_NONE
	sta	bl_errorzp		;set error to none

	IFNCONST NOTIMEOUT
	jsr	SetTimeout
	ENDIF
	jsr	SendBlock
	jsr	CheckAck
	jsr	ClearTimeout
	cmp	#ST_OK
	beq	wrb_ex1

	lda	#ERR_FAILED
	sta	bl_errorzp

wrb_timeout:
	jsr	ShortTimeout
	dec	bl_retries
	bne	wrb_lp1

;* exit FAIL
	sec
	rts

;* exit OK
wrb_ex1:
	clc
	rts


;**************************************************************************
;**
;** Send a block	38400 8N2
;**
;******
SendBlock:
	lda	#$00
	sta	bl_shiftregzp
	sta	bl_checksumzp

;*** send header ****
	lda	#HEAD
	jsr	SendByte38400

;*** send channel ***
	lda	bl_channelzp
	and	#$0f
	jsr	SendByte38400

;*** block number ***
	lda	bl_sendblocknumzp
	jsr	SendByte38400

;*** block size ***
	lda	bl_blocksizezp
	jsr	SendByte38400

;*** header checksum ***
	lda	bl_checksumzp
	jsr	SendByte38400

	ldy	#$00
	sty	bl_shiftregzp
	sty	bl_checksumzp
;*** get body ***
sb_lp1:
	sei
	IFNCONST CARTRIDGE
	ldx	#$34
	stx	$01
	lda	(bl_currzp),y
	ldx	#NORMALMEM
	stx	$01
	ELSE
	jsr	blk_getmem
	ENDIF
	cli
	jsr	SendByte38400	
	iny
	cpy	bl_blocksizezp
	bne	sb_lp1

;*** body checksum ***
	lda	bl_checksumzp
	jsr	SendByte38400


	rts

;**************************************************************************
;**
;** check acknowledge	38400 8N2
;**
;** UT: Acc=type (ST_OK or ST_RESEND)
;**
;******
CheckAck:
	lda	#$00
	sta	bl_shiftregzp
	sta	bl_checksumzp

;*** check header ****
	jsr	GetByte38400
	cmp	#HEAD
	bne	ca_fl1	;!!no header!!

;*** block type ***
	jsr	GetByte38400
	tax
	and	#$0f
	cmp	bl_channelzp
	bne	ca_fl1	;!!wrong channel!!
	txa
	and	#$f0
	sta	bl_statuszp

;*** block number ***
	jsr	GetByte38400
	cmp	bl_sendblocknumzp
	bne	ca_fl1	;!!wrong blocknum!!

;*** block size ***
	jsr	GetByte38400
	cmp	bl_blocksizezp
	bne	ca_fl1	;!!wrong blocksize!!

;*** header checksum ***
	jsr	GetByte38400
	cmp	bl_checksumzp
	bne	ca_fl1	;!!header checksum error!!

	lda	bl_statuszp
	clc
	rts
ca_fl1:
	lda	#0
	sec
	rts


;**************************************************************************
;**
;** Receive a block	38400 8N2
;**
;******
ReceiveBlock:
	lda	#$00
	sta	bl_shiftregzp
	sta	bl_checksumzp

;*** check header ****
	jsr	GetByte38400
	cmp	#HEAD
	bne	rb_fl1	;!!no header!!

	IFNCONST NOTIMEOUT
	lda	bl_timeoutzp
	bne	rb_skp1
	lda	#%10010001	;continous count cpu cycles
	sta	$dc0e
	lda	$dc0d
rb_skp1:
	ENDIF

;*** block type ***
	jsr	GetByte38400
	sta	bl_channelzp
	and	#$f0
	bne	rb_fl1	;!!no datablock!!

;*** block number ***
	jsr	GetByte38400
	sta	bl_recvblocknumzp

;*** block size ***
	jsr	GetByte38400
	sta	bl_blocksizezp

;*** header checksum ***
	jsr	GetByte38400
	cmp	bl_checksumzp
	bne	rb_fl1	;!!header checksum error!!

	ldy	#$00
	sty	bl_shiftregzp
	sty	bl_checksumzp
;*** get body ***
rb_lp1:
	jsr	GetByte38400	
	sei
	IFNCONST CARTRIDGE
	ldx	#$34
	stx	$01
	sta	(bl_currzp),y
	ldx	#NORMALMEM
	stx	$01
	ELSE
	ldx	#$33
	stx	$01
	sta	(bl_currzp),y
	ldx	#$37
	stx	$01
	ENDIF
	cli
	iny
	cpy	bl_blocksizezp
	bne	rb_lp1

;*** body checksum ***
	jsr	GetByte38400
	cmp	bl_checksumzp
	bne	rb_fl1	;!!body checksum error!!

	clc
	rts
rb_fl1:
	sec
	rts

;**************************************************************************
;**
;** Send acknowledge	38400 8N2
;**
;** IN: Acc=type (ST_OK or ST_RESEND)
;**
;******
SendAck:
	ora	bl_channelzp
	sta	bl_statuszp

	lda	#$00
	sta	bl_checksumzp

;*** send header ***
	lda	#HEAD
	jsr	SendByte38400

;*** send channel+type ***
	lda	bl_statuszp
	jsr	SendByte38400

;*** send blocknum ***
	lda	bl_recvblocknumzp
	jsr	SendByte38400

;*** send size ***
	lda	bl_blocksizezp
	jsr	SendByte38400

;*** send checksum ***
	lda	bl_checksumzp
	jsr	SendByte38400
	rts





;**************************************************************************
;** 
;** SENDBIT macro  (20 cycles)
;**
;******
	MAC	SENDBIT		;20
	sta	$dd00		;4
	lda	#0		;2
	lsr	bl_shiftregzp	;5
	rol			;2
	rol			;2
	rol			;2
	ora	bl_tempzp	;3
	ENDM

;**************************************************************************
;** 
;** Send a byte	38400 8N2
;**
;******
SendByte38400:
	sta	bl_shiftregzp	;3
	eor	bl_checksumzp	;3
	sta	bl_checksumzp	;3
	nop			;2
	nop			;2

	lda	$dd00		;4
	and	#%11111011	;2
	sta	bl_tempzp	;3

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
	sta	$dd00		;4

	lda	bl_tempzp	;3
	ora	#%00000100	;2
	DELAY	T9-9

;\/ 52 cycles (2 stopbits)
	sta	$dd00		;4
	jsr	Fourteen	;14
	jsr	Fourteen	;14
	jsr	Fourteen	;14
	jsr	Fourteen	;14

	jsr	Fourteen	;14

	rts


;**************************************************************************
;** 
;** GETBIT macro  (11 cycles)
;**
;******
	MAC	GETBIT		;11
	lda	$dd01		;4
	lsr			;2
	ror	bl_shiftregzp	;5
	ENDM

;**************************************************************************
;**
;** Receive a byte	38400 8N2
;**
;******
GetByte38400:
	lda	#%00000001
gb_lp1:
	bit	$dd01		;4
	bne	gb_lp1		;2

	lda	bl_shiftregzp	;3
	eor	bl_checksumzp	;3
	sta	bl_checksumzp	;3

;\/ T1 cycles  (startbit)
	lda	bl_shiftregzp	;3
	DELAY	T1-3

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

	lda	bl_shiftregzp	;3
	rts



;**************************************************************************
;**
;** Timing!
;**
;******

Twentyseven:
	nop		;2
Twentyfive:
	nop		;2
Twentythree:
	nop		;2
Twentyone:
	nop		;2
Nineteen:
	nop		;2
Seventeen:
	nop		;2
Fifteen:
	bit	$ea	;3
	rts

Twentysix:
	nop		;2
Twentyfour:
	nop		;2
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
InitSerial:

	IFCONST	CARTRIDGE
	ldx	#0
isc_lp1:
	lda	blk_getmemsource,x
	sta	blk_getmem,x
	inx
	cpx	#blk_getmemend-blk_getmem
	bne	isc_lp1
	ENDIF

	sei
	lda	#$ff
	sta	bl_sendblocknumzp
	sta	bl_recvblocknumzp

;*** shutdown interrupts ***
	lda	#%00000000
	sta	$d01a	;no VIC irq

	lda	#%01111111
	sta	$dc0d	;no CIA interrupts
	lda	$dc0d

;*** timeout count ***
	lda	#%10000000	;continuos count cpu cycles
	sta	$dc0e
	lda	#%01001000	;oneshot count timer A 0's
	sta	$dc0f
	lda	#<TIMERA
	sta	$dc04
	lda	#>TIMERA
	sta	$dc05
	jsr	ShortTimeout
	lda	#%10000010
	sta	$dc0d		;Enable timer B int
	lda	$dc0d

;*** set interrupt vectors ***
	lda	$0314
	sta	bl_irqstore
	lda	$0315
	sta	bl_irqstore+1
	lda	#<TimeoutServer
	sta	$0314
	lda	#>TimeoutServer
	sta	$0315

	lda	#%01111111
	sta	$dd0d	;no CIA interrupts
	lda	$dd0d

	lda	$dd02	
	ora	#%00000100
	sta	$dd02	;RS232 Data dir

	lda	#%00000110
	sta	$dd03	;RS232 Data dir

	lda	$dd00
	and	#%11111011
	ora	#%00000100
	sta	$dd00

	lda	#%00001000
	sta	$dd0e	;Timer off
	lda	#%00001000
	sta	$dd0f	;Timer off

;*** done ... safe to turn on interrupts ***
	cli

	jmp	BlankScreen

;**************************************************************************
;**
;** Initialize ports!
;**
;******
UninitSerial:
	lda	#$1b	;unblank screen
	sta	$d011
UninitSerialSmall:
	lda	bl_irqstore	;restore IRQ
	sta	$0314
	lda	bl_irqstore+1
	sta	$0315
	IFNCONST UNDERKERNAL
	jsr	$fda3
	ELSE
	sei
	jsr	newfda3
	ENDIF
	IFNCONST NOCOLOR
	lda	#OUTCOLOR
	sta	$d020
	ENDIF
	rts

;**************************************************************************
;**
;** ShortTimeout
;**
;******
ShortTimeout:
	lda	#<TIMEOUTSHORT
	sta	$dc06
	lda	#>TIMEOUTSHORT
	sta	$dc07
	rts

;**************************************************************************
;**
;** LongTimeout
;**
;******
LongTimeout:
	lda	#<TIMEOUTLONG
	sta	$dc06
	lda	#>TIMEOUTLONG
	sta	$dc07
	rts


;**************************************************************************
;**
;** SetTimeout
;**
;******
SetTimeout:
	pha
	sei
	lda	#%10010001	;continous count cpu cycles
	sta	$dc0e
	lda	#%01011001	;oneshot count timer A 0's
	sta	$dc0f
	lda	$dc0d
	cli
	pla
	rts

;**************************************************************************
;**
;** ClearTimeout
;**
;******
ClearTimeout:
	php
	pha
	sei
	lda	#%10000000	;continous count cpu cycles
	sta	$dc0e
	lda	#%01001000	;oneshot count timer A 0's
	sta	$dc0f
	lda	$dc0d
	cli
	pla
	plp
	rts

;**************************************************************************
;**
;** Timeout interruptserver
;**
;******
TimeoutServer:
	lda	$dc0d
	ldx	bl_timeoutstack
	txs
	jsr	ClearTimeout
	cli
	IFNCONST NOCOLOR
	ldy	$d020
	lda	#TIMEOUTCOLOR
	sta	$d020
	jsr	FrameWait
	sty	$d020
	ENDIF
	lda	#ERR_TIMEOUT		;Tell that we timed out!
	sta	bl_errorzp
	jmp	(bl_timeoutroutine)


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
	jmp	FrameWait



;**************************************************************************
;**
;** Wait for blank
;**
;******
FrameWait:
	sei
;*** wait 3 frames for good measure ***
	ldx	#3
fw_lp1:
fw_lp2:
	lda	$d011
	bpl	fw_lp2
fw_lp3:
	lda	$d011
	bmi	fw_lp3
	dex
	bne	fw_lp1
	cli
	rts


	IFCONST	CARTRIDGE
;**************************************************************************
;**
;** Special get memory routine
;******
blk_getmemsource:
	RORG	blk_getmemplace
	ECHO	"blk_getmem... ",.
blk_getmem:
	ldx	#$34
	stx	$01
	lda	(bl_currzp),y
	ldx	#$37
	stx	$01
	rts
	ECHO	"... ",.
blk_getmemend:
	REND
	ENDIF

