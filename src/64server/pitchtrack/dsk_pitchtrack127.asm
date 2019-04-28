;---------------------------------------
;         pitchtrack v1.27
;(c) Andreas "Pitch" Andersson 1995,96
;---------------------------------------

;---------------------------------------
;*** Usage ***
;---------------------------------------
;Always start with: jsr initdrive
;It transfers the program to the drive
;and inits the disk in the drive.
;
;  lda #18     ;Reads track 18
;  ldx #$00    ;to buffer at
;  ldy #$40    ;$4000
;  jsr gettrack
;  lda #18     ;Writes track 18
;  ldx #$00    ;from buffer at
;  ldy #$40    ;$4000
;  jsr sendtrack
;  lda #18     ;Verifies track 18
;  ldx #$00    ;with buffer at
;  ldy #$40    ;$4000
;  jsr verifytrack
;
;Exit with carry set = Error
;
;Sendtrack does NOT verify that the
;written data is correct, so always
;call verifytrack after sendtrack.
;
;End program with: jsr resetdrive
;
;---------------------------------------
listen	 EQU $ffb1
second	 EQU $ff93
chrout   EQU $ffa8
unlisten EQU $ffae
tracknumber EQU $ae
lastplusone EQU $af
temp     EQU $fc
temp2    EQU $fd
temp3    EQU $ff
temp4    EQU $96
p1       EQU $fa
p2       EQU $fd

gcrbin   EQU $f8e0
bingcr   EQU $f78f
dstrt    EQU $f50a
chkblk   EQU $f5e9
srch     EQU $f510
sync     EQU $f556
cnvbin   EQU $f497
conhdr   EQU $f934
errr     EQU $f969
ddra2    EQU $1c03
pcr2     EQU $1c0c
data2    EQU $1c01
buffer   EQU $0600
dtemp    EQU $6f
dtemp2   EQU $70
dtemp3   EQU $71
dtemp4   EQU $72
hdertrk  EQU $18
hdersect EQU $19
chksum   EQU $3a
bufpthi  EQU $31

initdrive
	lda #<driveprog
	sta p1
	lda #>driveprog
	sta p1+1
	lda #$00
	sta p2
	lda #$03
	sta p2+1
write
	lda $ba
	jsr listen
	lda #$6f
	jsr second
	lda #"M"
	jsr chrout
	lda #"-"
	jsr chrout
	lda #"W"
	jsr chrout
	lda p2
	jsr chrout
	lda p2+1
	jsr chrout
	lda #$20
	jsr chrout
	ldy #$00
writebyte
	lda (p1),y
	jsr chrout
	iny
	cpy #$20
	bcc writebyte
	jsr unlisten
	clc
	lda p1
	adc #$20
	sta p1
	bcc nocarry
	inc p1+1
nocarry
	clc
	lda p2
	adc #$20
	sta p2
	bcc nocarry2
	inc p2+1
nocarry2
	ldx p2+1
	cpx #$06
	bcc write
	lda $ba
	jsr listen
	lda #$6f
	jsr second
	lda #"M"
	jsr chrout
	lda #"-"
	jsr chrout
	lda #"W"
	jsr chrout
	lda #$00
	jsr chrout
	lda #$00
	jsr chrout
	lda #$01
	jsr chrout
	lda #$d0
	jsr chrout
	jsr unlisten

	jsr start
	jsr clear2send
	ldy #$50
longwait
	jsr waitawhile
	dey
	bne longwait
	lda #0
	jsr sendbyte
	jsr clear2get
	jsr getbyte
	jsr clear2send
	jsr waitawhile
	jmp end
resetdrive
	jsr start
	lda #$ff
	jsr sendbyte
end
	cli
	lda $d011
	ora #$10
	sta $d011
wait12
	rts
start
	sei
	lda $d011
	and #$ef
	sta $d011
waitblank1
	lda $d011
	bpl waitblank1
waitblank2
	lda $d011
	bmi waitblank2
	rts
gettrack
	sta tracknumber
	stx p1
	sty p2+1
	jsr start
	lda #1
	jsr sendbyte
	jsr waitawhile
	lda tracknumber
	jsr sendbyte
	jsr clear2get
	ldx #0
