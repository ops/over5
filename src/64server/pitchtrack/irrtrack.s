getbyte      ;Receive one byte
  lda $dd00			; 4
  bpl getbyte			; 2/3/4
  lda #0			; 2	-\ 19 (7)
  sta temp			; 3
  clc				; 2
  jsr wait12			; 12	-/
  lda $dd00			; 4	-\ 28 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  jsr wait12			; 12	-/
  lda $dd00			; 4	-\ 28 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  jsr wait12			; 12	-/
  lda $dd00			; 4	-\ 28 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  jsr wait12			; 12	-/
  lda $dd00			; 4	-\ 9
  and #$c0			; 2
  ora temp			; 3	-/
  rts

new_getbyte      ;Receive one byte
  lda $dd00			; 4
  bpl getbyte			; 2/3/4
  lda #0			; 2	-\ 31 (7)
  sta temp			; 3
  clc				; 2
  jsr wait12			; 12
  jsr wait12			; 12	-/
  lda $dd00			; 4	-\ 24 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2	-/
  lda $dd00			; 4	-\ 24 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2	-/
  lda $dd00			; 4	-\ 24 (16)
  and #$c0			; 2
  ora temp			; 3
  ror				; 2
  ror				; 2
  sta temp			; 3
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2	-/
  lda $dd00			; 4	-\ 9
  and #$c0			; 2
  ora temp			; 3	-/
  rts

sendbyte  ;Send one byte
  sta temp			; 3	-\ 9
  lda $dd00			; 4
  and #$0f			; 2	-/
  sta $dd00			; 4	-\ 25
  lda temp			; 3
  ror				; 2
  ror				; 2
  and #$30			; 2
  sta temp2			; 3
  lda $dd00			; 4
  and #$0f			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 31
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2
  lda temp			; 3
  and #$30			; 2
  sta temp2			; 3
  lda $dd00			; 4
  and #$0f			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 31
  asl temp			; 5
  asl temp			; 5
  lda temp			; 3
  and #$30			; 2
  sta temp2			; 3
  lda $dd00			; 4
  and #$0f			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 31
  asl temp			; 5
  asl temp			; 5
  lda temp			; 3
  and #$30			; 2
  sta temp2			; 3
  lda $dd00			; 4
  and #$0f			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 34
  jsr wait12			; 12
  jsr wait12			; 12
  lda $dd00			; 4
  ora #$30			; 2	-/
  sta $dd00			; 4	-\ 16
  jsr wait12			; 12	-/
  rts

new_sendbyte  ;Send one byte
  sta temp			; 3	-\ 12
  lda $dd00			; 4
  and #$0f			; 2
  sta temp2			; 3	-/
  sta $dd00			; 4	-\ 16
  lda temp			; 3
  ror				; 2
  ror				; 2
  and #$30			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 24
  jsr wait12			; 12
  lda temp			; 3
  and #$30			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 24
  nop				; 2
  asl temp			; 5
  asl temp			; 5
  lda temp			; 3
  and #$30			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 24
  nop				; 2
  asl temp			; 5
  asl temp			; 5
  lda temp			; 3
  and #$30			; 2
  ora temp2			; 3	-/
  sta $dd00			; 4	-\ 24
  nop				; 2
  jsr wait12			; 12
  lda $dd00			; 4
  ora #$30			; 2	-/
  sta $dd00			; 4	-\ 20
  nop				; 2
  nop				; 2
  jsr wait12			; 12	-/
  rts

clear2get
  lda $dd00			; 4
  and #$0f			; 2
  sta $dd00			; 4
  jsr wait12			; 12
  rts

clear2send
  lda $dd00			; 4
  ora #$30			; 2
  sta $dd00			; 4
  jsr waitawhile		; en jävla massa
  rts

new_dsendbyte =*-offset ;Send one byte
  sta dtemp4			; 3	-\ 10
  eor #$ff			; 2
  sta dtemp			; 3
  lda #$00			; 2	-/
  sta $1800			; 4	-\ 24
  lda #$00			; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2	-/
  sta $1800			; 4	-\ 24
  lda #$00			; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2	-/
  sta $1800			; 4	-\ 24
  lda #$00			; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2	-/
  sta $1800			; 4	-\ 24
  lda #$00			; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2
  ror dtemp			; 5
  rol				; 2
  asl				; 2	-/
  sta $1800			; 4	-\ 24
  jsr dwait12			; 12
  nop				; 2
  nop				; 2
  nop				; 2
  lda #$02			; 2	-/
  sta $1800			; 4	-\ 19
  jsr dwait12			; 12
  lda dtemp4			; 3	-/
dwait12  =*-offset
  rts

dgetbyte =*-offset ;Receive one byte
  lda #$05			; 2
waitstart
  bit $1800			; 4
  bne waitstart			; 2/3/4
  lda #0			; 2	-\ 27
  sta dtemp			; 3
  jsr dwait12			; 12
  ldx #4			; 2
  nop				; 2
  nop				; 2
  nop				; 2
  nop				; 2	-/
dgetloop
  lda $1800			; 4	-\ 32/33 (24/25)
  nop				; 2
  ror				; 2
  rol dtemp			; 5
  ror				; 2
  ror				; 2
  rol dtemp			; 5
  nop				; 2
  nop				; 2
  nop				; 2
  dex				; 2
  bne dgetloop			; 2/3/4	-/
  lda dtemp			; 3
  rts

new_dgetbyte =*-offset ;Receive one byte
  lda #$05			; 2
waitstart
  bit $1800			; 4
  bne waitstart			; 2/3/4
  lda #0			; 2	-\ 21
  sta dtemp			; 3
  jsr dwait12			; 12
  nop				; 2
  ldx #4			; 2	-/
dgetloop
  lda $1800			; 4	-\ 24/25
  ror				; 2
  rol dtemp			; 5
  ror				; 2
  ror				; 2
  rol dtemp			; 5
  dex				; 2
  bne dgetloop			; 2/3/4	-/
  lda dtemp			; 3
  rts

dclear2get =*-offset
  lda #0			; 2	-\ 18
  sta $1800			; 4
  jsr dwait12			; 12	-/
  rts

dclear2send =*-offset
  lda #2			; 2
  sta $1800			; 4
  jsr dwaitawhile		; en jävla massa
  rts
