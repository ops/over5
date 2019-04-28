;**************************************************************************
;**
;** sf_mem.i
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

currzp		EQU	$c3	;word
endzp		EQU	$be	;word
rowszp		EQU	$9e	;byte
returnzp	EQU	$9f	;byte
tempzp		EQU	$a9	;byte
xtempzp		EQU	tempzp	;byte
;*** basic patch ***

buf_start	EQU	$02b0
buf_end		EQU	$02fe

