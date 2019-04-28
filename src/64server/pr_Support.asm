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
	bne	seb_skp3
	lda	endzp
	sec
	sbc	currzp
	jmp	seb_skp4
seb_skp3:	
	lda	#0
seb_skp4:
	sta	bl_blocksizezp
	jsr	WriteBlock
	bcs	seb_fl1

	lda	bl_blocksizezp
	beq	seb_skp2
	lda	currzp
	clc
	adc	bl_blocksizezp
	sta	currzp
	bcc	seb_skp1
seb_skp2:
	inc	currzp+1
seb_skp1:

	lda	currzp
	cmp	endzp
	bne	seb_lp1
	lda	currzp+1
	cmp	endzp+1
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

	lda	bl_blocksizezp
	beq	reb_skp2
	lda	currzp
	clc
	adc	bl_blocksizezp
	sta	currzp
	bcc	reb_skp1
reb_skp2:
	inc	currzp+1
reb_skp1:

	lda	currzp
	cmp	endzp
	bne	reb_lp1
	lda	currzp+1
	cmp	endzp+1
	bne	reb_lp1

reb_ex1:
	clc
	rts

reb_fl1:
	sec
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
	ldx	#15
	stx	bl_channelzp
	ldx	#<BUFFER
	stx	currzp
	ldx	#>BUFFER
	stx	currzp+1
	sta	BUFFER
	lda	#1
	sta	bl_blocksizezp
	jsr	WriteBlock
	rts

;**************************************************************************
;**
;** WaitOK
;**
;******
WaitOKLong:
	lda	#<BUFFER
	sta	currzp
	lda	#>BUFFER
	sta	currzp+1
	jsr	ReadBlockLong
	jmp	wo_skp1
WaitOK:
	lda	#<BUFFER
	sta	currzp
	lda	#>BUFFER
	sta	currzp+1
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
	lda	#15
	sta	bl_channelzp
	lda	#<BUFFER
	sta	currzp
	lda	#>BUFFER
	sta	currzp+1
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
	jsr	WriteBlock
	rts

