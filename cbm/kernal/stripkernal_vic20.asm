;**************************************************************************
;*
;* FILE  stripkernal_vic20.asm
;* Copyright (c) 1995, 1996, 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: stripkernal_vic20.asm,v 1.2 2002/04/27 13:10:16 tlr Exp $
;*
;* DESCRIPTION
;*   this file contains a patch to remove tape and RS-232 routines from a
;*   vic20 kernal.
;*   kernal revisions that will work is:
;*     NTSC-M version (901486-06) $e475=$41
;*     PAL-B version (901486-07)  $e475=$e8
;*
;*   The only areas differing between original American kernals and other
;*   language kernals are these areas:
;*     $ec5e-$ed20 keyboard decode tables for standard/SHIFTed/C=ed keys
;*     $ed69-$ede3 keyboard decode tables for CTRLed keys
;*
;******
	processor 6502
	INCLUDE	"../../tlrutils/dasm/patch.i"

;**************************************************************************
;*
;* Configuration
;*
;******
; remove all tape support?
REMOVE_TAPE	EQU	1
; remove all rs232 support?
REMOVE_RS232	EQU	1

; start of the patch
	PATCHHEADER

;**************************************************************************
;*
;* Clean out unnecessary routines
;*
;******
; original patch area (filled with $ff)
	STARTPATCH $e47c,$e49f,$ea	;empty  
	ENDPATCH

	IF	REMOVE_RS232
; No check for RS232 ended! (vic20)
 	STARTPATCH $ee19,$ee1b,$ea
	nop
	nop
	nop
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 routines (vic20)
	STARTPATCH $efa3,$f173,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_TAPE
; Messages 'press play on tape' and 'press record & play on tape' (vic20)
	STARTPATCH $f18f,$f1bc,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

	IF	0
	IF	REMOVE_RS232
; skip RS232 in GETIN
	STARTPATCH $f140,$f141,$ea
	bne	$f166
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 in GETIN (empty)
	STARTPATCH $f14a,$f154,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

; return CR if a bogus read from RS232 or tape occurs
	STARTPATCH $f175,$f177,$ea
	lda	#$0d
	rts
	ENDPATCH

	IF	REMOVE_TAPE
; tape in BASIN
	STARTPATCH $f178,$f1ac,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

	IF	REMOVE_RS232
; RS232 in BASIN
	STARTPATCH $f1b8,$f1c9,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

; Don't accept RS232 or tape in BSOUT
	STARTPATCH $f1db,$f1dd,$ea
	jmp	$f707	;(device not present)
	ENDPATCH

; tape and RS232 in BSOUT
	STARTPATCH $f1de,$f20d,$ea	;empty
	ENDPATCH

; Don't accept RS232 or tape in CHKIN
	STARTPATCH $f223,$f225,$ea
	jmp	$f707	;(device not present)
	ENDPATCH

	IF	REMOVE_TAPE
; tape in CHKIN
	STARTPATCH $f226,$f232,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

; Don't accept RS232 or tape in CKOUT
	STARTPATCH $f268,$f26a,$ea
	jmp	$f707	;(device not present)
	ENDPATCH

	IF	REMOVE_TAPE
; tape in CKOUT
	STARTPATCH $f26b,$f274,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

; Don't accept RS232 or tape in CLOSE
	STARTPATCH $f2a7,$f2a9,$ea
	jmp	$f707	;(device not present)
	ENDPATCH

; RS232 and tape in CLOSE
	STARTPATCH $f2aa,$f2ed,$ea	;empty
	ENDPATCH

; Don't accept RS232 or tape in OPEN
	STARTPATCH $f384,$f386,$ea
	jmp	$f713	;(illegal device number)
	ENDPATCH

	IF	REMOVE_TAPE
; tape in OPEN
	STARTPATCH $f387,$f3d2,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

	IF	REMOVE_RS232
; RS232 in OPEN
	STARTPATCH $f409,$f49d,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

; don't accept RS232 or tape in LOAD
	STARTPATCH $f4b6,$f4b7,$ea
	bcc	$f4af	;(illegal device number)
	ENDPATCH

	IF	REMOVE_TAPE
; tape in LOAD
	STARTPATCH $f533,$f5a7,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

; don't accept RS232 or tape in SAVE
	STARTPATCH $f5f8,$f5f9,$ea
	bcc	$f5f1	;(illegal device number)
	ENDPATCH

	IF	REMOVE_TAPE
; tape in SAVE
	STARTPATCH $f659,$f68b,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

	IF	REMOVE_TAPE
; general tape routines
	STARTPATCH $f7af,$fb8d,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

	IF	REMOVE_TAPE
; general tape routines
	STARTPATCH $fb97,$fcbc,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

; IRQ vectors
	STARTPATCH $fd9b,$fda2,$ea
	dc.w	$ea31,$ea31,$ea31,$ea31
	ENDPATCH

	IF	REMOVE_RS232
; remove RS232 from NMI
	STARTPATCH $fe54,$fe55,$ea
	bmi	$feb6
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 NMI routine exit quick
	STARTPATCH $fe72,$fe74,$ea
	jmp	$feb6
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 in NMI
	STARTPATCH $fe75,$feb5,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232
	ENDIF

	IF	REMOVE_RS232
; RS232 (vic20)
	STARTPATCH $ff5c,$ff71,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

; unused (vic20)
; fff6  ff ff ff ff '....'
	STARTPATCH $fff6,$fff9,$ea	;empty
	ENDPATCH

; end of the patch file
	PATCHFOOTER
; eof
