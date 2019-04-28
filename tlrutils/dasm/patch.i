;**************************************************************************
;*
;* FILE  patch.i
;* Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: patch.i,v 1.1 2002/04/27 13:15:56 tlr Exp $
;*
;* DESCRIPTION
;*   Write the patch using
;*     PATCHHEADER
;*     STARTPATCH <start0>,<end0>,<fill0>
;*     ENDPATCH
;*     STARTPATCH <start1>,<end1>,<fill1>
;*     ENDPATCH
;*      ...
;*     STARTPATCH <startn>,<endn>,<filln>
;*     ENDPATCH
;*     PATCHFOOTER
;*
;*   Assemble this using:
;*     dasm <sourcefile> -f2 -o<output> [-DIGNOREOVERFLOW]
;*   (if -DIGNOREOVERFLOW is present, assembly will not end if
;*    a patch is bigger that the defined block.)
;*
;*   The output patch file has the format: (all words are little endian)
;*     0x00: xx xx       ; (startaddress)
;*     0x02: 05 00       ; (length of header)
;*     0x04: 50 54 53 48 ; "PTCH"
;*     0x08: patch chunk #0
;*     xxxx: patch chunk #1
;*        ...
;*     xxxx: patch chunk #x
;*
;*   Each patch chunk has the format:
;*     0x00: <startaddr> ; startaddress of this patch
;*     0x02: <length>    ; length of this patch
;*     0x04...0x04+length-1 ; actual data to patch with.
;*
;******
	MAC PATCHHEADER
	ORG	$1000
	dc.b	"PTCH"
_patchedtotal	SET	0
_patchedtotalblocks	SET	0
_patchedfree	SET	0
_patchedfreeblocks	SET	0
	ENDM

	MAC PATCHFOOTER
	ECHO	"total patched bytes:",_patchedtotal,"(in",_patchedtotalblocks,"blocks)"
	ECHO	"total free bytes:",_patchedfree,"(in",_patchedfreeblocks,"blocks)"
	ECHO	"NOTE: adjacent blocks get merged automatically."
	ENDM

	MAC STARTPATCH
_fillchar	SET	{3}
	ORG	{1}
_patchstart	SET	.
_patchend	SET	{2}
	ENDM

	MAC ENDPATCH
_patchdataend	SET	.
_fillnum	SET	_patchend+1-_patchdataend
	IF	_fillnum < 0
	ECHO	"overflow by",-_fillnum,"bytes in area: ",_patchstart,"-",_patchend
	IFNCONST	IGNOREOVERFLOW
	ERR
	ELSE
_fillnum	SET	0	;set fillnum to 0 if we should ignore the overflow
	ENDIF
	ENDIF
	ds.b	_fillnum,_fillchar
;	ECHO	"patcharea:",_patchstart,"-",_patchend," (",_patchend+1-_patchstart,"bytes )"
	IF	_fillnum > 0
	ECHO	"     free:",_patchdataend,"-",_patchend," (",_fillnum,"bytes )"
_patchedfree	SET	_patchedfree+_fillnum
_patchedfreeblocks	SET	_patchedfreeblocks+1
	ENDIF
_patchedtotal	SET	_patchedtotal+_patchend+1-_patchstart
_patchedtotalblocks	SET	_patchedtotalblocks+1
	ENDM

; eof
