
;**************************************************************************
;**
;** dsk_sdisk.asm
;** adapted in 1995 by Daniel Kahlin <tlr@stacken.kth.se>
;**
;** Turbodisk SAVE 1541part
;**
;******

dr01_b1_job	equ	$0001	
dr06_b0_T	equ	$0006	
dr07_b0_S	equ	$0007	
dr08_b1_T	equ	$0008	
dr09_b1_S	equ	$0009	
dr0a_b2_T	equ	$000a	
dr0b_b2_S	equ	$000b	
z000c	equ	$000c	
z000d	equ	$000d	
z000e	equ	$000e	
z000f	equ	$000f	
z0030	equ	$0030	
z0031	equ	$0031	
z0043	equ	$0043	
z0044	equ	$0044	
z0069	equ	$0069	
z006d	equ	$006d	
z006f	equ	$006f	
z0080	equ	$0080	
z0081	equ	$0081	
z0086	equ	$0086	
z0087	equ	$0087	
z00c7	equ	$00c7	
xe0100	equ	$0100	
xs0150	equ	$0150	
xe01b4	equ	$01b4	
xe0200	equ	$0200	
xe0215	equ	$0215	
xe024e	equ	$024e	
xe0261	equ	$0261	
xe0267	equ	$0267	
xe0300	equ	$0300	
xe0301	equ	$0301	
xe1800	equ	$1800	
xe1c00	equ	$1c00	
xe1c01	equ	$1c01	
xjc194	equ	$c194	
xsc1c8	equ	$c1c8	
xsd042	equ	$d042	
xsd57d	equ	$d57d	
xjd599	equ	$d599	
xse60a	equ	$e60a	
xsefd5	equ	$efd5	
xeefe9	equ	$efe9	
xsf24b	equ	$f24b	
xjf418	equ	$f418	
xsf50a	equ	$f50a	
xef575	equ	$f575	
xjf6c5	equ	$f6c5	
xsf8e0	equ	$f8e0	
xjf969	equ	$f969	
	RORG	$0400	
sdiskstart:

	lda	z0044
	lsr
	lsr
	lsr
	lsr
	lsr
	tax	
	lda	e06c6,x
	sta	z0069
	ldy	#$04
	dex	
	bne	b0413
	iny	
b0413:
	sty	dr07_b0_S
	lda	#$00
	sta	dr06_b0_T
b0419:
	jsr	s04e7
	beq	b042c
	sta	z0081
	sta	z00c7
	tax	
	inx	
	stx	z000e
	lda	#$00
	sta	z0080
	beq	b0438
b042c:
	jsr	s0554
	bcs	b0436
	lda	#$72
	jmp	$f969	;error
b0436:
	lda	#$00
b0438:
	jsr	s0517
	lda	z0080
	sta	xe0300
	lda	z0081
	sta	xe0301
	lda	#$03
	sta	z0031
	ldy	#$02
b044b:
	jsr	s04e7
	sta	(z0030),y
	iny	
	cpy	z000e
	bne	b044b
	jsr	s04e7
	ldx	dr06_b0_T
	sta	xe0200,x
	lda	dr09_b1_S
	sta	xe0215,x
	sta	dr0b_b2_S
	jsr	xs0150
	inc	z000c
	lda	z00c7
	bne	b047b
	lda	z0081
	sta	dr09_b1_S
	lda	z0080
	cmp	dr08_b1_T
	bne	b047b
	inc	dr06_b0_T
	bne	b0419
b047b:
	lda	#$00
	sta	dr09_b1_S
b047f:
	jsr	$f50a	;Find header
b0482:
	bvc	b0482
	clv	
	lda	xe1c01
	sta	(z0030),y
	iny	
	bne	b0482
	sty	dr0a_b2_T
	ldy	#$ba
b0491:
	bvc	b0491
	clv	
	lda	xe1c01
	sta	xe0100,y
	iny	
	bne	b0491
	jsr	$f8e0
	ldx	dr06_b0_T
b04a2:
	lda	xe0215,x
	cmp	dr09_b1_S
	beq	b04ae
	dex	
	bpl	b04a2
	bmi	b04c8
b04ae:
	lda	z000e
	ldy	dr09_b1_S
	cpy	dr0b_b2_S
	bne	b04b8
	sta	dr0a_b2_T
b04b8:
	ldy	#$02
	lda	xe0200,x
b04bd:
	eor	(z0030),y
	iny	
	cpy	dr0a_b2_T
	bne	b04bd
	cmp	#$00
	bne	b04e4
b04c8:
	clc	
	lda	dr09_b1_S
	adc	dr07_b0_S
	cmp	z0043
	sta	dr09_b1_S
	bcc	b047f
	sbc	z0043
	sta	dr09_b1_S
	bne	b047f
	lda	z0080
	sta	dr08_b1_T
	lda	z0081
	sta	dr09_b1_S
	jmp	$f418	;exit OK
b04e4:
	jmp	$f6c5	;write-vrfy error
s04e7:
	bit	xe1800
	bpl	s04e7
	lda	#$10
	sta	xe1800
b04f1:
	bit	xe1800
	bmi	b04f1
	ldx	#$04
b04f8:
	dex	
	bne	b04f8
	stx	xe1800
	ldx	#$04
