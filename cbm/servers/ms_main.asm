;**************************************************************************
;**
;** ms_main.asm 
;** Copyright (c) 1995,1996,2002 Daniel Kahlin <tlr@stacken.kth.se>
;**
;** TODO
;**   - implement the reloc
;**   - under basic / (under kernal?)
;**
;******

	PROCESSOR 6502


	seg	code

	INCLUDE	"ms_mem.i"
	INCLUDE "libdef.i"
	INCLUDE	"protocol.i"
	INCLUDE	"bl_mem.i"

STROUT	EQU	$ab1e
LINPRT	EQU	$bdcd
CHROUT	EQU	$ffd2
GETIN	EQU	$ffe4

rtsaddr	EQU	$0110	;BYTE
reloczp	EQU	$fb	;WORD
offsetzp	EQU	$fd	;BYTE
srczp	EQU	$fb	;WORD
destzp	EQU	$fd	;WORD


	IFCONST	RELOC
RELOC1	EQU	$0000
	ENDIF

	IFNCONST RELOC1
	ORG	$c600
	ELSE
	ORG	RELOC1
	ENDIF
Slave_st:
;**************************************************************************
;**
;** Start of the program! 
;**
;******
SysAddress:
;*
;* special code for relative addressing 
;* fucks up if NMI occurs somewhere
;*
	lda	#$60
	sta	rtsaddr
        jsr	rtsaddr
retaddr	EQU	.-1
	tsx
	lda.wx	[$0100-1],x
	sec
	sbc	#retaddr-Slave_st
	sta	reloczp
	bne	sa_bug		;low byte _must_ be same as low byte of assembled start addr. (which is $00 for now)
	lda.wx	[$0100],x
	sbc	#0
	sta	reloczp+1

; only single byte offsets for now.
	lda	reloczp+1	;thispage - lastpage -> acc
	sec
	ldy	#page-Slave_st
	sbc	(reloczp),y	;"sbc page" without using absolute addressing
	sta	offsetzp

	clc
	ldy	#reloctable_page_st-Slave_st
	adc	(reloczp),y
	sta	(reloczp),y
	
	ldx	#0
	ldy	#0
rl_lp1:
reloctable_page_st	EQU	.+2
	lda	[reloctable-Slave_st],x	;make it non-relocatable
	beq	rl_done
	clc
	adc	reloczp
	sta	reloczp
	lda	reloczp+1
	adc	#0	
	sta	reloczp+1
	lda	(reloczp),y
	clc
	adc	offsetzp
	sta	(reloczp),y
	inx
	bne	rl_lp1
page:
	dc.b	>Slave_st	;this shows where we were relocated before.


rl_done:

; check if reset patch was installed on the last known offset,
; correct the offset in the patch, and if it was installed,
; install it again with the updated offset.
	jsr	checkreset
	php
	lda	#>resetentry
	sta	resetentry_page_st
	plp
	bne	rl_skp1
	jsr	installreset
rl_skp1:

sa_menu:
;*** show startup page ***
	jsr	Startpage

sa_server:
	jsr	InitSerial

	jsr	Server
sa_bug:
	inc	$d020
	jmp	sa_bug