gettrackloop
	jsr getbyte
	cmp #$aa
	beq gettrackend
	cmp #21
	bcs gettrackfuckup
	clc
	adc p2+1
	sta p1+1
	jsr getsector
	inx
	jmp gettrackloop
gettrackend
	jsr clear2send
	jsr waitawhile
	clc
	jmp end
gettrackfuckup
	jsr clear2send
	jsr waitawhile
	sec
	jmp end
verifytrack
	sta tracknumber
	stx p1
	sty p2+1
	jsr start
	lda #0
	sta temp3
	lda #1
	jsr sendbyte
	jsr waitawhile
	lda tracknumber
	jsr sendbyte
	jsr clear2get
	ldx #0
verifytrackloop
	jsr getbyte
	cmp #$aa
	beq verifytrackend
	cmp #21
	bcs verifytrackfup
	clc
	adc p2+1
	sta p1+1
	jsr verifysector
	inx
	jmp verifytrackloop
verifytrackend
	lda #$ee
	cmp temp3
	beq verifytrackfup
	jsr clear2send
	jsr waitawhile
	clc
	jmp end
verifytrackfup
	jsr clear2send
	jsr waitawhile
	sec
	jmp end
sendtrack
	sta tracknumber
	stx p1
	sty p2+1
	tax
	lda noofsectors,x
	sta lastplusone
	jsr start
	lda #2
	jsr sendbyte
	jsr waitawhile
	lda tracknumber
	jsr sendbyte
	jsr clear2get
	jsr getbyte
	jsr clear2send
	jsr waitawhile
	ldx #0
sendtrackloop
	lda interleave,x
	jsr sendbyte
	jsr waitawhile
	lda interleave,x
	clc
	adc p2+1
	sta p1+1
	jsr sendsector
	jsr clear2get
	jsr getbyte
	jsr clear2send
	jsr waitawhile
	inx
	cpx lastplusone
	bne sendtrackloop
	lda #$ff
	jsr sendbyte
	jsr clear2get
notready
	jsr getbyte
	cmp #$ff
	beq notready
	jsr clear2send
	jsr waitawhile
	clc
	jmp end
getsector
	ldy #0
getsectorloop
	jsr getbyte
	sta (p1),y
	iny
	bne getsectorloop
	rts
verifysector
	clc
	ldy #0
verifysectorlp
	jsr getbyte
	cmp (p1),y
	beq byteok
	lda #$ee
	sta temp3
byteok
	iny
	bne verifysectorlp
	rts
sendsector
	ldy #0
sendsectorloop
	lda (p1),y
	jsr sendbyte
	iny
	bne sendsectorloop
	rts
getbyte	   ;Receive one byte
	lda $dd00
	bpl getbyte
	lda #0
	sta temp
	clc
	jsr wait12
	jsr wait12
	lda $dd00
	and #$c0
	ora temp
	ror
	ror
	sta temp
	nop
	nop
	nop
	nop
	lda $dd00
	and #$c0
	ora temp
	ror
	ror
	sta temp
	nop
	nop
	nop
	nop
	lda $dd00
	and #$c0
	ora temp
	ror
	ror
	sta temp
	nop
	nop
	nop
	nop
	lda $dd00
	and #$c0
	ora temp
	rts
sendbyte	  ;Send one byte
	sta temp
	lda $dd00
	and #$0f
	sta temp2
	sta $dd00
	lda temp
	ror
	ror
	and #$30
	ora temp2
	sta $dd00
	jsr wait12
	lda temp
	and #$30
	ora temp2
	sta $dd00
	nop
	asl temp
	asl temp
	lda temp
	and #$30
	ora temp2
	sta $dd00
	nop
	asl temp
	asl temp
	lda temp
	and #$30
	ora temp2
	sta $dd00
	nop
	jsr wait12
	lda $dd00
	ora #$30
	sta $dd00
	jsr wait12
	jsr wait12
	rts
clear2get
	lda $dd00
	and #$0f
	sta $dd00
	jsr wait12
	rts
clear2send
	lda $dd00
	ora #$30
	sta $dd00
	jsr waitawhile
	rts
waitawhile	 ;Wait a while
	txa
	pha
	ldx #$20
wawloop
	dex
	bne wawloop
	pla
	tax
