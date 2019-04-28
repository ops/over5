;**************************************************************************
;**
;** sf_main.asm 
;** Copyright (c) 1995,1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;******

	PROCESSOR 6502

	seg	code

	INCLUDE	sf_mem.i
	INCLUDE	sf_rev.i
	INCLUDE libdef.i
	INCLUDE	Protocol.i
	INCLUDE	bl_mem.i

;*
;* No flash during transfer
;*
NOCOLOR		EQU	0
;*
;* code located under kernal
;*
UNDERKERNAL	EQU	0



copysrczp	EQU	$fb
copydestzp	EQU	$fd
pctempzp	EQU	$02

	ORG	$0801
;**************************************************************************
;**
;** Sysline
;**
;******
StartOfFile:
	dc.w	EndLine
SumStart:
	dc.w	1996
	dc.b	$9e,"2069 /T.L.R/",0
;	     1996 SYS2069 /T.L.R/
EndLine:
	dc.w	0

;**************************************************************************
;**
;** The Startup
;**
;******
SysAddress:

;*
;* Show Startup Message
;*
	ldy	#0
	lda	#<Init_MSG
	sta	copysrczp
	lda	#>Init_MSG
	sta	copysrczp+1
sa_lp3:
	lda	(copysrczp),y
	beq	sa_skp3
	jsr	$ffd2
	iny
	bne	sa_lp3
	inc	copysrczp+1
	jmp	sa_lp3
sa_skp3:


;*
;* install jumptable
;*
	ldx	#Jump_end-Jump_st
sa_lp1:
	lda	Jump_rel-1,x
	sta	Jump_st-1,x
	dex
	bne	sa_lp1

;*
;* install Tranceiver
;*
	ldx	#<Tranceiver_rel
	ldy	#>Tranceiver_rel
	stx	copysrczp
	sty	copysrczp+1
	ldx	#<Tranceiver_st
	ldy	#>Tranceiver_st
	stx	copydestzp
	sty	copydestzp+1


	ldy	#0
sa_lp2:
	lda	(copysrczp),y
	sta	(copydestzp),y
	inc	copysrczp
	bne	sa_skp1
	inc	copysrczp+1
sa_skp1:
	inc	copydestzp
	bne	sa_skp2
	inc	copydestzp+1
sa_skp2:
	lda	copydestzp
	cmp	#<Tranceiver_end
	bne	sa_lp2
	lda	copydestzp+1
	cmp	#>Tranceiver_end
	bne	sa_lp2

;*
;* Init Basic variables
;*
	jsr	$e453	

;*
;* setup NMI vector
;*
	ldx	#<Restore
	ldy	#>Restore
	stx	$fffa
	sty	$fffb

;*
;* setup IRQ vector
;*
	ldx	#<IRQpatch
	ldy	#>IRQpatch
	stx	$fffe
	sty	$ffff

;*
;* setup load vector
;*
	ldx	#<LoadPatch
	ldy	#>LoadPatch
	stx	$0330
	sty	$0331

;*
;* setup save vector
;*
	ldx	#<SavePatch
	ldy	#>SavePatch
	stx	$0332
	sty	$0333

;*
;* setup ICRNCH vector
;*
	ldx	#<ICRNCHPatch
	ldy	#>ICRNCHPatch
	stx	$0304
	sty	$0305

;*
;* perform NEW
;*
	jsr	$a644

;*
;* Exit to basic
;*
	jmp	$a474	;Exit to BASIC DIRECTMODE




;**************************************************************************
;**
;** The StartupMessage
;**
;******
;		 0000000000111111111122222222223333333333
;		 0123456789012345678901234567890123456789
;
Init_MSG:
	dc.b	147,142		;Cls, uppercase
	dc.b	"ีรรรรรรรรรรรรรรรรรรรรรรรรรรรรรรษ",13
	dc.b	"ยSERFILE "
	verrev5
	dc.b	" 38400 8N2 "
	IFCONST	PAL
	dc.b	" (PAL)ย",13
	ENDIF
	IFCONST	NTSC
	dc.b	"(NTSC)ย",13
	ENDIF
	dc.b	"ยDONE IN 1996 BY DANIEL KAHLIN.ย",13
	dc.b	"ยHANDLES PROGRAMS $0801-$F600. ย",13
	dc.b	"ยLOAD:    #L <FILENAME>        ย",13
	dc.b	"ย         /  <FILENAME>        ย",13
	dc.b	"ยSAVE:    #S <FILENAME>        ย",13
	dc.b	"ยCOMMAND: #C <COMMAND>         ย",13
	dc.b	"ย         .  <COMMAND>         ย",13
	dc.b	"ยDIR:     #$ OR $ OR .$        ย",13
	dc.b	"ยKILL:    #K                   ย",13
	dc.b	"สรรรรรรรรรรรรรรรรรรรรรรรรรรรรรรห"
	dc.b	0




;**************************************************************************
;**
;** Jump table
;**
;******
Jump_rel:
	RORG	$0334
Jump_st:

newjsr:
	php
	jsr	newjmp
	jsr	kernalout
	plp
	rts
