;**************************************************************************
;**
;** pr_MemTransfer.asm
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

;**************************************************************************
;**
;** MemTransfer
;**
;******
MemTransfer:
	lda	BUFFER+HEADER_TYPE
	cmp	#TYPE_MEMTRANSFER
	bne	mt_fl2
	lda	BUFFER+HEADER_SUBTYPE
	cmp	#SUB_MT_WRITEMEM		;send to c64
	beq	mt_WriteMem
	cmp	#SUB_MT_READMEM			;file from c64
	beq	mt_ReadMem
	cmp	#SUB_MT_SYS			;startcode
	beq	mt_Sys
	cmp	#SUB_MT_RUN			;startcode run
	beq	mt_skp1

	lda	#RESP_NOTSUPPORTED
	jmp	mt_resp

mt_ex1:
	clc
	rts

mt_fl1:
	lda	#RESP_ERROR
mt_resp:
	jsr	SendResp
mt_fl2:
	sec
	rts	

mt_skp1:
	jmp	mt_Run

;**************************************************************************
;**
;** send memory.
;**
;******
mt_ReadMem:
;*** send ok! ***
	jsr	SendOK
	bcs	mt_fl1

;*** set start address ***
	lda	BUFFER+RMHD_START_L
	sta	currzp
	lda	BUFFER+RMHD_START_H
	sta	currzp+1
	lda	BUFFER+RMHD_END_L
	sta	endzp
	lda	BUFFER+RMHD_END_H
	sta	endzp+1

;*** send body ***
	jsr	sendbody
	bcs	mt_fl1

;*** wait ok ***
	jsr	WaitOK

	jmp	mt_ex1

;**************************************************************************
;**
;** Receive Memory
;**
;******
mt_WriteMem:
;*** send ok! ***
	jsr	SendOK
	bcs	mt_fl1


;*** set start address ***
	lda	BUFFER+WMHD_START_L
	sta	currzp
	lda	BUFFER+WMHD_START_H
	sta	currzp+1
	lda	BUFFER+WMHD_END_L
	sta	endzp
	lda	BUFFER+WMHD_END_H
	sta	endzp+1

;*** receive body ***
	jsr	recvbody
	bcs	mt_fl1

;*** send ok! ***
	jsr	SendOK
	bcs	mt_fl1

	jmp	mt_ex1


;**************************************************************************
;**
;** Do SYS
;**
;******
mt_Sys:
;*** send ok! ***
	jsr	SendOK
	bcs	mt_fl1

	jsr	UninitSerialSmall

;*** init system ***
	ldx	#$ff
	txs
	jsr	InitSystem

;*** set params ***
	sei
	ldx	BUFFER+SYHD_SP
	txs
;* push pc-1 *
	lda	BUFFER+SYHD_PC_L
	sec
	sbc	#1
	tax
	lda	BUFFER+SYHD_PC_H
	sbc	#0
	pha
	txa
	pha

;* push SR *
	lda	BUFFER+SYHD_SR
	pha
	IFNCONST	CARTRIDGE
	lda	BUFFER+SYHD_MEMORY
	sta	$01
;* set regs *
	lda	BUFFER+SYHD_AC
	ldx	BUFFER+SYHD_XR
	ldy	BUFFER+SYHD_YR
;* pop SR *
	plp
;* pop PC and GOOOOO!!! *
	rts
	ELSE
	ldx	#0
mts_lp1:
	lda	mt_syssersource,x
	sta	mt_sysser,x
	inx
	cpx	#mt_sysserend-mt_sysser
	bne	mts_lp1
	jmp	mt_sysser
	ENDIF

	IFCONST CARTRIDGE
;**************************************************************************
;**
;** Do sys
;**
;******
mt_syssersource:
	RORG	mt_sysserplace
	ECHO	"mt_sysser... ",.
