
;**************************************************************************
;**
;** dsk_fdiskold.asm
;** adapted in 1995 by Daniel Kahlin <tlr@stacken.kth.se>
;**
;** Turbodisk FORMAT 1541part
;**
;******

z0011	equ	$0011	
z0012	equ	$0012	
z0013	equ	$0013	
z0022	equ	$0022	
z0030	equ	$0030	
z0031	equ	$0031	
z0032	equ	$0032	
z0039	equ	$0039	
z003a	equ	$003a	
z0041	equ	$0041	
z0043	equ	$0043	
z0044	equ	$0044	
z004a	equ	$004a	
z004b	equ	$004b	
z004d	equ	$004d	
z0052	equ	$0052	
z00a0	equ	$00a0	
xe0100	equ	$0100	
xe02f9	equ	$02f9	
xe02fa	equ	$02fa	
xe02fb	equ	$02fb	
xe02fc	equ	$02fc	
xe02fd	equ	$02fd	
xe0300	equ	$0300	
xe1805	equ	$1805	
xe1c00	equ	$1c00	
xe1c01	equ	$1c01	
xe1c03	equ	$1c03	
xe1c0c	equ	$1c0c	
xjc1c8	equ	$c1c8	
xsf24b	equ	$f24b	
xsf5e9	equ	$f5e9	
xsf78f	equ	$f78f	
xsfde5	equ	$fde5	
xsfdf5	equ	$fdf5	
xsfe00	equ	$fe00	
xsfe30	equ	$fe30	

	RORG	$0400	
fdiskstart:
e0400:
bam:
	dc.b	$12,$01,$41,$00,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f;"a.......
	dc.b	$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f;"........
	dc.b	$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f;"........
	dc.b	$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$15,$ff,$ff,$1f;"........
	dc.b	$15,$ff,$ff,$1f,$15,$ff,$ff,$1f,$11,$fc,$ff,$07,$13,$ff,$ff,$07;"....ü...
	dc.b	$13,$ff,$ff,$07,$13,$ff,$ff,$07,$13,$ff,$ff,$07,$13,$ff,$ff,$07;"........
	dc.b	$13,$ff,$ff,$07,$12,$ff,$ff,$03,$12,$ff,$ff,$03,$12,$ff,$ff,$03;"........
	dc.b	$12,$ff,$ff,$03,$12,$ff,$ff,$03,$12,$ff,$ff,$03,$11,$ff,$ff,$01;"........
	dc.b	$11,$ff,$ff,$01,$11,$ff,$ff,$01,$11,$ff,$ff,$01,$11,$ff,$ff,$01;"........
fnameid:
	dc.b	$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0;"                
	dc.b	$a0,$a0,$a0,$a0,$a0,$32,$41,$a0,$a0,$a0,$a0,$00,$00,$00,$00,$00;"     2a    .....
	dc.b	$00,$a0,$a0,$00,$00,$00,$00,$00,$00,$a0,$a0,$00,$00,$00,$00,$00;".  ......  .....
	dc.b	$00,$a0,$a0,$00,$00,$00,$00,$00,$00,$a0,$a0,$00,$00,$00,$00,$00;".  ......  .....
	dc.b	$00,$a0,$a0,$00,$00,$00,$00,$00,$00,$a0,$a0,$00,$00,$00,$00,$00;".  ......  .....
	dc.b	$00,$a0,$a0,$00,$00,$00,$00,$00,$00,$a0,$a0,$00,$00,$00,$00,$00;".  ......  .....
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


FormatEntry:
	sei	
	lda	$04a2
	sta	z0012
	lda	$04a3
	sta	z0013
	nop
	lda	#<s0726	;VERIFY	(<s0796 no verify)
	sta	b05fc+1
	lda	#$a0
	sta	$04a7
	lda	xe1c00
	ora	#$0c
	sta	xe1c00
	and	#$10
	bne	b0527
	lda	#$a6
	jmp	j060f

b0527:
	sec	
	lda	z0022
	adc	#$01
	sta	z004a
b052e:
	jsr	s0632
	dec	z004a
	bne	b052e
	ldx	#$00
	stx	z004b
	jsr	s0639
	lda	#$01
	sta	z0022
j0540:
	jsr	xsf24b
	sta	z0043
	txa	
	asl
	asl
	asl
	asl
	asl
	sta	z0044
	lda	xe1c00
	and	#$9f
	ora	z0044
	sta	xe1c00
	jsr	s0653
	lda	#$55
	sta	xe1c01
	ldy	#$00
	sty	z004d
b0563:
	lda	z0039
	sta	xe0300,y
	iny	
	iny	
	lda	z004d
	sta	xe0300,y
	iny	
	lda	z0022
	sta	xe0300,y
	iny	
	lda	z0013
	sta	xe0300,y
	iny	
	lda	z0012
	sta	xe0300,y
	iny	
	lda	#$0f
	sta	xe0300,y
	iny	
	sta	xe0300,y
	iny	
	lda	xe02fa,y
	eor	xe02fb,y
	eor	xe02fc,y
	eor	xe02fd,y
	sta	xe02f9,y
	inc	z004d
	lda	z004d
	cmp	z0043
	bcc	b0563
	tya	
	pha	
	lda	#$00
	sta	z0030
	lda	#$03
	sta	z0031
	jsr	xsfe30
	pla	
	tay	
	dey	
	jsr	xsfde5
	jsr	xsfdf5
	lda	#$00
	sta	z0032
b05bd:
	jsr	s0661
	dec	z004d
	bne	b05bd
