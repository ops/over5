;**************************************************************************
;**
;** cart_mem.i
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******


currzp		EQU	$c3	;word
endzp		EQU	$be	;word
tempzp		EQU	$a9	;byte

turboflag	EQU	$9e	;byte
modeflags	EQU	$9e	;byte
stacktempzp	EQU	$9f	;byte

trackzp		EQU	$02a7	;byte
sectorzp	EQU	$02a8	;byte
slaskzp		EQU	$fd	;byte

turbo_getmemplace	EQU	$0110
blk_getmemplace		EQU	$0110
mt_sysserplace	EQU	$0110
mt_runnerplace	EQU	$0110
dsk_getmemplace	EQU	$0110

BUFFER		EQU	$0128
buffersize	EQU	64
FileBufferStart	EQU	$0334
FileBufferEnd	EQU	$ffff
