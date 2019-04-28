;**************************************************************************
;*
;* FILE  newkernal_c64.asm
;* Copyright (c) 2002 Daniel Kahlin <daniel@kahlin.net>
;* Written by Daniel Kahlin <daniel@kahlin.net>
;* $Id: newkernal_c64.asm,v 1.8 2002/05/12 14:13:32 tlr Exp $
;*
;* DESCRIPTION
;*   Improvements and stuff for a c64 kernal.
;*
;******
	processor 6502
	INCLUDE	"../../tlrutils/dasm/patch.i"
	INCLUDE	"newkernal_mem.i"
        INCLUDE "../servers/libdef.i"
        INCLUDE "../servers/protocol.i"
        INCLUDE "../servers/bl_mem.i"


FileBufferStart	EQU	$0801
BUFFER		EQU	$0334
;* No flash during transfer
NOCOLOR		EQU	1
;* code located in rom
;UNDERKERNAL	EQU	1
CARTRIDGE	EQU	1
KERNALPATCH	EQU	1

;**************************************************************************
;*
;* Configuration
;*
;******
; fix the $fd15 bug?
FIX_FD15	EQU	1

TEXT_COLOR	EQU	0
BKGND_COLOR	EQU	15
BORDER_COLOR	EQU	6

; start of the patch
	PATCHHEADER

;**************************************************************************
;*
;* Improvements and bugfixes
;*
;******

	IF	FIX_FD15
;**************************************************************************
;*
;* bug: fd30-fd4f under rom gets trashed when setting up the vectors
;*      from rom.
;*
;******
;FD15 A2 30     LDX #$30
;FD17 A0 FD     LDY #$FD
;FD19 18        CLC
;FD1A 86 C3     STX $C3
;FD1C 84 C4     STY $C4
;FD1E A0 1F     LDY #$1F
;FD20 B9 14 03  LDA $0314,Y        FD20 B1 C3     LDA ($C3),Y
;FD24 B0 02     BCS $FD27    --->  FD22 90 05     BCC $FD29
;FD25 B1 C3     LDA ($C3),Y        FD24 B9 14 03  LDA $0314,Y
;FD27 91 C3     STA ($C3),Y
;FD29 99 14 03  STA $0314,Y
;FD2C 88        DEY
;FD2D 10 F1     BPL $FD20
;FD2F 60        RTS

	STARTPATCH $fd20,$fd26,$ea
	lda	($c3),y
	bcc	$fd29
	lda	$0314,y
	ENDPATCH
	ENDIF	;FIX_FD15


;**************************************************************************
;*
;* bug: memtest takes a long time, and RAM under the first encountered ROM
;*      byte gets trashed.
;*
;******
; FD50 A9 00     LDA #$00
; FD52 A8        TAY
; FD53 99 02 00  STA $0002,Y
; FD56 99 00 02  STA $0200,Y
; FD59 99 00 03  STA $0300,Y
; FD5C C8        INY
; FD5D D0 F4     BNE $FD53
; FD5F A2 3C     LDX #$3C
; FD61 A0 03     LDY #$03
; FD63 86 B2     STX $B2
; FD65 84 B3     STY $B3
; FD67 A8        TAY
; FD68 A9 03     LDA #$03
; FD6A 85 C2     STA $C2
; FD6C E6 C2     INC $C2
; FD6E B1 C1     LDA ($C1),Y
; FD70 AA        TAX
; FD71 A9 55     LDA #$55
; FD73 91 C1     STA ($C1),Y
; FD75 D1 C1     CMP ($C1),Y
; FD77 D0 0F     BNE $FD88
; FD79 2A        ROL A
; FD7A 91 C1     STA ($C1),Y
; FD7C D1 C1     CMP ($C1),Y
; FD7E D0 08     BNE $FD88
; FD80 8A        TXA
; FD81 91 C1     STA ($C1),Y
; FD83 C8        INY
; FD84 D0 E8     BNE $FD6E
; FD86 F0 E4     BEQ $FD6C
; FD88 98        TYA
; FD89 AA        TAX
; FD8A A4 C2     LDY $C2
; FD8C 18        CLC
; FD8D 20 2D FE  JSR $FE2D
; FD90 A9 08     LDA #$08
; FD92 8D 82 02  STA $282
; FD95 A9 04     LDA #$04
; FD97 8D 88 02  STA $288
; FD9A 60        RTS

;	STARTPATCH $fd20,$fd26,$ea
;	ENDPATCH

;**************************************************************************
;*
;*  
;*
;******
;E5EE A2 09     LDX #$09
;E5F0 78        SEI
;E5F1 86 C6     STX $C6
;E5F3 BD E6 EC  LDA $ECE6,X
;E5F6 9D 76 02  STA $0276,X
;E5F9 CA        DEX
;E5FA D0 F7     BNE $E5F3
; note, the buffer length may at max be 15 bytes, if it exceeds 10,
; $0281/$0282 MEMSTR, $0283/$0284 MEMSIZ, and $0285 TIMOUT will be
; destroyed, which can cause problems.
	STARTPATCH $e5ee,$e5ef,$ea
	ldx	#loadrun_msg_end-loadrun_msg
	ENDPATCH
	STARTPATCH $e5f3,$e5f5,$ea
	lda	loadrun_msg-1,x
	ENDPATCH
	STARTPATCH $f0d8,$f0e6,$ea
