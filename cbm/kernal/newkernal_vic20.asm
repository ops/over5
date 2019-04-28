;**************************************************************************
;*
;* FILE  newkernal_vic20.asm
;* Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: newkernal_vic20.asm,v 1.2 2002/04/27 13:10:16 tlr Exp $
;*
;* DESCRIPTION
;*   Improvements and stuff for a vic20 kernal.
;*
;******
	processor 6502
	INCLUDE	"../../tlrutils/dasm/patch.i"

;**************************************************************************
;*
;* Configuration
;*
;******
; new reset message
ADD_RESETMSG	EQU	1

TEXT_COLOR	EQU	6
BKGND_COLOR	EQU	1
BORDER_COLOR	EQU	3

; start of the patch
	PATCHHEADER

;**************************************************************************
;*
;* Improvements and bugfixes
;*
;******

	IF	ADD_RESETMSG
;**************************************************************************
;*
;* Add reset message
;*
;******
;e436  93 2a 2a 2a 2a 20 43 42 '.**** CB'
;e43e  4d 20 42 41 53 49 43 20 'M BASIC '
;e446  56 32 20 2a 2a 2a 2a 0d 'V2 ****.'
;e44e  00                      '.'
	STARTPATCH $e436,$e44e,$ea
	dc.b	147
	dc.b	"**** OVER5 KERNAL ****",13,0
	ENDPATCH

; In $e518 (CINT)
; e54f a9 06     lda #$06
; e551 8d 86 02  sta $0286
	STARTPATCH $e550,$e550,$ea
	dc.b	TEXT_COLOR	;cursor color
	ENDPATCH

; VIC-I init-table 
; Copied to $9000-$900f by the routine at $e5bb)
; ede4 0c 26 16 2e 00 c0 00 00
; edee 00 00 00 00 00 00 00 1b
	STARTPATCH $edf3,$edf3,$ea
	dc.b	BKGND_COLOR<<4 | [BORDER_COLOR | %1000] 	;color ($900f)
	ENDPATCH

	ENDIF	;ADD_RESETMSG

; end of the patch file
	PATCHFOOTER
; eof
