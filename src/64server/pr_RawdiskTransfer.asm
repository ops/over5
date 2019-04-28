;**************************************************************************
;**
;** pr_RawdiskTransfer.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;**************************************************************************
;**
;** RawdiskTransfer
;**
;******
RawdiskTransfer:
	lda	BUFFER+HEADER_TYPE
	cmp	#TYPE_RAWDISKTRANSFER
	bne	rt_fl2
	lda	BUFFER+HEADER_SUBTYPE
	cmp	#SUB_RT_WRITETRACK
	beq	rt_WriteTrack
	cmp	#SUB_RT_READTRACK
	beq	rt_ReadTrack
	cmp	#SUB_RT_WRITESECTOR
	beq	rt_WriteSector
	cmp	#SUB_RT_READSECTOR
	beq	rt_ReadSector

	lda	#RESP_NOTSUPPORTED
	jsr	SendResp

rt_fl2:
	sec
	rts	
rt_ex1:
	clc
	rts

rt_fl1:
	lda	#RESP_ERROR
	jsr	SendResp

	sec
	rts	


;**************************************************************************
;**
;** Write a sector
;**
;******
rt_WriteSector:
	jmp	rt_fl1

;**************************************************************************
;**
;** Read a sector
;**
;******
rt_ReadSector:
	jmp	rt_fl1

;**************************************************************************
;**
;** Write a track
;**
;******
rt_WriteTrack:
	lda	#RESP_OK
	jsr	SendResp
	lda	BUFFER+WTHD_TRACK
	sta	trackzp
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

	lda	trackzp
	ldx	BUFFER+WTHD_NUMTRACKS
	jsr	dsk_sizetracks
	txa
	clc
	adc	currzp
	sta	endzp
	tya
	adc	currzp+1
	sta	endzp+1

;*** receive body ***
	jsr	recvbody
	bcs	rt_fl1

;*** Write track ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	dsk_setstart
	lda	trackzp
	ldx	BUFFER+WTHD_NUMTRACKS
	jsr	dsk_writetracks

	php
	jsr	InitSerial
	plp
	bcs	rt_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	rt_fl1

	jmp	rt_ex1


;**************************************************************************
;**
;** Read a track
;**
;******
rt_ReadTrack:
	lda	#RESP_OK
	jsr	SendResp
	lda	BUFFER+WTHD_TRACK
	sta	trackzp


;*** read track ***
	jsr	UninitSerialSmall


	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	dsk_setstart
	lda	trackzp
	ldx	BUFFER+WTHD_NUMTRACKS
	jsr	dsk_readtracks

	php
	jsr	InitSerial
	plp
	bcs	rrt_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	rrt_fl1

;*** wait ok! ***
	jsr	WaitOK
	bcs	rrt_fl1


;*** calculate size ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

	lda	trackzp
	ldx	BUFFER+WTHD_NUMTRACKS
	jsr	dsk_sizetracks
	txa
	clc
	adc	currzp
	sta	endzp
	tya
	adc	currzp+1
	sta	endzp+1

;*** send body ***
	jsr	sendbody
	bcs	rrt_fl1

;*** wait ok! ***
	jsr	WaitOK
	bcs	rrt_fl1

	jmp	rt_ex1
rrt_fl1:
	jmp	rt_fl1

