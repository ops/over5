;**************************************************************************
;**
;** bl_mem.i
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;*
;* bl_block.asm
;* the following are used as soon 'InitSerial' is called,
;* and cannot be used for other things, until 'UninitSerial' is
;* called.
;*
bl_recvblocknumzp	EQU	$a4	;byte
bl_sendblocknumzp	EQU	$a5	;byte
bl_irqstore		EQU	$029f	;word

;*
;* bl_block.asm
;* temporary storage.  These are probably destroyed if
;* you call 'ReadBlock', 'ReadBlockLong' or 'WriteBlock'
;*
bl_currzp		EQU	currzp	;word
bl_tempzp		EQU	$a9	;byte
bl_statuszp		EQU	$a8	;byte
bl_checksumzp		EQU	$a7	;byte
bl_shiftregzp		EQU	$bd	;byte
bl_channelzp		EQU	$a3	;byte
bl_blocksizezp		EQU	$a6	;byte
bl_errorzp		EQU	$02	;byte
bl_timeoutzp		EQU	$aa	;byte
bl_retries		EQU	$ab	;byte
bl_timeoutstack		EQU	$b4	;byte
bl_timeoutroutine	EQU	$b5	;word

