;---------------------------------------
;         pitchtrack test
;---------------------------------------

         jsr initdrive ;Init drive

         lda #1
         sta temp4
test                   ;Read one track from the disk
         lda temp4
         ldx #$00
         ldy #$40
         jsr gettrack
         bcc moeg
         dec $d020
         jmp test
moeg                   ;Overwrite track with junk
         lda temp4
         ldx #$00
         ldy #$e0
         jsr sendtrack
doagain                ;Write previous data back to track
         lda temp4
         ldx #$00
         ldy #$40
         jsr sendtrack

         lda temp4     ;Check to see if data was written
         ldx #$00      ;correctly
         ldy #$40
         jsr verifytrack
         bcc ok
                       ;If not, wait a while, send init to drive,
         jsr waitawhile;wait, flash the border and try again
         lda #0
         jsr sendbyte
         jsr clear2get
         jsr getbyte
         jsr clear2send
         jsr waitawhile

         inc $d020
         jmp doagain
ok                     ;Track written ok, goto next track
         inc temp4
         lda temp4
         cmp #36
         bne test

         jmp resetdrive;Reset drive

;---------------------------------------