mt_sysser:
	IFNCONST	KERNALPATCH
	lda	#%0001
	sta	C_CTRL0		;switch out cartridge
	ENDIF
	lda	BUFFER+SYHD_MEMORY
	sta	$01
;* set regs *
	lda	BUFFER+SYHD_AC
	ldx	BUFFER+SYHD_XR
	ldy	BUFFER+SYHD_YR
;* pop SR *
	plp
;* pop PC and GOOOOO!!! *
	rts
	ECHO	"... ",.
mt_sysserend:
	REND
	ENDIF




mtr_fl1:
	jmp	mt_fl1
;**************************************************************************
;**
;** Do RUN
;**
;******
mt_Run:
;*** send ok! ***
	jsr	SendOK
	bcs	mtr_fl1

	jsr	UninitSerialSmall

;*** init system ***
	ldx	#$ff
	txs
	jsr	InitSystem

;*** Init Basic! ***
	jsr	$e453	;Init basicvectors
	jsr	$e3bf	;Init Basicram

;* Set stack. IMPORTANT!! *
	ldx	#$fb
	txs

	lda	#"R"
	jsr	$ffd2
	lda	#"U"
	jsr	$ffd2
	lda	#"N"
	jsr	$ffd2

;*** Program specifik init ***
	lda	BUFFER+RUHD_HIMEM_L	;Program slutadress
	ldx	BUFFER+RUHD_HIMEM_H
	sta	$2d
	stx	$2e

;*** Initiera ***
	jsr	$ffcc	;CLRCH
	lda	#0
	sta	$13	;Keyb input
	jsr	$ff90	;Program mode

	IFNCONST CARTRIDGE
;*** Gör en total load/run! ***
	jsr	$a68e	;peka på progstart
	jsr	$a533	;länka
	jsr	$a659	;Run
	jmp	$a7b1	;Körkod
	ELSE
	ldx	#0
mtr_lp1:
	lda	mt_runnersource,x
	sta	mt_runner,x
	inx
	cpx	#mt_runnerend-mt_runner
	bne	mtr_lp1
	jmp	mt_runner
	ENDIF

	IFCONST CARTRIDGE
;**************************************************************************
;**
;** Do run
;**
;******
mt_runnersource:
	RORG	mt_runnerplace
	ECHO	"mt_runner... ",.
mt_runner:
	IFNCONST	KERNALPATCH
	lda	#%0001
	sta	C_CTRL0	;switch out cartridge
	ENDIF
	jsr	$a68e	;peka på progstart
	jsr	$a533	;länka
	jsr	$a659	;Run
	jmp	$a7b1	;Körkod
	ECHO	"... ",.
mt_runnerend:
	REND
	ENDIF

;**************************************************************************
;**
;** Init System
;**
;******
InitSystem:
;*** Do systeminitialization! ***
	sei
	cld
	jsr	$fda3	;Init interrupts /d418=0

	IFCONST	KERNALPATCH
; in the kernal patch fd50 is assumed to be patched to be fast and
; non destructive.
	jsr	$fd50
	ELSE
;*** $fd50 Init Memory Subst ***
	lda	#0
	tay
ins_lp1:
	sta	$0002,y
	sta	$0200,y
	sta	$0300,y
	iny
	bne	ins_lp1

	ldx	#$03
	lda	#$3c
	sta	$b2
	stx	$b3

	ldx	#$00
	ldy	#$a0
	jsr	$fd8c	;Set MemBounds
	ENDIF

	IFCONST	KERNALPATCH
; in the kernal patch fd15 is assumed to be patched to be
; non destructive.
	jsr	$fd15
	ELSE
;*** $fd15 Init Vectors subst ***
	ldy	#$1f
ins_lp2:
	lda	$fd30,y
	sta	$0314,y
	dey
	bpl	ins_lp2
	ENDIF

;*** Init VideoChip ***
	jsr	$ff5b	;Init video

	cli
	rts

; eof