noofsectors  ;# of sectors on tracks
	rts
	.byte 21,21,21,21,21,21,21
	.byte 21,21,21,21,21,21,21
	.byte 21,21,21
	.byte 19,19,19,19,19,19,19
	.byte 18,18,18,18,18,18
	.byte 17,17,17,17,17
interleave ;Interleave for sending
	   ;sectors to drive.
	   ;Has nothing to do with
	   ;the interleaving on the
	   ;disk.
	   ;Could be tweaked (?) for
	   ;better performance.
	.byte 0,9,1,10,2,11,3,12,4
	.byte 13,5,14,6,15,7,16,8
	.byte 17,18,19,20
teststring ;The monkey flies again...
	.text "apan flyger igen..."
	.byte 0

;---------------------------------------
;Driveprogram
;---------------------------------------
driveprog
offset  EQU driveprog-$0300
	sei
	jsr dclear2get
	ldy #0
	sty $00
commandloop EQU .-offset
;---------------------------------------
;Commands:
;	0 - init disk
;	1 - read track
;	2 - write track
;       ff - end program
;Everything else is ignored.
;---------------------------------------
	jsr dgetbyte
	beq doinit
	cmp #$ff
	beq doend
	sta dtemp3
	cmp #1
	beq doreadwrite
	cmp #2
	beq doreadwrite
	jmp commandloop
doinit
	jsr dclear2send
	cli
	jsr $d042 ;Do init
	sei
	lda #0
	jsr dsendbyte
	jsr dclear2get
	jmp commandloop
doend	  ;End program.
	ldx #0  ;Clear jobs.
	stx $00 ;(Just in case)
	stx $01
	stx $02
	stx $04
	stx $05
	cli
	rts
doreadwrite
	jsr dgetbyte
	sta $0a
	sta hdertrk
	jsr dclear2send
	lda #0
	sta $0b
	lda #$e0
	cli
	sta $02
readready
	lda $02
	bmi readready
	sei
	lda #$aa
	jsr dsendbyte
	jsr dclear2get
	jmp commandloop
dsendsector EQU .-offset ;Send one
	ldy #0	;sector
dsendsectorloop
	lda buffer,y
	jsr dsendbyte
	nop
	nop
	nop
	iny
	bne dsendsectorloop
	rts
dgetsector EQU .-offset ;Receive one
	ldy #0        ;sector
dgetsectorloop
	jsr dgetbyte
	sta buffer,y
	iny
	bne dgetsectorloop
	rts
dsendbyte EQU .-offset ;Send one byte
	sta dtemp4
	eor #$ff
	sta dtemp
	lda #0
	sta $1800
	nop
	ror dtemp
	rol
	asl
	ror dtemp
	rol
	asl
	sta $1800
	lda #0
	ror dtemp
	rol
	asl
	ror dtemp
	rol
	asl
	sta $1800
	lda #0
	ror dtemp
	rol
	asl
	ror dtemp
	rol
	asl
	sta $1800
	lda #$00
	ror dtemp
	rol
	asl
	ror dtemp
	rol
	asl
	sta $1800
	jsr dwait12
	nop
	nop
	nop
	lda #$02
	sta $1800
	jsr dwait12
	jsr dwait12
	lda dtemp4
dwait12 EQU .-offset
	rts
dgetbyte EQU .-offset ;Receive one byte
	txa
	sta dtemp4
	lda #%00000101
waitstart
	bit $1800
	bne waitstart
	lda #0
	sta dtemp
	jsr dwait12
	nop
	ldx #4
dgetloop
	lda $1800
	ror
	rol dtemp
	ror
	ror
	rol dtemp
	dex
	bne dgetloop
	lda temp4
	tax
	lda dtemp
	rts
dclear2get EQU .-offset
	lda #0
	sta $1800
	jsr dwait12
	rts
dclear2send EQU .-offset
	lda #2
	sta $1800
	jsr dwaitawhile
	rts
dwaitawhile EQU .-offset ;Wait a while
	txa
	pha
	ldx #$20
dwawloop
	dex
	bne dwawloop
	pla
	tax
	rts
toggleled EQU .-offset ;Toggled driveled
	lda $1c00
	eor #8
	sta $1c00
	rts
waitheader EQU .-offset ;Wait for header
waitheader0           ;on disk
	jsr sync
