;**************************************************************************
;**
;** ds_mem.i
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


;*
;* general
;*
stacktempzp	EQU	$b4	;byte
slaskzp		EQU	$ab	;byte
modeflags	EQU	$0338	;byte
currzp		EQU	$c3	;word
endzp		EQU	$be	;word
tempzp		EQU	$a9	;byte

;*
;* dsk_disk.asm
;*
trackzp		EQU	$0339	;byte
sectorzp	EQU	$033a	;byte
