;**************************************************************************
;**
;** pr_Support.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

;**************************************************************************
;**
;** Send body on channel 1
;**
;** start: currzp  end: endzp
;**
;******
sendbody:

	lda	#1
	sta	bl_channelzp
;*** send body ***
seb_lp1:
	lda	endzp
	sec
	sbc	currzp
	lda	endzp+1
	sbc	currzp+1
	bne	seb_skp3	; if not same page, transfer 256 bytes.
	lda	endzp		; else, calculate difference
	sec
	sbc	currzp
	jmp	seb_skp4
seb_skp3:	
	lda	#0	; 256 bytes
seb_skp4:
	sta	bl_blocksizezp
	jsr	WriteBlock
	bcs	seb_fl1

	jsr	IncCmpEndPtr
	bne	seb_lp1

	clc
	rts
seb_fl1:
	sec
	rts

;**************************************************************************
;**
;** Receive body
;**
;** start: currzp  end: endzp
;**
;******
recvbody:

;*** receive body ***
reb_lp1:
	jsr	ReadBlock
	bcs	reb_fl1
	lda	bl_channelzp
	cmp	#1
	bne	reb_fl1

	jsr	IncCmpEndPtr
	bne	reb_lp1

	clc
	rts

reb_fl1:
	sec
	rts


;**************************************************************************
;**
;** IncCmpEndPtr
;** increase currzp by bl_blocksizezp.  Compare currzp to endzp
;** Z=0 if same.
;**
;******
IncCmpEndPtr:
	lda	bl_blocksizezp
	beq	icep_skp2	;if 0, skip to add 256
	lda	currzp		;otherwise do 16-bit add
	clc
	adc	bl_blocksizezp
	sta	currzp
	bcc	icep_skp1
icep_skp2:
	inc	currzp+1
icep_skp1:

; compare currzp and endzp
	lda	currzp
	cmp	endzp
	bne	icep_ex1
	lda	currzp+1
	cmp	endzp+1
icep_ex1:
	rts

;**************************************************************************
;**
;** SendOK
;**
;******
SendOK:
	lda	#RESP_OK	;OK
	jmp	SendResp

;**************************************************************************
;**
;** SendResponse	
;** Acc=Response
;**
;******
SendResp:
	sta	BUFFER
	jsr	SetupBufferPtrCh15
	lda	#1
	sta	bl_blocksizezp
	jmp	WriteBlock

;**************************************************************************
;**
;** WaitOK
;**
;******
WaitOKLong:
	jsr	SetupBufferPtr
	jsr	ReadBlockLong
	jmp	wo_skp1
WaitOK:
	jsr	SetupBufferPtr
	jsr	ReadBlock
wo_skp1:
	bcs	wo_fl1
	lda	bl_channelzp
	cmp	#15
	bne	wo_fl1
	lda	BUFFER
	cmp	#RESP_OK
	bne	wo_fl1
	clc
	rts
wo_fl1:
	sec
	rts

;**************************************************************************
;**
;** SendOK+len
;**
;******
SendOKlen:
	jsr	SetupBufferPtrCh15
	lda	#RESP_OK	;OK
	sta	BUFFER+RFRS_RESPONSE
;*** calc end ***
	lda	endzp
	sec
	sbc	#<FileBufferStart
	sta	BUFFER+RFRS_LEN_L
	lda	endzp+1
	sbc	#>FileBufferStart
	sta	BUFFER+RFRS_LEN_H

;*** send ***
	lda	#3
	sta	bl_blocksizezp
	jmp	WriteBlock

;**************************************************************************
;**
;** load BUFFER into currzp
;**
;******
SetupBufferPtrCh15:
	lda	#15
	sta	bl_channelzp
SetupBufferPtr:
	lda	#<BUFFER
	sta	currzp
	lda	#>BUFFER
	sta	currzp+1
	rts
; eof