waitdataloop
	bvc waitdataloop
	clv
	lda data2
	cmp #$52
	bne waitheader0
	rts
eraseread EQU .-offset ;Clear table of
	ldx #20      ;read sectors
	lda #0
erasereadloop
	sta sectorsread,x
	dex
	bpl erasereadloop
	rts
sectorsread EQU .-offset
	.byte 0,0,0,0,0,0,0,0,0,0,0
	.byte 0,0,0,0,0,0,0,0,0,0

dwritetrack EQU .-offset ;Write one
	lda #$aa       ;track
	jsr dsendbyte
	jsr dclear2get
dwritetrackloop
dwritetracklp EQU .-offset
	jsr dgetbyte
	sta hdersect
	cmp #$ff
	beq dwritetrackend
	jsr dgetsector
	jsr dclear2send
	jsr chkblk
	sta chksum
	lda $1c00
	and #$10
	beq dwritefuckup
	jsr bingcr
	jsr mysrch
	ldx #9
byte8loop
	bvc byte8loop
	clv
	dex
	bne byte8loop
	lda #$ff
	sta ddra2
	lda pcr2
	and #$1f
	ora #$c0
	sta pcr2
	lda #$ff
	ldx #5
	sta data2
	clv
dwritesyncs
	bvc dwritesyncs
	clv
	dex
	bne dwritesyncs
	ldy #$bb
dwritebytes1
	lda $0100,y
dbytenotwrit1
	bvc dbytenotwrit1
	clv
	sta data2
	iny
	bne dwritebytes1
dwritebytes2
	lda buffer,y
dbytenotwrit2
	bvc dbytenotwrit2
	clv
	sta data2
	iny
	bne dwritebytes2
dbytenotwrit3
	bvc dbytenotwrit3
	lda pcr2
	ora #$e0
	sta pcr2
	lda #0
	sta ddra2
	lda hdersect
	jsr dsendbyte
	jsr dclear2get
	jmp dwritetracklp
dwritefuckup
	lda #$08
	jmp errr
dwritetrackend
	lda #0
	sta $02
	lda #$01
	jmp errr
dwritetrbogus
	jmp dwritetrack

	ORG driveprog+$0200

	jsr toggleled ;Read or write
	lda #>buffer  ;one track
	sta bufpthi
	lda dtemp3
	cmp #2
	beq dwritetrbogus
	lda $0a       ;Code to read
	jsr $f24b     ;track starts
	sta dtemp2    ;here
	sta dtemp3
	jsr eraseread
dreadtrackloop EQU .-offset
dreadtrackloop0
	jsr waitheader
	ldx #0
byteloop1
	bvc byteloop1
	clv
	lda data2
	sta $25,x
	inx
	cpx #7
	bne byteloop1
	jsr cnvbin
	ldy #4
	lda #0
dchecksum
	eor $16,y
	dey
	bpl dchecksum
	cmp #0
	bne dreadtrackloop0
	ldx dtemp2
	dex
	cpx hdersect
	bcc dreadtrackloop0
	ldx hdersect
	inx
	cpx dtemp2
	bne raj1
	ldx #0
raj1
	stx hdersect
	lda sectorsread,x
	bne dreadtrackloop0
	lda #$ff
	sta sectorsread,x
	txa
	jsr dsendbyte
	jsr waitheader
	jsr sync
byteloop2
	bvc byteloop2
	clv
	lda data2
	sta buffer,y
	iny
	bne byteloop2
	ldy #$ba
byteloop3
	bvc byteloop3
	clv
	lda data2
	sta $0100,y
	iny
	bne byteloop3
	jsr gcrbin
	jsr dsendsector
	dec dtemp3
	lda dtemp3
	beq dreadtrackend
	jmp dreadtrackloop
dreadtrackend
	jsr toggleled
	lda #$01
	jmp errr
mysrch   EQU .-offset ;Search for a
	lda $12     ;particular header
	sta $16
	lda $13
	sta $17
	lda #0
	eor $16
	eor $17
	eor $18
	eor $19
	sta $1a
	jsr conhdr
compareheader
	jsr sync
	ldy #0
waithdrbyte
	bvc waithdrbyte
	clv
	lda data2
	cmp $24,y
	bne compareheader
	iny
	cpy #8
	bne waithdrbyte
	rts

