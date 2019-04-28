;**************************************************************************
;**
;** pr_SerFile.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;**************************************************************************
;**
;** NAME  DoSrvLoad
;**
;** DESCRIPTION
;**   Loads a file from server.
;**
;** INPUTS
;**   the name must have been setup with SETNAM.
;**
;** RESULT
;**   Carry - if set, an error has occured.
;**   A     - kernal error code (only if carry set)
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   none
;**
;******
DoSrvLoad:
	jsr	InitSerial
	lda	#$00
	sta	$90
	lda	#4		;'file not found'
	sta	returnzp

;*
;* do the command
;*
	lda	#TYPE_SERVER
	sta	BUFFER+SRVLDHD_TYPE
	lda	#SUB_SRV_LOAD
	sta	BUFFER+SRVLDHD_SUBTYPE

;*
;* copy filename
;*
	jsr	sf_copyfilename
	
;*
;* send command
;*

	lda	#SRVLDHD_SIZEOF
	jsr	sf_sendcommand
	bcs	dsl_fl1

;*
;* wait for response
;*
	jsr	WaitOKLong
	bcs	dsl_fl1
	lda	BUFFER+SRVLDRS_START_L
	sta	currzp
	lda	BUFFER+SRVLDRS_START_H
	sta	currzp+1
	lda	BUFFER+SRVLDRS_END_L
	sta	endzp
	lda	BUFFER+SRVLDRS_END_H
	sta	endzp+1

	lda	currzp
	pha
	lda	currzp+1
	pha

;*
;* send OK
;*
	lda	#RESP_OK
	sta	BUFFER+SRVLDRS2_RESPONSE
	lda	currzp
	sta	BUFFER+SRVLDRS2_START_L
	lda	currzp+1
	sta	BUFFER+SRVLDRS2_START_H

	lda	#SRVLDRS2_SIZEOF
	jsr	sf_sendcommand
	pla
	sta	currzp+1
	pla
	sta	currzp
	bcs	dsl_fl1

;*
;* receive body
;*
	jsr	recvbody
	bcs	dsl_fl1

	lda	endzp
	sta	$ae
	lda	endzp+1
	sta	$af

;*
;* send ok
;*
	jsr	SendOK
	bcs	dsl_fl1


	clc
dsl_fl1:
dsl_ex1:
	php
	bcc	 dsl_skp3
	lda	#%01000011
	sta	$90
	lda	bl_errorzp
	beq	dsl_skp3
	lda	#5		;'device not present'
	sta	returnzp
dsl_skp3:
;*
;* Return safely to earth!
;*
	jsr	UninitSerial
	plp
	lda	returnzp
	rts

;**************************************************************************
;**
;** NAME  DoSrvSave
;**
;** DESCRIPTION
;**   Save a file to server.
;**
;** INPUTS
;**   $c1/$c2 - startaddress
;**   $ae/$af - endaddress
;**   the name must have been setup with SETNAM.
;**
;** RESULT
;**   Carry - if set, an error has occured.
;**   A     - kernal error code (only if carry set)
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   none
;**
;******
DoSrvSave:
	jsr	InitSerial
	lda	#$00
	sta	$90
	lda	#4		;'file not found'
	sta	returnzp

;*
;* do the command
;*
	lda	#TYPE_SERVER
	sta	BUFFER+SRVSVHD_TYPE
	lda	#SUB_SRV_SAVE
	sta	BUFFER+SRVSVHD_SUBTYPE

	lda	$c1
	sta	BUFFER+SRVSVHD_START_L
	lda	$c2
	sta	BUFFER+SRVSVHD_START_H
	lda	$ae
	sta	BUFFER+SRVSVHD_END_L
	lda	$af
	sta	BUFFER+SRVSVHD_END_H

;*
;* copy filename
;*
	jsr	sf_copyfilename

;*
;* send command
;*
	lda	#SRVSVHD_SIZEOF
	jsr	sf_sendcommand
	bcs	dss_fl1

;*
;* wait for response
;*
	jsr	WaitOK
	bcs	dss_fl1

;*
;* sendbody
;*
	lda	$c1
	sta	currzp
	lda	$c2
	sta	currzp+1
	lda	$ae
	sta	endzp
	lda	$af
	sta	endzp+1
	jsr	sendbody
	bcs	dss_fl1


;*
;* wait for response
;*
	jsr	WaitOKLong
	bcs	dss_fl1

	clc
dss_fl1:
dss_ex1:
	php
	bcc	dss_skp3
	lda	#%01000011
	sta	$90
	lda	bl_errorzp
	beq	dss_skp3
	lda	#5		;'device not present'
	sta	returnzp
dss_skp3:
;*
;* Return safely to earth!
;*
	jsr	UninitSerial
	plp
	lda	returnzp
	rts


;**************************************************************************
;**
;** NAME  DoSrvCommand
;**
;** DESCRIPTION
;**   Send a command to server.
;**
;** INPUTS
;**   the command must have been setup with SETNAM.
;**
;** RESULT
;**   Carry - if set, an error has occured.
;**   A     - kernal error code (only if carry set)
;**
;** BUGS
;**   none known
;**
;** SEE ALSO
;**   none
;**
;******
DoSrvCommand:
	jsr	InitSerial
	lda	#4		;'file not found'
	sta	returnzp

