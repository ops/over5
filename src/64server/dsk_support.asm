;**************************************************************************
;**
;** dsk_support.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;** 
;******


	IFNCONST NOCOLOR
;**************************************************************************
;**
;** colorroutines
;**
;******
dsk_loadcolor:
	lda	d_modeflags
	and	#DMODE_NOCOLOR
	bne	dlc_ex1
	lda	#LOADCOLOR
	sta	$d020
dlc_ex1:
	rts
;***
dsk_savecolor:
	lda	d_modeflags
	and	#DMODE_NOCOLOR
	bne	dsc_ex1
	lda	#SAVECOLOR
	sta	$d020
dsc_ex1:
	rts
;***
dsk_statuscolor:
	lda	d_modeflags
	and	#DMODE_NOCOLOR
	bne	dstc_ex1
	lda	#STATUSCOLOR
	sta	$d020
dstc_ex1:
	rts
;***
dsk_commandcolor:
	lda	d_modeflags
	and	#DMODE_NOCOLOR
	bne	dcoc_ex1
	lda	#COMMANDCOLOR
	sta	$d020
dcoc_ex1:
	rts
;***
dsk_togglecolor:
	lda	d_modeflags
	and	#DMODE_NOCOLOR
	bne	dtc_ex1
	lda	$d020
	eor	#8
	sta	$d020
dtc_ex1:
	rts

	ENDIF



	IFCONST CARTRIDGE
;**************************************************************************
;**
;** install get mem
;**
;******
dsk_installgetmem:
	ldx	#0
igm_lp1:
	lda	dsk_getmemsource,x
	sta	dsk_getmem,x
	inx
	cpx	#dsk_getmemend-dsk_getmem
	bne	igm_lp1
	rts


;**************************************************************************
;**
;** Special get mem
;**
;******
dsk_getmemsource:
	RORG	dsk_getmemplace
	ECHO	"dsk_getmem... ",.
dsk_getmem:
	stx	$01
	lda	(d_currzp),y
	ldx	#$37
	stx	$01
	rts
	ECHO	"... ",.
dsk_getmemend:
	REND

	ENDIF