b05c4:
	bvc	b05c4
	clv	
	jsr	xsfe00
	lda	#$00
	sta	z0032
	lda	z0022
	cmp	#$12
	bne	b05fc
	lda	#$04
	sta	z0031
	jsr	xsf5e9
	sta	z003a
	jsr	xsf78f
	jsr	s06fe
	bne	j060f
	ldx	#$09
b05e7:
	bvc	b05e7
	clv	
	dex	
	bne	b05e7
	jsr	s0653
	jsr	s06bb
	jsr	s06c9
b05f6:
	bvc	b05f6
	clv	
	jsr	xsfe00
b05fc:
	jsr	s0726
	bne	j060f
	inc	z0022
	jsr	s0628
	lda	z0022
	cmp	#$24
	beq	b0611
	jmp	j0540
j060f:
	sta	z004b
b0611:
	lda	xe1c00
	and	#$f3
	sta	xe1c00
	lda	#$ec
	sta	xe1c0c
	lda	z004b
	beq	b0627
	and	#$7f
	jmp	xjc1c8
b0627:
	rts	
s0628:
	jsr	s062b
s062b:
	ldx	xe1c00
	inx	
	jmp	s0639
s0632:
	jsr	s0635
s0635:
	ldx	xe1c00
	dex	
s0639:
	txa	
	and	#$03
	sta	z0044
	lda	xe1c00
	and	#$fc
	ora	z0044
	sta	xe1c00
	ldy	#$06
	ldx	#$00
b064c:
	dex	
	bne	b064c
	dey	
	bne	b064c
	rts	
s0653:
	lda	#$ce
	sta	xe1c0c
	lda	#$ff
	sta	xe1c01
	sta	xe1c03
	rts	
s0661:
	jsr	s06bb
	ldx	#$0a
	ldy	z0032
b0668:
	bvc	b0668
	clv	
	lda	xe0300,y
	sta	xe1c01
	iny	
	dex	
	bne	b0668
	ldx	#$09
b0677:
	bvc	b0677
	clv	
	lda	#$55
	sta	xe1c01
	dex	
	bne	b0677
	jsr	s06bb
	ldy	#$04
b0687:
	bvc	b0687
	clv	
	lda	e079c,y
	sta	xe1c01
	dey	
	bpl	b0687
	ldx	#$40
b0695:
	ldy	#$04
b0697:
	bvc	b0697
	clv	
	lda	e07a1,y
	sta	xe1c01
	dey	
	bpl	b0697
	dex	
	bne	b0695
	lda	#$55
	ldx	#$08
b06aa:
	bvc	b06aa
	clv	
	sta	xe1c01
	dex	
	bne	b06aa
s06b3:
	lda	z0032
	clc	
	adc	#$0a
	sta	z0032
	rts	
s06bb:
	ldx	#$05
	lda	#$ff
b06bf:
	bvc	b06bf
	clv	
	sta	xe1c01
	dex	
	bne	b06bf
	rts	
s06c9:
	ldy	#$bb
b06cb:
	bvc	b06cb
	clv	
	lda	xe0100,y
	sta	xe1c01
	iny	
	bne	b06cb
b06d7:
	bvc	b06d7
	clv	
	lda	e0400,y
	sta	xe1c01
	iny	
	bne	b06d7
	rts	
s06e4:
	lda	#$d0
	sta	xe1805
b06e9:
	bit	xe1805
	bpl	b06fb
	bit	xe1c00
	bmi	b06e9
	lda	xe1c01
	clv	
	ldy	#$00
	tya	
	rts	
b06fb:
	lda	#$a1
	rts	
s06fe:
	lda	#$5a
	sta	z004b
b0702:
	jsr	s06e4
	bne	b071e
	ldy	z0032
	ldx	#$0a
b070b:
	bvc	b070b
	clv	
	lda	xe1c01
	cmp	xe0300,y
	bne	b071f
	iny	
	dex	
	bne	b070b
	lda	#$00
	sta	z004b
b071e:
	rts	
b071f:
	dec	z004b
	bne	b0702
	lda	#$a0
	rts	
s0726:
	lda	z0043
	sta	z004d
	lda	z0022
	cmp	#$12
	bne	b0760
	jsr	s06fe
	bne	b0798
	jsr	s06b3
	jsr	s06e4
	bne	b0798
	ldy	#$bb
b073f:
	bvc	b073f
	clv	
	lda	xe1c01
	cmp	xe0100,y
	bne	b0799
	iny	
	bne	b073f
	ldx	#$fc
b074f:
	bvc	b074f
	clv	
	lda	xe1c01
	cmp	e0400,y
	bne	b0799
	iny	
	dex	
	bne	b074f
	beq	b0792
b0760:
	jsr	s06fe
	bne	b0798
	jsr	s06b3
	jsr	s06e4
	bne	b0798
	ldy	#$04
b076f:
	bvc	b076f
	clv	
	lda	xe1c01
	cmp	e079c,y
	bne	b0799
	dey	
	bpl	b076f
	ldx	#$40
b077f:
	ldy	#$04
b0781:
	bvc	b0781
	clv	
	lda	xe1c01
	cmp	e07a1,y
	bne	b0799
	dey	
	bpl	b0781
	dex	
	bne	b077f
b0792:
	dec	z004d
	bne	b0760
s0796:
	lda	#$00
b0798:
	rts	
b0799:
	lda	#$a5
	rts	
e079c:
	dc.b	$4a,$29,$a5,$d4,$55
e07a1:
	dc.b	$4a,$29,$a5,$94,$52
;*** probably the end ***

fdiskend:
	REND