b0500:
	lda	xe1800
	lsr
	php	
	lsr
	lsr
	ror	z000f
	plp	
	ror	z000f
	dex	
	bne	b0500
	lda	#$0f
	sta	xe1800
	lda	z000f
	rts	
s0517:
	sta	z000f
b0519:
	bit	xe1800
	bpl	b0519
	lda	#$10
	sta	xe1800
b0523:
	bit	xe1800
	bmi	b0523
	ldx	#$04
b052a:
	lda	#$00
	lsr	z000f
	rol
	asl
	lsr	z000f
	rol
	asl
	sta	xe1800
	dex	
	bne	b052a
	ldx	#$01
b053c:
	dex	
	bne	b053c
	nop	
	nop	
	lda	#$0f
	sta	xe1800
	rts	
s0547:
	lda	#$e0
s0549:
	sta	dr01_b1_job
	cli	
b054c:
	lda	dr01_b1_job
	bmi	b054c
	sei	
	cmp	#$02
	rts	
s0554:
	lda	#$03
	sta	z000d
b0558:
	jsr	s05cc
	bne	b058d
	lda	z0080
	cmp	#$12
	beq	b0579
	bcc	b057b
	inc	z0080
	lda	z0080
	cmp	#$24
	bne	b0558
	ldx	#$11
	stx	z0080
	lda	#$00
	sta	z0081
	dec	z000d
	bne	b0558
b0579:
	clc	
	rts	
b057b:
	dec	z0080
	bne	b0558
	ldx	#$13
	stx	z0080
	lda	#$00
	sta	z0081
	dec	z000d
	bne	b0558
	beq	b0579
b058d:
	lda	z0081
	clc	
	adc	z0069
	sta	z0081
	lda	z0080
	jsr	$f24b	;Returns num of sectors on this track
	sta	xe024e
	cmp	z0081
	bcs	b05ac
	sec	
	lda	z0081
	sbc	xe024e
	sta	z0081
	beq	b05ac
	dec	z0081
b05ac:
	jsr	s05d7
	bne	b05ba
	lda	#$00
	sta	z0081
	jsr	s05d7
	beq	b0579
b05ba:
	lda	(z006d),y
	eor	xeefe9,x
	sta	(z006d),y
	ldy	#$00
	lda	(z006d),y
	sec	
	sbc	#$01
	sta	(z006d),y
	sec	
	rts	
s05cc:
	lda	z0080
	asl
	asl
	sta	z006d
	ldy	#$00
	lda	(z006d),y
	rts	
s05d7:
	ldy	#$00
	sty	z006f
	lda	z0080
	jsr	$f24b	;Returns num of sectors on this track
	sta	xe024e
b05e3:
	lda	z0081
	cmp	xe024e
	bcs	b05f3
	jsr	$efd5	;check BAM bits
	bne	b05f5
	inc	z0081
	bne	b05e3
b05f3:
	lda	#$00
b05f5:
	rts	

SaveEntry:
	jsr	$d042	;Initialize
	jsr	s06a8
	sei	
	beq	b060e
	lda	$1c00
	and	#$10
	bne	b060a
	lda	#$08
	bne	b065a
b060a:
	lda	#$63
	bne	b065a
b060e:
	ldy	#$01
	lda	(z0086),y
	beq	b060a
	sta	dr08_b1_T
	sta	z0080
	iny	
	lda	(z0086),y
	sta	dr09_b1_S
	sta	z0081
	ldx	#$63
b0621:
	lda	$f575,x
	sta	xs0150,x
	dex	
	bpl	b0621
	lda	#$60
	sta	xe01b4
	inx	
	stx	z000e
	stx	z00c7
	stx	z000c
	jsr	s05cc
	jsr	s05d7
	jsr	b05ba
	ldx	#$04
b0641:
	lda	#$b0
	jsr	s0549
	bcc	b064d
	dex	
	bne	b0641
	bcs	b0658
b064d:
	jsr	s0547
	bcs	b0658
	lda	z00c7
	beq	b0641
	bne	b0672
b0658:
	cmp	#$72
b065a:
	pha	
	beq	b0660
	jsr	s04e7
b0660:
	ora	#$80
	jsr	s0517
	pla	
	cmp	#$63
	bcs	b066f
	ldx	#$01
	jsr	$e60a	;handle error!
b066f:
	jsr	$c1c8	;error!

b0672:
	jsr	s04e7
	lda	#$00
	jsr	s0517
	cli	
	jsr	s06a8
	lda	(z0086),y
	ora	#$80
	sta	(z0086),y
	ldy	#$1c
	lda	z000c
	sta	(z0086),y
	lda	#$90
	jsr	s06a0
	lda	#$12
	sta	z000e
	lda	#$90
	ldx	#$04
	jsr	s06a2
	jsr	$d042	;Initialize
	jmp	$c194	;Terminate successfully
s06a0:
	ldx	#$00
s06a2:
	jsr	$d57d	;Store Job Acc in buffer X
	jmp	$d599	;Wait for job to complete

s06a8:
	lda	xe0261
	sta	dr07_b0_S
	lda	#$12
	sta	dr06_b0_T
	lda	#$80
	jsr	s06a0
	lda	#$03
	sta	z0087
	lda	xe0267
	sta	z0086
	ldy	#$00
	lda	(z0086),y
	and	#$80
	rts	
e06c6:
	dc.b	9,10,10,11
sdiskend:
	REND