loadrun_msg:
	dc.b	"L",["O"|$80],34,"*",34,",8,1",13
	dc.b	"R",["U"|$80],13
loadrun_msg_end:
	ENDPATCH
; the original "LOAD<cr>RUN<cr>" string
	STARTPATCH $ece7,$ecef,$ea
	ENDPATCH

;**************************************************************************
;*
;* Change startup color.
;*
;******
; In $e518, part of CINT ($ff81)
; E534 A9 0E     LDA #$0E
; E536 8D 86 02  STA $0286
	STARTPATCH $e535,$e535,$ea
	dc.b	TEXT_COLOR	;cursor color
	ENDPATCH

; VIC-II init-table 
; Copied to $d000-$d02e by the routine at $e5a0)
; Note that this is one byte short, and that the last value ($d02e, 
; sprite #8 color) gets set to the first byte of the "load/run" string,
; which is $4c.
; ECB9  00 00 00 00 00 00 00 00
; ECC1  00 00 00 00 00 00 00 00
; ECC9  00 9B 37 00 00 00 08 00
; ECD1  14 0F 00 00 00 00 00 00
; ECD9  0E 06 01 02 03 04 00 01
; ECE1  02 03 04 05 06 07
	STARTPATCH $ecd9,$ecda,$ea
	dc.b	BORDER_COLOR	;border color     ($d020)
	dc.b	BKGND_COLOR	;background color ($d021)
	ENDPATCH


;**************************************************************************
;*
;* reset hook
;*
;******
; FCE2 A2 FF     LDX #$FF
; FCE4 78        SEI
; FCE5 9A        TXS
; FCE6 D8        CLD
; FCE7 20 02 FD  JSR $FD02
; FCEA D0 03     BNE $FCEF
; FCEC 6C 00 80  JMP ($8000)
	STARTPATCH $fce7,$fce9,$ea
	jmp	earlyreset
	ENDPATCH

	STARTPATCH $fe75,$feb5,$ea 
	dc.b	"T.L.R RULES!"
	ENDPATCH

	STARTPATCH $fec2,$ff47,$ea
earlyreset:
;Non destructive key check (SpeedDos-Plus)
	ldx	#$00
	stx	$dc03
	dex
	ldy	$dc02
	stx	$dc02
	ldx	$dc00
	lda	#%01111111
	sta	$dc00
	lda	$dc01
	stx	$dc00
	sty	$dc02
; here we have the data from the key row in acc (just shift and bcc)
; WRITE TO PORT A               READ PORT B (56321, $DC01)
; 56320/$DC00
;          Bit 7   Bit 6   Bit 5   Bit 4   Bit 3   Bit 2   Bit 1   Bit 0
; 
; Bit 7    STOP    Q       C=      SPACE   2       CTRL    <-      1
;
; Bit 6    /       ^       =       RSHIFT  HOME    ;       *       LIRA
;
; Bit 5    ,       @       :       .       -       L       P       +
;
; Bit 4    N       O       K       M       0       J       I       9
;
; Bit 3    V       U       H       B       8       G       Y       7
;
; Bit 2    X       T       F       C       6       D       R       5
;
; Bit 1    LSHIFT  E       S       Z       4       A       W       3
;
; Bit 0    CRSR DN F5      F3      F1      F7      CRSR RT RETURN  DELETE
;
	lsr
	lsr
	bcc	er_runmemslave	; Key "<-"
	lsr
	bcc	er_flash	; Key "Ctrl"
	lsr
	lsr
	bcc	er_skipcheck	; Key "Space"
	IF	0
	lsr
	bcc	er_commodore	; Key "C="
	lsr
	lsr
	bcc	er_stop		; Key "Stop"
	ENDIF

; check for break

; preserve data dir settings
;	ldx	$dd02
;	ldy	$dd03

; setup data dir for RS232
	lda	#%00000110
	sta	$dd03	;RS232 Data dir
	lda	$dd02	
	ora	#%00000100
	sta	$dd02	;RS232 Data dir
	lda	$dd00
	ora	#%00000100
	sta	$dd00	;Set TxD right.

; check if RxD is being held low.
	lda	#%00000001
	bit	$dd01
	bne	er_skp1		;No break, just skip.

; wait for 400ms seconds, to see if break ended.
	ldx	#200
er_lp1:
	jsr	$eeb3		;millisecond delay (trashes Acc)
	jsr	$eeb3		;millisecond delay
	
	lda	#%00000001
	bit	$dd01
	bne	er_runmemslave  ;Break ended!

	dex
	bne	er_lp1

er_skp1:
; put it back
;	stx	$dd02
;	sty	$dd03

	jsr	$fd02	;check for autostart cartridge (sets X=5 if no autostart)
er_continue:
	jmp	$fcea	;return to normal reset (if Z=1 autostart cartridge
			;			 will run.)
er_skipcheck:
	ldx	#$05	;set up x like after $fd02 was called
	bne	er_continue

er_runmemslave:
	ldx	#$05	;set up x like after $fd02 was called
	stx	$d016
	jsr	$fda3
	jsr	$fd15
	jsr	$fd50
	jsr	$ff5b
	jmp	MemSlaveServer

er_flash:
rms_lp1:
	inc	$d020
	jmp	rms_lp1
	ENDPATCH


; E394 20 53 E4  JSR $E453
; E397 20 BF E3  JSR $E3BF
; E39A 20 22 E4  JSR $E422
; E39D A2 FB     LDX #$FB
; E39F 9A        TXS
; E3A0 D0 E4     BNE $E386

; E422 A5 2B     LDA $2B
; E424 A4 2C     LDY $2C
; E426 20 08 A4  JSR $A408
; E429 A9 73     LDA #$73
; E42B A0 E4     LDY #$E4
; E42D 20 1E AB  JSR $AB1E
; E430 A5 37     LDA $37
; E432 38        SEC
; E433 E5 2B     SBC $2B
; E435 AA        TAX
; E436 A5 38     LDA $38
; E438 E5 2C     SBC $2C
; E43A 20 CD BD  JSR $BDCD
; E43D A9 60     LDA #$60
; E43F A0 E4     LDY #$E4
; E441 20 1E AB  JSR $AB1E
; E444 4C 44 A6  JMP $A644

	STARTPATCH $e444,$e446,$ea
	jmp	basiccoldhook
	ENDPATCH
	STARTPATCH $f409,$f49d,$ea
basiccoldhook:
; need flag here for disabled start.
	lda	#<coldstart_msg
	ldy	#>coldstart_msg
	jsr	$ab1e	;print additional startup

	IF	0
;* setup load vector
	ldx	#<LoadPatch
	ldy	#>LoadPatch
	stx	$0330
	sty	$0331

;* setup save vector
	ldx	#<SavePatch
	ldy	#>SavePatch
	stx	$0332
	sty	$0333

;* setup ICRNCH vector
	ldx	#<ICRNCHPatch
	ldy	#>ICRNCHPatch
	stx	$0304
	sty	$0305
	ENDIF

; run "NEW" (the instruction that was replaced by our hook)
	jmp	$a644

coldstart_msg:
	IFCONST	PAL
	dc.b	13,"   OVER5 EXTENSIONS ("
	dc.b	PACKAGE
	dc.b	" "
	dc.b	VERSION
	dc.b	") PAL",13,0
	ENDIF
	IFCONST	NTSC
	dc.b	13,"  OVER5 EXTENSIONS ("
	dc.b	PACKAGE
	dc.b	" "
	dc.b	VERSION
	dc.b	") NTSC",13,0
	ENDIF

;**************************************************************************
;*
;* MemSlaveServer
;*
;******
	echo	"memslaveserver",.
MemSlaveServer:
	jsr	InitSerial

mss_lp1:
;*** receive command ***
	jsr	SetupBufferPtr
	jsr	ReadBlockNoTimeout
	bcs	mss_lp1
	lda	bl_channelzp
	cmp	#15
	bne	mss_lp1

	lda	BUFFER
	cmp	#TYPE_MEMTRANSFER
	bne	mss_fl1

;*** handle memoryrequest ***
	jsr	MemTransfer
	jmp	mss_lp1

mss_fl1:
	lda	#RESP_NOTSUPPORTED
	jsr	SendResp
	jmp	mss_lp1

	ENDPATCH


	STARTPATCH $f72c,$fb8d,$ea	;THIN by $0a bytes.
sprt_st:
	INCLUDE	"../servers/pr_support.asm"
	echo	"pr_support.asm",sprt_st,"-",.-1,.-sprt_st
bl_st:
	INCLUDE	"../servers/bl_block.asm"
	echo	"bl_block.asm",bl_st,"-",.-1,.-bl_st
	ENDPATCH

	STARTPATCH $fb97,$fcbc,$ea	;THIN by $02 bytes.
mt_st:
	INCLUDE	"../servers/pr_memtransfer.asm"
	echo	"pr_memtransfer.asm",mt_st,"-",.-1,.-mt_st
	ENDPATCH

	STARTPATCH $eebb,$f0bc,$ea	;THIN by $16 bytes.
sf_st:
	INCLUDE	"../servers/pr_serfile.asm"
	echo	"pr_serfile.asm",sf_st,"-",.-1,.-sf_st
	ENDPATCH

; end of the patch file
	PATCHFOOTER
; eof