newjmp:
	jsr	kernalin
thejmp:
	jmp	thejmp


;*
;* kernal in routine
;*
kernalin:
	pha
	lda	#$37
	sta	$01
	pla
	cli
	rts
;*
;* kernal out routine
;*
kernalout:
	sei
	pha
	lda	#$35
	sta	$01
	pla
	rts

;*
;* IRQ patch
;*
IRQpatch:
	pha
	txa
	pha
	tya
	pha
	jmp	($0314)
;*
;* Do Basic WarmStart
;*
Restore:
	sei
	lda	#$37
	sta	$01
	jmp	$fe69	;Restore basic!




;**************************************************************************
;**
;** the ICRNCH Patch
;**
;******
ICRNCHPatch:
;*
;* save stack ptr
;*
	tsx
;*
;* pop return address and check if no linenumber
;* (by checking the return address)
;*
	pla
	cmp	#$98
	bne	ip_ex1
	pla
	cmp	#$a4
	bne	ip_ex1

;*
;* check if for us
;*
	ldy	$7a
	lda	$0200,y
	cmp	#"#"
	beq	ip_Command
	cmp	#"/"
	beq	ip_CommandSlash
	cmp	#"$"
	beq	ip_CommandDollar
	cmp	#"."
	beq	ip_CommandDot

ip_ex1:
;*
;* not for us
;* restore stack and return
;*
	txs
	jmp	$a57c

;*
;* go to the appropriate commandhandler
;*
ip_Command:
	jsr	kernalout
	jmp	CommandHandler
ip_CommandSlash:
	jsr	kernalout
	jmp	ch_load
ip_CommandDollar:
	jsr	kernalout
	jmp	ch_dir
ip_CommandDot:
	jsr	kernalout
	jmp	ch_command



;**************************************************************************
;**
;** The Load Patch
;**
;** IN: $ae/$af startaddress
;**
;******
LoadPatch:
;*
;* check if devnum=6
;*
	ldx	$ba
	cpx	#6
	beq	lp_skp1
;*
;* no, jump to normal load.
;*
	jmp	$f4a5

lp_skp1:
;*
;* yes, call serfile.
;*
	jsr	$f5af	;print 'Searching'
	jsr	kernalout
	jsr	DoLoad
	jsr	kernalin
	ldx	$ae
	ldy	$af
	rts



;**************************************************************************
;**
;** The Save Patch
;**
;** IN: $c1/$c2 startaddress, $ae/$af endaddress
;**
;******
SavePatch:
;*
;* check if devnum=6
;*
	ldx	$ba
	cpx	#6
	beq	sp_skp1
;*
;* no, jump to normal save.
;*
	jmp	$f5ed


sp_skp1:
;*
;* yes, call serfile.
;*
	jsr	kernalout
	jsr	DoSave
	jsr	kernalin
	rts



Jump_end:
	REND
	echo	"Jump ",Jump_st,Jump_end






;**************************************************************************
;**
;** TheTranceiver part
;**
;******
Tranceiver_rel:
	RORG	$f600
Tranceiver_st:



;**************************************************************************
;**
;** SUBSTITUTES
;**
;******
newa43a:
	pha
	lda	#0
	beq	dojmp
newa474:
	pha
	lda	#2
	bne	dojmp
newa82c:
	pha
	lda	#4
	bne	dojsr
newe195:
	pha
	lda	#6
	bne	dojsr
newf715:
	pha
	lda	#8
	bne	dojsr
newfda3:
	pha
	lda	#10
	bne	dojsr
newffd2:
	pha
	lda	#12
	bne	dojsr
newffe4:
	pha
	lda	#14
	bne	dojsr
newfff0:
	pha
	lda	#16
	bne	dojsr
newLoadPatch:
	pha
	lda	#18
	bne	dojsr
newSavePatch:
	pha
	lda	#20
dojsr:
	jsr	setjmp
	pla
	jmp	newjsr
dojmp:
	jsr	setjmp
	pla
	jmp	newjmp

setjmp:
	stx	xtempzp
	tax
	lda	jumps,x
	sta	thejmp+1
	lda	jumps+1,x
	sta	thejmp+2
	ldx	xtempzp
	rts


jumps:
	dc.w	$a43a,$a474,$a82c,$e195,$f715,$fda3,$ffd2,$ffe4,$fff0
	dc.w	LoadPatch,SavePatch



;**************************************************************************
;**
;** CommandHandler
;**
;******
CommandHandler:
	jsr	$0073		;GETCHR
	beq	ch_syntaxerror
	cmp	#"L"
	beq	ch_load
	cmp	#"S"
	beq	ch_save
	cmp	#"C"
	beq	ch_command
	cmp	#"K"
	beq	ch_kill
	cmp	#"$"
	beq	ch_dir

ch_syntaxerror:
	ldx	#11	;syntax error
	dc.b	$2c
ch_devicenotpresent:
	ldx	#5	;device not present
	dc.b	$2c
ch_missingfilename:
	ldx	#8	;missing filename
	jmp	newa43a

