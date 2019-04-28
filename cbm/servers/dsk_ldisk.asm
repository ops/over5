;**************************************************************************
;**
;** dsk_ldisk.asm
;** adapted in 1995 by Daniel Kahlin <tlr@stacken.kth.se>
;**
;** Turbodisk LOAD 1541part
;**
;******

z0001	equ	$0001	
z0006	equ	$0006	
z0007	equ	$0007	
z0008	equ	$0008	
z0009	equ	$0009	
z000d	equ	$000d	
z000f	equ	$000f	
z0010	equ	$0010	
z0018	equ	$0018	
z0019	equ	$0019	
z0030	equ	$0030	
z0031	equ	$0031	
z0038	equ	$0038	
z003a	equ	$003a	
z0047	equ	$0047	
xe0100	equ	$0100	
xe0300	equ	$0300	
xe0301	equ	$0301	
xe1800	equ	$1800	
xe1c01	equ	$1c01	
xjc194	equ	$c194	
xsc1c8	equ	$c1c8	
xsd676	equ	$d676	
xse60a	equ	$e60a	
xjf418	equ	$f418	
xjf4f6	equ	$f4f6	
xjf502	equ	$f502	
xsf50a	equ	$f50a	
xsf5e9	equ	$f5e9	
xsf8e0	equ	$f8e0	
xefedb	equ	$fedb	
	RORG	$0400	
ldiskstart:

	lda	#$03
	sta	z0031
j0404:
	jsr	xsf50a
b0407:
	bvc	b0407
	clv	
	lda	xe1c01
	sta	(z0030),y
	iny	
	bne	b0407
	ldy	#$ba
b0414:
	bvc	b0414
	clv	
	lda	xe1c01
	sta	xe0100,y
	iny	
	bne	b0414
	jsr	xsf8e0
	lda	z0038
	cmp	z0047
	beq	b042c
	jmp	xjf4f6
b042c:
	jsr	xsf5e9
	cmp	z003a
	beq	b0436
	jmp	xjf502
b0436:
	lda	xe0300
	jsr	s048a
	lda	xe0301
	jsr	s048a
	ldy	#$02
b0444:
	bit	xe1800
	bpl	b0444
	lda	#$10
	sta	xe1800
b044e:
	bit	xe1800
	bmi	b044e
b0453:
	lda	xe0300,y
	eor	#$ff
	sta	z000f
	ldx	#$04
b045c:
	lda	#$00
	lsr	z000f
	rol
	asl
	lsr	z000f
	rol
	asl
	sta	xe1800
	dex	
	bne	b045c
	iny	
	nop	
	nop	
	bne	b0453
	lda	#$0f
	sta	xe1800
	lda	xe0301
	sta	z0009
	lda	xe0300
	cmp	z0008
	bne	b0485
	jmp	j0404
b0485:
	sta	z0008
	jmp	xjf418
s048a:
	sta	z000f
b048c:
	bit	xe1800
	bpl	b048c
	lda	#$10
	sta	xe1800
b0496:
	bit	xe1800
	bmi	b0496
	ldx	#$04
b049d:
	lda	#$00
	lsr	z000f
	rol
	asl
	lsr	z000f
	rol
	asl
	sta	xe1800
	dex	
	bne	b049d
	ldx	#$01
b04af:
	dex	
	bne	b04af
	nop	
	nop	
	lda	#$0f
	sta	xe1800
	rts	
s04ba:
	sta	z0001
	cli	
b04bd:
	lda	z0001
	bmi	b04bd
	sei	
	cmp	#$02
	rts	
LoadEntry:
	sei	
	lda	z0018
	cmp	#$12
	bne	b04d1
	lda	#$62
	jmp	j0539
b04d1:
	sta	z0008
	lda	z0019
	sta	z0009
b04d7:
	lda	#$00
	sta	z0006
	sta	z0007
	sta	z0010
	sta	z000d
b04e1:
	ldx	#$04
b04e3:
	lda	#$b0
	jsr	s04ba
	bcc	b04ef
	dex	
	bne	b04e3
	bcs	b04f6
b04ef:
	lda	#$e0
	jsr	s04ba
	bcc	b0522
b04f6:
	lda	z0010
	beq	b0507
	dec	z0010
	lda	#$c0
	jsr	s04ba
	lda	#$00
	sta	z0006
	sta	z0007
b0507:
	ldy	z0006
	lda	xefedb,y
	beq	b052f
	lda	z0007
	sec	
	sbc	xefedb,y
	sta	z0007
	lda	xefedb,y
	cli	
	jsr	xsd676
	sei	
	inc	z0006
	bne	b04e1
b0522:
	lda	z0007
	cli	
	jsr	xsd676
	sei	
	lda	z0008
	bne	b04d7
	beq	b054e
b052f:
	lda	z000d
	bne	j0539
	inc	z0010
	inc	z000d
	bne	b04e1
j0539:
	pha	
	ora	#$80
	jsr	s048a
	pla	
	cmp	#$62
	bne	b0547
	jsr	xsc1c8
b0547:
	ldx	#$01
	lda	z0001
	jsr	xse60a
b054e:
	jmp	xjc194

ldiskend:
	REND
