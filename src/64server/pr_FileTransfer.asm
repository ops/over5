;**************************************************************************
;**
;** pr_FileTransfer.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;**************************************************************************
;**
;** FileTransfer
;**
;******
FileTransfer:
	lda	BUFFER+HEADER_TYPE
	cmp	#TYPE_FILETRANSFER
	bne	ft_fl2
	lda	BUFFER+HEADER_SUBTYPE
	cmp	#SUB_FT_WRITEFILE		;send to c64
	beq	ft_WriteFile
	cmp	#SUB_FT_READFILE		;file from c64
	beq	ft_ReadFile

	lda	#RESP_NOTSUPPORTED
	jsr	SendResp

ft_fl2:
	sec
	rts	
ft_ex1:
	clc
	rts

ft_fl1:
	lda	#RESP_ERROR
	jsr	SendResp

	sec
	rts	


;**************************************************************************
;**
;** Load a file and send it.
;**
;******
ft_ReadFile:
;*** send ok! ***
	jsr	SendOK
	bcs	ft_fl1

;*** load file ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<[BUFFER+HEADER_FILENAME]
	ldy	#>[BUFFER+HEADER_FILENAME]
	jsr	dsk_setname

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	dsk_readfile
	stx	endzp
	sty	endzp+1

	php
	jsr	InitSerial
	plp
	bcs	ft_fl1

;*** send ok! ***
	jsr	SendOKlen
	bcs	ft_fl1

;*** wait ok ***
	jsr	WaitOK


;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** send body ***
	jsr	sendbody
	bcs	ft_fl1

;*** wait ok ***
	jsr	WaitOK

	jmp	ft_ex1

;**************************************************************************
;**
;** Receive a file and save it to disk
;**
;******
ft_WriteFile:
;*** send ok! ***
	jsr	SendOK
	bcs	ft_fl1


;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** set end address ***
	lda	BUFFER+WFHD_LEN_L
	clc
	adc	currzp
	sta	endzp
	lda	BUFFER+WFHD_LEN_H
	adc	currzp+1
	sta	endzp+1

;*** receive body ***
	jsr	recvbody
	bcs	ftc_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	ftc_fl1

;*** save file ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<[BUFFER+HEADER_FILENAME]
	ldy	#>[BUFFER+HEADER_FILENAME]
	jsr	dsk_setname

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	stx	currzp
	sty	currzp+1

	lda	#currzp
	ldx	endzp
	ldy	endzp+1
	jsr	dsk_writefile

	php
	jsr	InitSerial
	plp
	bcs	ftc_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	ftc_fl1

	jmp	ft_ex1

ftc_fl1:
	jmp	ft_fl1



;**************************************************************************
;**
;** DiskCommands
;**
;******
DiskCommands:
	lda	BUFFER+HEADER_TYPE
	cmp	#TYPE_DISKCOMMAND
	bne	dc_fl2
	lda	BUFFER+HEADER_SUBTYPE
	cmp	#SUB_DC_DIRECTORY
	beq	dc_Directory
	cmp	#SUB_DC_STATUS
	beq	dc_Status
	cmp	#SUB_DC_COMMAND
	bne	dc_skp10
	jmp	dc_Command
dc_skp10:

	lda	#RESP_NOTSUPPORTED
	jsr	SendResp

dc_fl2:
	sec
	rts	
dc_ex1:
	clc
	rts

dc_fl1:
	lda	#RESP_ERROR
	jsr	SendResp

	sec
	rts	


;**************************************************************************
;**
;** Do DIRECTORY
;**
;******
dc_Directory:
;*** send ok! ***
	jsr	SendOK
	bcs	dc_fl1

;*** load file ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<[BUFFER+HEADER_FILENAME]
	ldy	#>[BUFFER+HEADER_FILENAME]
	jsr	dsk_setname

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	dsk_readfile
	stx	endzp
	sty	endzp+1

	php
	jsr	InitSerial
	plp
	bcs	dc_fl1

;*** send ok! ***
	jsr	SendOKlen
	bcs	dc_fl1

;*** wait ok ***
	jsr	WaitOK


;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** send body ***
	jsr	sendbody
	bcs	dc_fl1


;*** wait ok ***
	jsr	WaitOK

	jmp	dc_ex1

;**************************************************************************
;**
;** Do STATUS
;**
;******
dc_Status:
;*** send ok! ***
	jsr	SendOK
	bcs	dc_fl1
	
;*** get status ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	dsk_getstatus
	sty	bl_blocksizezp

	jsr	InitSerial

;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** send statusline ***
	lda	#1
	sta	bl_channelzp
	jsr	WriteBlock
	bcs	dc_fl1

;*** wait ok ***
	jsr	WaitOK

	jmp	dc_ex1

;**************************************************************************
;**
;** Do DISKCOMMAND
;**
;******
dc_Command:
;*** send ok! ***
	jsr	SendOK
	bcs	dc_fl1

;*** set start address ***
	lda	#<FileBufferStart
	sta	currzp
	lda	#>FileBufferStart
	sta	currzp+1

;*** get command ***
	jsr	ReadBlock
	bcs	dcc_fl1
	lda	bl_channelzp
	cmp	#1
	bne	dcc_fl1

;*** Send command ***
	jsr	UninitSerialSmall

	lda	BUFFER+HEADER_DEVICE
	sta	$ba	;devicenum

	lda	bl_blocksizezp
	ldx	#<FileBufferStart
	ldy	#>FileBufferStart
	jsr	$ffbd	;SETNAM

	jsr	dsk_diskcommand2

	jsr	InitSerial

;*** send ok! ***
	jsr	SendOK
	bcs	dcc_fl1

	jmp	dc_ex1
dcc_fl1:
	jmp	dc_fl1

