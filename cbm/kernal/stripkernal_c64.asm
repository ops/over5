;**************************************************************************
;*
;* FILE  stripkernal_c64.asm
;* Copyright (c) 1995, 1996, 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: stripkernal_c64.asm,v 1.3 2002/04/27 13:10:16 tlr Exp $
;*
;* DESCRIPTION
;*   this file contains a patch to remove tape and RS-232 routines from a
;*   c64 kernal.
;*   kernal revisions that will work is:
;*     revision 1 (901227-01)  $ff80=$aa (exists as NTSC only)
;*     revision 2 (901227-02)  $ff80=$00
;*     revision 3 (901227-03)  $ff80=$03
;*     sx64 kernal (251104-04) $ff80=$43
;*       (which has no tape support in the first place, but most of the
;*        code is still there.)
;*
;*   The only areas differing between original American kernals and other
;*   language kernals are these areas:
;*     $eb81-$ec43 keyboard decode tables for standard/SHIFTed/C=ed keys
;*     $ec78-$ecb8 keyboard decode tables for CTRLed keys
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
; original patch area (empty in all kernals)
	STARTPATCH $e4b7,$e4d2,$ea	;empty
	ENDPATCH

	IF	REMOVE_RS232
; e4d3-e4d9 used in kernal 901227-03 and kernal 251104-04 (sx)
; original patch area (empty in revision 2 kernals)  patch for RS232
; routine "test if start bit received from RS-232" at $ef90 in later
; kernals.
	STARTPATCH $e4d3,$e4d9,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 timings PAL
	STARTPATCH $e4ec,$e4ff,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; No check for RS232 ended!
	STARTPATCH $ed0e,$ed10,$ea
	nop
	nop
	nop
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_RS232
; RS232 routines
	STARTPATCH $eebb,$f0bc,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

	IF	REMOVE_TAPE
; Messages 'press play on tape' and 'press record & play on tape'
	STARTPATCH $f0d8,$f105,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_TAPE

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
	STARTPATCH $f72c,$fb8d,$ea	;empty
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

	IF	REMOVE_RS232
; RS232
	STARTPATCH $fec2,$ff47,$ea	;empty
	ENDPATCH
	ENDIF	;REMOVE_RS232

; unused
; fff6  52 52 42 59 'RRBY'
	STARTPATCH $fff6,$fff9,$ea	;empty
	ENDPATCH

; end of the patch file
	PATCHFOOTER
; eof
