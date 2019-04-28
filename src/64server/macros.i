;**************************************************************************
;**
;** Macros.i
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

;**************************************************************************
;**
;** stable branch macros
;** 6 cycles (7 cycles if branch occurs)
;** NO extra cycles for pagecrossing. needs 'slaskzp' zeropage address
;**
;** sbne, sbeq
;** 
;******
;* sbne *
	MAC	sbne
	IF [>[.+4]]-[>{1}]
	sta	slaskzp
	ELSE
	nop
	nop
	ENDIF
	bne	{1}
	ENDM

;* sbeq *
	MAC	sbeq
	IF [>[.+4]]-[>{1}]
	sta	slaskzp
	ELSE
	nop
	nop
	ENDIF
	beq	{1}
	ENDM