;**************************************************************************
;**
;** #L or /
;**
;******
ch_load:
	jsr	getname
	lda	$b7
	beq	ch_missingfilename

	jsr	newLoadPatch
	lda	$90
	bne	ch_devicenotpresent
	jsr	newe195		;Print Status, fix end ptrs


	jmp	newa474		;Exit

;**************************************************************************
;**
;** #S
;**
;******
ch_save:
	jsr	getname
	lda	$b7
	beq	ch_missingfilename

	ldx	$2b
	ldy	$2c
	stx	$c1
	sty	$c2
	ldx	$2d
	ldy	$2e
	stx	$ae
	sty	$af
	jsr	newSavePatch
	lda	$90
	bne	ch_devicenotpresent

	jmp	newa474	;Exit


;**************************************************************************
;**
;** #C or #$ or $
;**
;******
ch_dir:
	lda	#"$"
	sta	buf_start
	lda	#1
	sta	$b7
	jsr	setbuf
	jmp	cc_skp1

ch_command:
CommandGreater:
	jsr	getname

cc_skp1:
	jsr	DoSrvCommand
	bcs	ch_devicenotpresent
	lda	$9d
	beq	cc_skp2
	jsr	ReadMessage
	bcs	ch_devicenotpresent
cc_skp2:
	jmp	newa474	;Exit
cc_fl1:
	ldx	#5	;device not present
	jmp	newa43a

;**************************************************************************
;**
;** #K
;**
;******
ch_kill:
	jsr	$0073
	beq	ck_skp1
	cmp	#":"
	bne	ch_syntaxerror
ck_skp1:
	ldx	#$7c
	ldy	#$a5
	stx	$0304
	sty	$0305
	ldx	#$9e
	ldy	#$f4
	stx	$0330
	sty	$0331
	ldx	#$dd
	ldy	#$f5
	stx	$0332
	sty	$0333
	jmp	newa474	;Exit


;**************************************************************************
;**
;** Alloc name
;**
;******
getname:
	ldx	#0
	ldy	#1
	jsr	$0073
	beq	gn_skp1
	cmp	#$22	;quote
	beq	gn_skp2
	cmp	#":"
	beq	gn_skp1

;*
;* no encapsulated string
;*
	dey
	lda	#$00
;*
;* set termination char
;*
gn_skp2:
	sta	$08
;*
;* copy string
;*
gn_lp1:
	lda	($7a),y
	beq	gn_skp1
	cmp	$08
	beq	gn_skp1
	sta	buf_start,x
	iny
	inx
	cpx	#buf_end-buf_start
	bne	gn_lp1
;*
;* setup parameters
;*
gn_skp1:
	stx	$b7

setbuf:
	lda	#<buf_start
	sta	$bb
	lda	#>buf_start
	sta	$bc

	ldx	#6
	txa
	ldy	#1
	stx	$ba
	sty	$b9
	sta	$b8

	rts


;**************************************************************************
;**
;** Do load and save + readmessage
;** RUN AT KERNAL LEVEL!
;** Be sure that no basic calls are made from here!
;**
;******
DoLoad:
	jsr	DoSrvLoad
	jmp	dls_skp1
DoSave:
	jsr	DoSrvSave
dls_skp1:
	bcc	dls_skp2
	cmp	#5	;'device not present'
	beq	dls_fl1
	sec
dls_skp2:

	lda	$9d	;direct mode?
	beq	dls_ex1
;*
;* read message from server
;*
	jsr	ReadMessage
	bcs	dls_fl1
	lda	#$00
	sta	$90
	clc
	rts
;*
;* set error
;*
dls_fl1:
	jsr	newf715
	sec
dls_ex1:
	rts



;**************************************************************************
;**
;** ReadMessage
;**
;******
ReadMessage:
rm_lp1:
	jsr	DoSrvReadString
	lda	bl_errorzp
	bne	rm_fl1
	bcc	rm_ex1

	ldx	#<press_MSG
	ldy	#>press_MSG
	jsr	printstr

rm_lp2:
	jsr	newa82c
	jsr	newffe4
	cmp	#$20
	bne	rm_lp2

	jmp	rm_lp1
rm_fl1:
	sec
rm_ex1:
	rts

press_MSG:
	dc.b	13,"<PRESS SPACE>",0

;**************************************************************************
;**
;** Print a str
;** X,Y=PTR
;**
;******
printstr:
	stx	currzp
	sty	currzp+1
	ldy	#0
ps_lp1:
	lda	(currzp),y	
	beq	ps_ex1
	jsr	newffd2
	iny
	bne	ps_lp1
	inc	currzp+1
	jmp	ps_lp1
ps_ex1:
	rts


;**************************************************************************
;**
;** Modules
;**
;******
	INCLUDE pr_SerFile.asm
	INCLUDE	pr_Support.asm
	INCLUDE	bl_Block.asm


;**************************************************************************
;**
;** Buffers
;**
;******
BUFFER		EQU	.
FileBufferStart	EQU	$2000	;bonus



Tranceiver_end:
	REND
	echo	"Tranceiver ",Tranceiver_st,Tranceiver_end