;*
;* do the command
;*
	lda	#TYPE_SERVER
	sta	BUFFER+SRVCMHD_TYPE
	lda	#SUB_SRV_COMMAND
	sta	BUFFER+SRVCMHD_SUBTYPE

;*
;* copy filename
;*
	jsr	sf_copyfilename

;*
;* send command
;*
	lda	#SRVCMHD_SIZEOF
	jsr	sf_sendcommand
	bcs	dsc_fl1

;*
;* wait for response
;*
	jsr	WaitOK
	bcs	dsc_fl1

;*
;* wait for response
;*
	jsr	WaitOKLong
;	bcs	dsc_fl1

dsc_fl1:
dsc_ex1:
	php
	bcc	dsc_skp1
	lda	bl_errorzp
	beq	dsc_skp1
	lda	#5		;'device not present'
	sta	returnzp
dsc_skp1:
;*
;* Return safely to earth!
;*
	jsr	UninitSerial
	plp
	lda	returnzp
	rts




;**************************************************************************
;**
;** DO SRV_READSTRING
;**
;** OUT: Carry=1 -> more pages
;**
;******
dsrs_fl2:
dsrs_ex2:
	jmp	dsrs_ex1
DoSrvReadString:
	jsr	InitSerial

;*
;* prepare clean exit
;*
	lda	#0
	sta	returnzp

;*
;* do the command
;*
	lda	#TYPE_SERVER
	sta	BUFFER+SRVRSHD_TYPE
	lda	#SUB_SRV_READSTRING
	sta	BUFFER+SRVRSHD_SUBTYPE
	ldx	#40
	ldy	#25
	stx	BUFFER+SRVRSHD_WIDTH
	sty	BUFFER+SRVRSHD_HEIGHT

;*
;* send command
;*
	lda	#SRVRSHD_SIZEOF
	jsr	sf_sendcommand
	bcs	dsrs_fl2

;*
;* wait for response
;*
	jsr	WaitOK
	bcs	dsrs_fl2
	lda	BUFFER+SRVRSRS_ROWS
	beq	dsrs_ex2	;no messages.
	sta	returnzp
	and	#$7f
	sta	rowszp
	jsr	UninitSerialSmall

;*
;* fix space on screen
;*
	ldx	rowszp
	lda	#13
dsrs_lp3:
	jsr	newffd2
	dex
	bne	dsrs_lp3

	lda	$d6
	sec
	sbc	rowszp
	tax
	inx
	ldy	#0
	clc
	jsr	newfff0

;*
;* calculate pointers
;*
	lda	$d1
	sta	currzp
	sta	endzp
	sta	$f3
	lda	$d2
	sta	currzp+1
	sta	endzp+1
	sec
	sbc	$288
	clc
	adc	#$d8
	sta	$f4	

	ldx	rowszp
dsrs_lp2:
	lda	endzp
	clc
	adc	#40
	sta	endzp
	lda	endzp+1
	adc	#0
	sta	endzp+1
	dex
	bne	dsrs_lp2

;*
;* get message
;*
	jsr	InitSerial
	lda	currzp
	pha
	lda	currzp+1
	pha
	jsr	SendOK
	pla
	sta	currzp+1
	pla
	sta	currzp
	bcs	dsrs_fl1

	jsr	recvbody
	bcs	dsrs_fl1


;*
;* fill up colors
;*
	lda	endzp+1
	sec
	sbc	$288
	clc
	adc	#$d8
	sta	endzp+1

	ldy	#0
	lda	$286
dsrs_lp1:
	sta	($f3),y
	inc	$f3
	bne	dsrs_skp1
	inc	$f4
dsrs_skp1:
	ldx	$f3
	cpx	endzp
	bne	dsrs_lp1
	ldx	$f4
	cpx	endzp+1
	bne	dsrs_lp1

;*
;* fix cursor pos
;*
	lda	$d6
	clc
	adc	rowszp
	tax
	dex
	ldy	#0
	clc
	jsr	newfff0

dsrs_ex1:
dsrs_fl1:
;*
;* Return safely to earth!
;*
	jsr	UninitSerial
	lda	returnzp
	bmi	dsrs_ex3
	clc
	rts
dsrs_ex3:
	sec
	rts


;**************************************************************************
;**
;** sf_copyfilename
;**
;******
sf_copyfilename:
	ldy	#0
cfn_lp1:
	lda	($bb),y
	sta	BUFFER+SRVHD_FILENAME,y
	iny
	cpy	$b7
	bne	cfn_lp1
	lda	#0
	sta	BUFFER+SRVHD_FILENAME,y
	lda	$b7
	rts


;**************************************************************************
;**
;** sf_sendcommand
;**
;** IN: A=size of command
;** OUT: Carry=0 => OK!
;**
;******
sf_sendcommand:
	sta	bl_blocksizezp
	lda	#<BUFFER
	sta	currzp
	lda	#>BUFFER
	sta	currzp+1
	lda	#15
	sta	bl_channelzp
	jmp	WriteBlock

