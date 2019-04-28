;**************************************************************************
;**
;** dsk_mem.i 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

;*
;*
;*
d_currzp	EQU	$ae	;word
d_endzp		EQU	$ac	;word
d_tempptrzp	EQU	$9b	;word
d_tempzp	EQU	$a6	;byte
d_slaskzp	EQU	$a7	;byte
d_sectorzp	EQU	$a8	;byte
d_trackzp	EQU	$a9	;byte
d_retries	EQU	$aa	;byte
d_modeflags	EQU	$0334	;byte

;*
;* dsk_diskturbo.asm
;*
d_turbotmp1zp	EQU	$a4	;byte
d_turbotmp2zp	EQU	$90	;byte
d_turbotmp3zp	EQU	$93	;byte
d_turboptr1zp	EQU	$3f	;word
d_turboptr2zp	EQU	$41	;word

;*
;* dsk_pitchtrack.asm
;*
d_tracknumber	EQU	$9b	;byte
d_lastplusone	EQU	$9c	;byte
d_temp		EQU	$fc	;byte
d_temp2		EQU	$fd	;byte
d_temp3		EQU	$ff	;byte
d_temp4		EQU	$96	;byte
d_pfa		EQU	$fa	;word
;d_afa		EQU	$fa	;byte
;d_afb		EQU	$fb	;byte
d_afd		EQU	$fd	;byte
d_afe		EQU	$fe	;byte
