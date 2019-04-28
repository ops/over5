;**************************************************************************
;**
;** pr_Test.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;**************************************************************************
;**
;** TESTCOMMAND
;**
;******
TestCommand:
	lda	BUFFER+HEADER_TYPE
	cmp	#TYPE_TESTCOMMAND
	bne	tc_fl2
	lda	BUFFER+HEADER_SUBTYPE
	cmp	#SUB_TC_BLOCKTEST
	beq	tc_BlockTest
	cmp	#SUB_TC_FILETEST
	beq	tc_FileTest

	lda	#RESP_NOTSUPPORTED
	jsr	SendResp

tc_fl2:
	sec
	rts	
tc_ex1:
	clc
	rts

tc_fl1:
	lda	#RESP_ERROR
	jsr	SendResp
	sec
	rts

;**************************************************************************
;**
;** BLOCKTEST
;**
;******
tc_BlockTest:
;*** send ok! ***
	jsr	SendOK
	bcs	tc_fl1


;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** do test ***
	lda	#0
	sta	currzp
tcbt_lp1:
;*** get block ***
	lda	#$ff
	jsr	ReadBlock
	bcs	tc_fl1

;*** bounce block ***
	jsr	WriteBlock
	bcs	tc_fl1

;*** do 16 times ***
	inc	currzp
	lda	currzp
	cmp	#16
	bne	tcbt_lp1

	jmp	tc_ex1


;**************************************************************************
;**
;** FILETEST
;**
;******
tc_FileTest:

;*** GET FILE ***

;*** send ok! ***
	jsr	SendOK
	bcs	tc_fl1

;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** set end address ***
	lda	BUFFER+FTHD_LEN_L
	clc
	adc	currzp
	sta	endzp
	lda	BUFFER+FTHD_LEN_H
	adc	currzp+1
	sta	endzp+1

;*** receive body ***
	jsr	recvbody
	bcs	tc_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	tc_fl1


;*** BOUNCE FILE ***

;*** send ok! ***
	jsr	SendOKlen
	bcs	tc_fl1

;*** wait ok ***
	jsr	WaitOK


;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** send body ***
	jsr	sendbody
	bcs	tc_fl1

;*** wait ok ***
	jsr	WaitOK

	jmp	tc_ex1
