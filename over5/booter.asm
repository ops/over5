
;**************************************************************************
;**
;** booter.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

;zeropage definitions
currzp		EQU	$fb	;WORD
destzp		EQU	$ae	;WORD
relzp		EQU	$fd	;WORD
jmpaddr		EQU	$0110	;WORD
rtsaddr		EQU	$0110	;BYTE
ytmp		EQU	$ac	;BYTE
checksumzp	EQU	$ad	;BYTE
codezp		EQU	$ac	;BYTE


HASH_DISTANCE	EQU	32

	org	$4711	;should not matter at all
booter_start:

;**************************************************************************
;**
;** unstuffer 
;** Fully relocatable & machine independant code.
;**
;******
unstuffer:
;***
;*** do unstuffing of code
;*** this code may not contain any zeroes!!!
;***
	sei
	lda	#$ff	;MUST be! code is inserted here by Over5
	sta	codezp
;*
;* special code for relative addressing 
;* fucks up if NMI occurs somewhere
;*
	lda	#$60
	sta	rtsaddr
	jsr	rtsaddr
reladdrstuffer:
	tsx
	dex
	dex
	lda.wx	[$0100+1],x
	clc
	adc	#booterstuff_OFFSET
	sta	currzp
	lda.wx	[$0100+2],x
	sta	currzp+1
	bcc	us_skp4
	inc	currzp+1
us_skp4:

;*
;* decide where to put the code.
;* always put us at MEMTOP-$420 (should work on most cbm machines)
;* When RS-232 is opened later on kernal lowers MEMTOP automatically
;* to provide space for buffers (512 bytes).  We ourselves take $200
;* bytes. $20 extra is for good measure
;*
SPACE	EQU	$0420

	sec
	jsr	$ff99	;MEMTOP
	txa
	sec
	sbc	#<SPACE
	sta	destzp
	sta	jmpaddr
	tya
	sbc	#>SPACE
	sta	destzp+1
	sta	jmpaddr+1

	ldx	#2	;number of pages

	ldy	#1	;y=0
	dey
;*
;* the unstuff loop
;*
us_lp1:
	lda	(currzp),y
	cmp	codezp
	bne	us_skp1
	sec
	sbc	codezp	;A=0 without any zeros.
us_skp1:
	sta	(destzp),y

	iny
	bne	us_lp1
	inc	currzp+1
	inc	destzp+1
	dex
	bpl	us_lp1
	
	jmp	(jmpaddr)

;***
;*** stuff tag!  MUST be here!  Tells Over5 to start stuffing after
;*** this mark.
;***
	nop
	nop

;***
;*** from here it's ok to have zeroes in the code.
;***

;**************************************************************************
;**
;** booter
;** Fully relocatable & machine independant code.
;**
;******
booter_stuff:
booterstuff_OFFSET	EQU	[booter_stuff-reladdrstuffer]+1

;*
;* produce code with origin $0000
;* so that we can just add the base address to all
;* references
;*
	RORG	$0000
reladdr:

	lda	jmpaddr
	sta	relzp
	lda	jmpaddr+1
	sta	relzp+1

;*
;* relocate ourselves
;*

	ldy	#table_OFFSET
bt_lp1:
	ldx	#1
	lda	(relzp),y
	clc
	adc	relzp
	sta	currzp
	iny
	lda	(relzp),y
	bpl	bt_skp1
	ldx	#2
bt_skp1:
	and	#$7f
	adc	relzp+1
	sta	currzp+1
	iny
	sty	ytmp

	ldy	#0
	lda	(currzp),y
	clc
	adc	relzp
	sta	(currzp),y
	txa
	tay
	lda	(currzp),y
	adc	relzp+1
	sta	(currzp),y

	ldy	ytmp
	cpy	#tableend_OFFSET
	bne	bt_lp1

rel_iw0:
	jmp	theprogram

;**************************************************************************
;**
;** relocation tables
;**
;******
	MAC	RELINSTR
	IFCONST	rel_ilh{1}
	dc.w	[rel_ilh{1}+1]|$8000
	ELSE
	dc.w	[rel_iw{1}+1]
	ENDIF
	ENDM

table:
	RELINSTR	0
	RELINSTR	1
	RELINSTR	2
	RELINSTR	3
	RELINSTR	4
	RELINSTR	5
	RELINSTR	6
	RELINSTR	7
	RELINSTR	8
	RELINSTR	9
	RELINSTR	10
	RELINSTR	11
	RELINSTR	12
	RELINSTR	13
	RELINSTR	14
	RELINSTR	15
	RELINSTR	16
tableend:
table_OFFSET		EQU	[table-reladdr]
tableend_OFFSET		EQU	[tableend-reladdr]



;**************************************************************************
;**
;** theprogram
;** when entering here we are located at somewhere around MEMTOP-$420 and
;** all absolute references has (hopefully) been relocated.
;**
;******
theprogram:
	cli
rel_ilh1:
	ldx	#<start_MSG
	ldy	#>start_MSG