resetentry:
	ldx	#$05
	stx	$d016
	jsr	$fda3	;$7f->$dc00 (sets up $dc02 & $dc03

;* Do normal reset if 'space' key is pressed *
	lda	$dc01
	and	#%00010000
	beq	re_DoReset

;* Go to menu if '<-' key is pressed *
	lda	$dc01
	and	#%00000010
	php	; Z=1 if '<-' was pressed

	
	jsr	$fd15
;	jsr	$fd50
	jsr	$ff5b
	plp
	beq	sa_menu
	jmp	sa_server

; continue to normal reset
re_DoReset:
	ldx	#$05
	jmp	$fcef
	
;**************************************************************************
;**
;** Server
;**
;******
Server:
sv_lp1:
	lda	#<BUFFER
	sta	bl_currzp
	lda	#>BUFFER
	sta	bl_currzp+1

;*** receive command ***
	jsr	ReadBlockNoTimeout
	bcs	sv_fl1
	lda	bl_channelzp
	cmp	#15
	bne	sv_fl1

	lda	BUFFER
	cmp	#TYPE_MEMTRANSFER
	beq	sv_mem


	lda	#RESP_NOTSUPPORTED
	jsr	SendResp


sv_fl1:
	jmp	sv_lp1

;*** handle memoryrequest ***
sv_mem:
	jsr	MemTransfer
	jmp	sv_lp1


;**************************************************************************
;**
;** Modules
;**
;******
	INCLUDE	"pr_memtransfer.asm"
	INCLUDE	"pr_support.asm"
	INCLUDE	"bl_block.asm"

;**************************************************************************
;**
;** Startpage
;**
;******
Startpage:
	lda	#5
	sta	$d020
	sta	$d021
	lda	#13
	sta	646

sp_lp2:
	lda	#<Startup_MSG
	ldy	#>Startup_MSG
	jsr	$ab1e

	lda	#"$"
	jsr	CHROUT
	lda	#>Slave_st
	jsr	printhex
	lda	#<Slave_st
	jsr	printhex
	lda	#"-"
	jsr	CHROUT
	lda	#"$"
	jsr	CHROUT
	lda	#>Slave_end
	jsr	printhex
	lda	#<Slave_end
	jsr	printhex

	lda	#>Slave_st
	cmp	#$d0
	bcs	sp_skp3		; greater than or equal to $d0
	cmp	#$a0
	bcc	sp_skp4		; less than $a0
	cmp	#$c0		; less than $c0
	bcc	sp_skp3
sp_skp4:
	lda	#<Sys_MSG
	ldy	#>Sys_MSG	
	jsr	STROUT
	lda	#<Slave_st
	lda	#>Slave_st
	jsr	LINPRT
	
	lda	#")"
	jsr	CHROUT

sp_skp3:
	lda	#13
	jsr	CHROUT

	jsr	checkreset
	beq	sp_skp1

	lda	#<Reset_no_MSG
	ldy	#>Reset_no_MSG
	jsr	STROUT
	jmp	sp_skp2

sp_skp1:
	lda	#<Reset_MSG
	ldy	#>Reset_MSG
	jsr	STROUT

	lda	#>resetpatch_st
	jsr	printhex
	lda	#<resetpatch_st
	jsr	printhex
	lda	#"-"
	jsr	CHROUT
	lda	#"$"
	jsr	CHROUT
	lda	#>resetpatch_end
	jsr	printhex
	lda	#<resetpatch_end
	jsr	printhex
	lda	#13
	jsr	CHROUT

sp_skp2:
	lda	#<Keys_MSG
	ldy	#>Keys_MSG
	jsr	STROUT
sp_lp1:
	jsr	GETIN
	cmp	#" "
	beq	sp_server
	cmp	#"R"
	beq	sp_relocate
	cmp	#"P"
	beq	sp_toggleresetpatch
	jmp	sp_lp1
sp_server:
	rts

sp_toggleresetpatch:
	jsr	checkreset
	beq	sptrp_skp1
	jsr	installreset
	jmp	sp_lp2
sptrp_skp1:
	jsr	uninstallreset
	jmp	sp_lp2

sp_relocate:
	lda	#13
	jsr	CHROUT
	jsr	CHROUT

sprl_lp1:
	lda	#<New_MSG
	ldy	#>New_MSG
	jsr	STROUT

	lda	#"$"
	jsr	CHROUT
	lda	relocpage
	jsr	printhex
	lda	#$00
	jsr	printhex
	lda	#"-"
	jsr	CHROUT
	lda	#"$"
	jsr	CHROUT
	lda	relocpage
	clc
	adc	#>[Slave_end-Slave_st]
	jsr	printhex
	lda	#<[Slave_end-Slave_st]
	jsr	printhex	

	lda	#13
	jsr	CHROUT	
	lda	#145	;UP
	jsr	CHROUT
sprl_lp2:
	jsr	GETIN
	beq	sprl_lp2
	cmp	#3	;RUN/STOP
	beq	ssp_lp2
	cmp	#13	;RETURN
	beq	sprl_dorelocate
	cmp	#145	;UP
	beq	sprl_up
	cmp	#17	;DOWN
	bne	sprl_lp2

	dec	relocpage
	jmp	sprl_lp1
sprl_up:
	inc	relocpage
	jmp	sprl_lp1
ssp_lp2:
	jmp	sp_lp2

relocpage:
	dc.b	>Slave_st
sprl_dorelocate:
	lda	#<Slave_st
	sta	srczp
	sta	destzp
	lda	#>Slave_st
	sta	srczp+1
	lda	relocpage
	sta	destzp+1
	sta	jmp_page_st
	lda	#>Slave_st	;reinstate old relocpage
	sta	relocpage

	ldx	#relocator_end-relocator_st
dr_lp1:
	lda	relocator_rel-1,x
	sta	relocator_st-1,x
	dex
	bne	dr_lp1

	ldy	#0
	ldx	#0
	jmp	relocator_st

relocator_rel:
	RORG	$0110
relocator_st:
	sei
rlc_lp1:
	lda	(srczp),y
	sta	(destzp),y
	txa
	sta	(srczp),y
	iny
	bne	rlc_skp1
	inc	srczp+1
	inc	destzp+1
rlc_skp1:
	cpy	#<Slave_end
	bne	rlc_lp1
	lda	srczp+1
	cmp	#>Slave_end
	bne	rlc_lp1
	cli
jmp_page_st	EQU	[.-relocator_st+relocator_rel]+2
	jmp	$ff00
relocator_end:
	REND

;**************************************************************************
;**
;** printhex
;** Acc=byte
;**
;******
printhex:
	pha
	lsr
	lsr
	lsr
	lsr
	jsr	ph_skp1
	pla
ph_skp1:
	and	#$0f
	tax
	lda	hex_msg,x
	jmp	CHROUT

;**************************************************************************
;*
;* NAME  installreset
;*
;* DESCRIPTION
;*   Install a resident reset handler.
;*
;******
installreset:
; install the resetter
	ldx	#resetpatch_end-resetpatch_st
ir_lp1:
	lda	resetpatch_rel-1,x
	sta	resetpatch_st-1,x
	dex
	bne	ir_lp1
	rts

uninstallreset:
; uninstall the resetter
	lda	#0
	ldx	#resetpatch_end-resetpatch_st
ur_lp1:
	sta	resetpatch_st-1,x
	dex
	bne	ur_lp1
	rts

checkreset:
; install the resetter
	ldx	#resetpatch_end-resetpatch_st
cr_lp1:
	lda	resetpatch_rel-1,x
	cmp	resetpatch_st-1,x
	bne	cr_ex1
	dex
	bne	cr_lp1
cr_ex1:
	rts

resetpatch_rel:
	RORG	$8000
resetpatch_st:
	dc.w	Reset			;Reset!
	dc.w	NMI			;Normal NMI
	dc.b	$c3,$c2,$cd,$38,$30	;CBM80
Reset:
	sei
	lda	#$37
	sta	$01
	lda	#$2f
	sta	$00
resetentry_page_st	EQU	[.-resetpatch_st+resetpatch_rel]+2
	jmp	resetentry-Slave_st	;make it non relocatable
NMI:
	jmp	$fe5e		; Continue like nothing happened
resetpatch_end:
	REND

;**************************************************************************
;**
;** Startpage MESSAGES
;**
;******
Startup_MSG:
	dc.b	147,8,14	;HOME, No togglecase, UPPERCASE
	dc.b	"memslave/"
	dc.b    PACKAGE
	dc.b	" "
	dc.b	VERSION
	dc.b    "       "
	IFCONST PAL
	dc.b    " c64/pal"
	ENDIF
	IFCONST NTSC
	dc.b    "c64/ntsc"
	ENDIF
	dc.b	13,13
	dc.b	"cOPYRIGHT (c) 1995,1996,2000,2002",13
	dc.b	"  dANIEL kAHLIN <DANIEL@KAHLIN.NET>",13
	dc.b	13
	dc.b	"sPEED: 38400 8n2",13
	dc.b	"rESIDENT AT ",0
Sys_MSG:
	dc.b	" (sys ",0

Reset_MSG:
	dc.b	"rESET PATCH AT $",0
Reset_no_MSG:
	dc.b	"rESET PATCH NOT INSTALLED",13,0

New_MSG:
	dc.b	"nEW LOCATION (up/dn/ret) ",0
Keys_MSG:
	dc.b	13
	dc.b	"<r> RELOCATE MEMSLAVE",13
	dc.b	"<p> TOGGLE RESET PATCH",13
	dc.b	"<spacebar> ENTERS SERVER MODE",0

hex_msg:
	dc.b	"0123456789ABCDEF"

reloctable:
	IFCONST RELOC
	INCBIN	"reloc_tmp"
	ENDIF
;**************************************************************************
;**
;** Buffers
;**
;******
BUFFER		EQU	.

FileBufferStart	EQU	$2000	;bonus

Slave_end:

	ECHO	"Slave ",Slave_st,"-",Slave_end

; eof