rel_iw2:
	jsr	bt_print


	jsr	$ffcc	;CLRCHN
	jsr	$ffe7	;CLALL

;*
;* open a RS232 channel
;*
	lda	#2
	ldx	#2
	ldy	#3
	jsr	$ffba	;SETLFS
	lda	#sernameend-sername
rel_ilh3:
	ldx	#<sername
	ldy	#>sername
	jsr	$ffbd	;SETNAM
	jsr	$ffc0	;OPEN

;*
;* set RS232 as the default input 
;*
	ldx	#2
	jsr	$ffc6	;CHKIN

;*
;* sync receiver 
;*
bt_lp2:
rel_iw4:
	jsr	bt_rawgetbyte
	cmp	#"S"
	bne	bt_lp2
bt_lp3:
rel_iw5:
	jsr	bt_rawgetbyte
	cmp	#"S"
	beq	bt_lp3


;*
;* Flush ST, and reset checksum
;*
	jsr	$ffb7	;READST

	lda	#0
	sta	checksumzp

;*
;* synced
;* now get mem bottom
;*
	sec
	jsr	$ff9c	;MEMBOT
	txa
	clc
	adc	#1
	sta	destzp
	tya
	adc	#0
	sta	destzp+1

;*
;* Get the data
;* $11,$11 -> $11   $11,$80 -> $00  $11,$01 -> END
;*

	ldx	#HASH_DISTANCE
	ldy	#0
bt_lp4:
rel_iw6:
	jsr	bt_getbyte
	cmp	#$11
	bne	bt_skp5

rel_iw7:
	jsr	bt_getbyte
	cmp	#$80
	beq	bt_skp2
	cmp	#$11
	beq	bt_skp5
	cmp	#$01	;endmark
	beq	bt_skp4
rel_iw8:
	jmp	bt_failchecksum
bt_skp2:
	lda	#0
bt_skp5:
	sta	(destzp),y
	inc	destzp
	bne	bt_skp3
	inc	destzp+1
bt_skp3:
	dex
	bne	bt_lp4
	lda	#"#"
	jsr	$ffd2
	ldx	#HASH_DISTANCE
	bne	bt_lp4	;always

;*
;* end of data
;* setup basic end.
;*
bt_skp4:
	lda	destzp
	sta	$2d	;end of basic program
	lda	destzp+1
	sta	$2e	;end of basic program

;*
;* receive checksum
;*
rel_iw9:
	jsr	bt_getbyte
rel_iw10:
	jsr	bt_getbyte
	lda	checksumzp
	bne	bt_failchecksum

;*
;* it went ok!
;*	

rel_ilh11:
	ldx	#<allok_MSG
	ldy	#>allok_MSG
rel_iw12:
	jsr	bt_print


bt_ex1:
;*
;* close RS232 and terminate 
;*
	jsr	$ffcc	;CLRCHN
	lda	#2
	jsr	$ffc3	;CLOSE

;*
;* 'READY.' has already been printed.
;* set direct mode,
;* set stack and jump through the basic main loop vector
;*
	lda	#$80
	jsr	$ff90	;SETMSG
	ldx	#$fa
	txs
	jmp	($0302)	;IMAIN


;*
;* failure exit
;* Just outputs '?transfer  error'
;*
bt_failchecksum:
bt_failserial:
rel_ilh13:
	ldx	#<error_MSG
	ldy	#>error_MSG
rel_iw14:
	jsr	bt_print
rel_iw15:
	jmp	bt_ex1


;**************************************************************************
;**
;** print
;** prints a NULL terminated string pointed to by X/Y
;** always returns Z=1
;**
;******
bt_print:
	stx	currzp
	sty	currzp+1
	ldy	#0
btp_lp1:
	lda	(currzp),y
	beq	btp_ex1
	jsr	$ffd2	;CHROUT
	iny
	bne	btp_lp1
btp_ex1:
	rts


;**************************************************************************
;**
;** getbyte
;**
;** get a byte from RS232, calculate checksum, exit if errors
;**
;******
bt_getbyte:
rel_iw16:
	jsr	bt_rawgetbyte
	pha
	clc
	adc	checksumzp
	sta	checksumzp
	jsr	$ffb7	;READST
	and	#$f7
	bne	bt_failserial
	pla
	rts

;**************************************************************************
;**
;** rawgetbyte
;**
;******
bt_rawgetbyte:
btrgb_lp1:
	jsr	$ffe4	;GETIN
	cmp	#0
	beq	btrgb_lp1
	rts

;**************************************************************************
;**
;** booter data
;**
;******
sername:	;600 baud
	dc.b	%00000111,%00000000
sernameend:

start_MSG:
	dc.b	13,13,"* STAGE 2 *",13,0
error_MSG:
	dc.b	13,"?TRANSFER  ERROR",13,"READY.",13,0
allok_MSG:
	dc.b	13,"OK, NOW SAVE TO DISK!",13,13,"READY.",13,0

	REND
	ds.b	[booter_start+$200]-.,$ea
booter_end:
