                        include src/constants.s     ; Global constants. Start with '_'

; Big boss large sprite routine
; 320x59 pixels and 4 bit planes

    XDEF    _asm_restore_big_sprite_background_blitter
    XDEF    _asm_display_big_sprite_xy
    XDEF    _asm_calculate_blitter_address
    XDEF    _asm_init_big_sprite
    XREF    _c23_logo_ready
    XREF    _screen_next
    XREF    _current_screen_mask    ; Current we have to now the screen mask to know where to display and restore the sprite

BITPLANES               equ 4      ; Number of bitplanes
BACKGROUND_BITPLANES    equ 4      ; Number of bitplanes for the background stored in the buffer
MASKPLANES              equ 1      ; Number of maskplanes
SRC_WIDTH               equ 160    ; Original width of the sprite in WORDS
SRC_MASK_WIDTH          equ (SRC_WIDTH / 8)    ; Original width of the sprite mask in WORDS
SRC_HEIGHT              equ 59     ; Original height of the sprite in lines
DST_WIDTH               equ 160    ; Original width of the sprite in WORDS
DST_HEIGHT              equ 59     ; Original height of the sprite in lines
BITS_PER_SKEW           equ 16     ; Number of bits to shift per skew (16 bits per word)
SPRITE_SIZE_ORIGINAL    equ (SRC_WIDTH * SRC_HEIGHT) ; Size of the original sprite in bytes
SPRITE_SIZE_BACKGROUND  equ (DST_WIDTH * DST_HEIGHT) ; Size of the background of the sprite

                section code

; Create a megamask for the sprite
_asm_init_big_sprite:
                    move.l _c23_logo_ready,a0   ; a0 <- the c23 logo address
                    lea sprite_mask,a1          ; a1 <- the sprite mask address
                    move.w #((SPRITE_SIZE_ORIGINAL / 2) - 1) , d0  ; d0 <- Words to read minus one
next_word:
                    move.w (a0)+, d3             ; d3 <- read the next word from the sprite
                    or.w (a0)+, d3              ; d3 <- d3 | read the next word from the sprite
                    or.w (a0)+, d3              ; d3 <- d3 | read the next word from the sprite
                    or.w (a0)+, d3              ; d3 <- d3 | read the next word from the sprite
                    not.w d3                    ; d3 <- ~d3
                    move.w d3, (a1)+            ; write the word to the mask

                    dbf d0, next_word           ; d0 <- d0 - 1
                    rts


; Calculate memory address from X and Y coordinates for blitter
;  Need to pass:
;       D0.W -> X coordinate (-320 to +319)
;       D1.W -> Y coordinate (-200 to +199)
;  Returns:
;       D0.W -> Memory offset of the X axis over the screen
;       D1.W -> Memory offset of the Y axis in the screen
;       D2.W -> Skew position (0..15)
;       D3.W -> Width in WORDS of each bitplane of the sprite
;       D4.W -> Height in lines of the sprite
;       D5.W -> Width in WORDS to skip of each bitplane of the sprite
;       D6.W -> Height in lines to skip of the sprite
_asm_calculate_blitter_address:

.offset_x_axis:
; d0 contains the X coordinate
; If d0 is negative, we have to add the memory offset of the sprite for clipping
; If d0 is positive, we have to decrease the memory offset of the sprite for clipping

                cmp.w #-320, d0
                bgt.s .axis_x_in_range
                move.w #-320, d0
.axis_x_in_range:
                add.w #320, d0
                move.w d0, d3
                move.w d0, d7
.positive_x:
; Transform d3.w to the width in WORDS of each bitplane of the sprite
                lsr.w #4, d3
                cmp.w #(DST_WIDTH / 8), d3
                blt.s .fix_offset_x_axis
                move.w d3, d5
                sub.w #DST_WIDTH / 8, d5
                add.w d5, d5
                sub.w d5, d3
                moveq #0, d5
                tst.w d3
                bgt.s .offset_y_axis
                moveq #0, d3           ; if nothing to display because out of range in X, set width to 0
                bra.s .offset_y_axis
.fix_offset_x_axis:
                moveq #(DST_WIDTH / 8), d5
                sub.w d3, d5
                subq #1, d5
                addq #2, d3
                tst.w d5
                bgt.s .offset_y_axis
                moveq #0, d5
                subq #1, d3
;                moveq #DST_WIDTH / 8, d3

; d3.w contains the width in WORDS of the sprite starting from the left side
; d0.w contains the X coordinate of the sprite. Since positive, do not touch it

.offset_y_axis:
; d1.w contains the Y coordinate
; If d1 is negative, we have to count the number of lines to display from the bottom of the sprite
; If d1 is positive, we have to count the number of lines to display from the top of the sprite
                move.w d1, d4
                btst   #15, d1
                beq.s  .positive_y
.negative_y:
                add.w #DST_HEIGHT, d4
                moveq #0, d1
; d4.w contains the height in lines of the sprite starting from the bottom
; d1.w contains the Y coordinate of the sprite. Since negative, it is 0

; Calculate the height in lines to skip of the sprite
                move.w #DST_HEIGHT, d6
                sub.w d4, d6
                cmp.w #DST_HEIGHT, d6
                ble.s .calculate_memory_address
                move.w #DST_HEIGHT, d6
                moveq #0, d4
                bra.s .calculate_memory_address
.positive_y:
                moveq #0, d6
                move.w #DST_HEIGHT, d4
                cmp.w #(_SCREEN_HEIGHT_LINES  - DST_HEIGHT), d1
                ble.s .calculate_memory_address
                move.w #(_SCREEN_HEIGHT_LINES  - DST_HEIGHT), d6
                sub.w d1,d6
                not.w d6
                addq #1, d6 
                sub.w d6, d4
                moveq #0, d6
                tst.w d4
                bgt.s .calculate_memory_address
                moveq #0, d4

; d4.w contains the height in lines of the sprite starting from the top
; d1.w contains the Y coordinate of the sprite. Since positive, do not touch it

.calculate_memory_address:
; Calculate the Y offset of the sprite in the screen
                lsl.w	#4,d1                   ; Multiply by _SCREEN_WIDTH_BYTES
                move.w	d1,d2
                add.w	d1,d1
                add.w	d1,d1
                add.w	d2,d1
                add.w	d1,d1                    ; Till here   

; Calculate the X offset of the sprite in the screen FOR THE FIRST BITPLANE in bytes
                and.w #(65536 - 16), d0 ; d0 <- d0 & (65535 - TOTAL_SHIFTS). Keep the X coordinate in the range 0..304
                lsr.w #1, d0            ; d0 <- d0 >> 1. d0 now contains the the byte offset of the sprite in X
                sub.w #DST_WIDTH, d0
                btst #15, d0
                beq.s .do_skew
                moveq #-8, d0
;                tst.w d5
;                beq.s .do_skew
;                addq #1, d5

; Calculate the skew position
.do_skew:
                and.w #15, d7           ; d2 <- d2 & 15. d2 now contains the skew position
                move.w d7,d2

                rts

_asm_restore_big_sprite_background_blitter:

                    moveq #0, d0                    ; d0 <- 0
                    move.w _current_screen_mask, d0 ; d0 <- current screen mask
                    lea sprite_bckgrnd, a2          ; a2 <- sprite_bckgrnd. a4 now contains the address of the array
                                                    ; where the background of the sprite will be stored
                    mulu #SPRITE_SIZE_BACKGROUND + 8,d0 ; d0 <- d0 * SPRITE_SIZE_BACKGROUND. d0 now contains the
                                                    ; index of the sprite in the array
                    add.l d0, a2                    
; a2 <- a2 + d0. a2 now contains the address to restore the background of the sprite for the current screen
; a3 <- screen address where the background was restored
                    move.l (a2)+, a3                 ; Retrieve the screen address to restore the background buffer
                    cmp.l #0,a3                     ; Test if the sprite was displayed in the previus pass
                    beq .skip_restore                ; If the sprite was not displayed in the previus pass, skip the restore sprite routine

                    move.w (a2)+, d3                ; Retrieve the width in WORDS of the sprite
                    move.w (a2)+, d4                ; Retrieve the height in lines of the sprite

                    move.w #DST_WIDTH / 8, d7
                    sub.w d3, d7
                    move.w d7, d6
                    add.w d7,d7
                    add.w d7,d7
                    add.w d7,d7
                    addq.w #8, d7               ; d7 <- Increment of Y axis for the sprite to do the clipping

; a2 <- screen background buffer address. The address of memory to save the background of the screen for the future
                    lea  $FF8A00,a4          ; a4-> BLiTTER register block
                    move.w #8, SRC_X_INCREMENT(a4) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    move.w d7, SRC_Y_INCREMENT(a4) ; source Y increment. Increase the 4 planes.
                    move.w #8, DEST_X_INCREMENT(a4) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d7, DEST_Y_INCREMENT(a4) ; dest Y increment. Increase the 4 planes.
                    move.w d3, BLOCK_X_COUNT(a4) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.w #$FFFF, ENDMASK1_REG(a4) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a4) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a4) ; endmask3 register. The mask should covers the char column.
                    move.b #$2, BLITTER_HOP(a4) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$3, BLITTER_OPERATION(a4) ; blitter operation. Copy src to dest, replace copy.
                    move.b #%00000000, BLITTER_SKEW(a4) ; blitter skew: -8 pixels and NFSR and FXSR.

                    ; copy first plane
                    move.l a2, SRC_ADDR(a4)  ; source address
                    move.l a3, DEST_ADDR(a4) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a4) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode

                    ; copy second plane
                    addq.w #2, a2               ; Next bitplane src
                    addq.w #2, a3               ; Next bitplane dest
                    move.l a2, SRC_ADDR(a4)  ; source address
                    move.l a3, DEST_ADDR(a4) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a4) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode

                    ; copy third plane
                    addq.w #2, a2               ; Next bitplane src
                    addq.w #2, a3               ; Next bitplane dest
                    move.l a2, SRC_ADDR(a4)  ; source address
                    move.l a3, DEST_ADDR(a4) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a4) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode
.skip_restore:
                    rts




; Display the sprite passing the X and Y coordinates
; Parameters:
;       D0.W -> Memory offset of the X axis over the screen
;       D1.W -> Memory offset of the Y axis in the screen
;       D2.W -> Skew position (0..15)
;       D3.W -> Width in WORDS of each bitplane of the sprite
;       D4.W -> Height in lines of the sprite
;       D5.W -> Width in WORDS to skip of each bitplane of the sprite
;       D6.W -> Height in lines to skip of the sprite
; Returns:
;   Nothing
; Modifies:
;   a0, a1, a2, a3, a4, a5, a6
;   d0, d1, d2, d3, d4, d5, d6
_asm_display_big_sprite_xy:
                    move.l _screen_next, a1         ; a1 <- screen_next. A1 now contains the address of the screen where the sprite will be displayed
                    move.l _c23_logo_ready,a0            ; a0 <- Memory address where the cooked sprites are stored

                    add.w d0,a1                     ; a1 <- a1 + d0. a1 now contains the memory address of the screen
                                                    ; where the sprite will be displayed in X
                    add.w d1,a1                     ; a1 <- a1 + d1. a1 now contains the memory address of the screen
                                                    ; where the sprite will be displayed in X and now Y
; a1 <- screen address. The address of the screen where the sprite will be displayed
; store in the sprites_bckgrnd_idx to restore the background in the next frame

                    moveq #0, d7                    ; d7 <- 0
                    move.w _current_screen_mask, d7 ; d7 <- current screen mask
                    lea sprite_bckgrnd, a2          ; a2 <- sprite_bckgrnd. a4 now contains the address of the array
                                                    ; where the background of the sprite will be stored
                    mulu #SPRITE_SIZE_BACKGROUND + 8,d7 ; d7 <- d7 * SPRITE_SIZE_BACKGROUND. d7 now contains the
                                                    ; index of the sprite in the array
                                                    ; Add the size of the sprite background structure
                    add.l d7, a2                    
; a2 <- a2 + d7. a2 now contains the address to store the background of the sprite for the current screen

; Positive clipping X
                    tst.w d3
                    bne.s .visible_X_clipping
                    rts
.visible_X_clipping:
                    tst.w d5
                    beq.s .clipping_y
                    move.w d5, d0
                    add.w d0, d0        ; mask increment in bytes
                    add.w d0, a3
                    add.w d0, d0
                    add.w d0, d0        ; sprite increment in bytes
                    add.w d0, a0

; Clipping Y
.clipping_y:
                    lea sprite_mask, a3             ; a3 <- sprite_mask. a3 now contains the address of the array
                                                    ; where the masks of the sprite are stored
                    tst.w d4
                    bne.s .visible_Y_clipping
                    rts
.visible_Y_clipping:
                    tst.w d1
                    bne.s .pos_Y_clipping
                    move.w d6, d1
                    mulu #SRC_MASK_WIDTH, d1    ; in bytes
                    add.w d1, a3
                    move.w d6, d1
                    mulu #SRC_WIDTH, d1         ; in bytes
                    add.w d1, a0
.pos_Y_clipping:

.use_blitter:

;                    addq #6,a1
;                    addq #6,a2
;                   

                    move.w #DST_WIDTH / 8, d7
                    sub.w d3, d7
                    move.w d7, d6
                    add.w d7,d7
                    add.w d7,d7
                    add.w d7,d7
                    addq.w #8, d7               ; d7 <- Increment of Y axis for the sprite to do the clipping
                    add.w d6,d6
                    addq.w #2, d6               ; d6 <- Increment of Y axis for the mask to do the clipping

                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
; save the background planes
;                    subq #8, a1

                    move.l a1, (a2)+ ; Save the address to recover
                    move.w d3, (a2)+ ; Save the width in words of the sprite
                    move.w d4, (a2)+ ; Save the lines of the sprite
                    move.w #8, SRC_X_INCREMENT(a6) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    move.w d7, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    move.w #8, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d7, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d3, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask3 register. The mask should covers the char column.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$3, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.b #0, BLITTER_SKEW(a6) ; blitter skew: nothing

                    REPT 3
                    ; copy fourth plane
                    move.l a1, SRC_ADDR(a6)  ; source address
                    move.l a2, DEST_ADDR(a6) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                    addq.w #2, a1               ; Next bitplane src
                    addq.w #2, a2               ; Next bitplane dest
                    ENDR

; Apply masks to the screen
.apply_masks:
                    subq #6, a1 ; Restore a1 as the screen address
                                ; a3 as the sprite mask address
                                ; a0 as the sprite address 

                    move.w #8, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d7, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d3, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$02, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b d2, BLITTER_SKEW(a6) ; blitter skew:

                    move d2, d1
                    bsr get_leftmask                 ; SHould be optimizable
                    bsr get_rightmask                 ; SHould be optimizable
                    move.w d2, ENDMASK1_REG(a6)     ; endmask1 register
                    move.w d1, ENDMASK3_REG(a6)     ; endmask1 register

                    move.w #2, SRC_X_INCREMENT(a6) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    move.w d6, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                REPT 3
                    ; AND plane
                    move.b #$1, BLITTER_OPERATION(a6) ; blitter operation. source AND destination.
                    move.l a3, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                    addq.w #2, a1               ; Next bitplane dest
                ENDR

                    move.w #8, SRC_X_INCREMENT(a6) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    move.w d7, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    subq #6, a1
                REPT 3
                    ; OR plane
                    move.b #$7, BLITTER_OPERATION(a6) ; blitter operation. source OR destination.
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d4, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                    addq.w #2, a0               ; Next bitplane src
                    addq.w #2, a1               ; Next bitplane dest
                ENDR
                    rts

                EVEN
; Left end mask for the blitter
lf_endmask:
                dc.w %1111111111111111
                dc.w %0111111111111111
                dc.w %0011111111111111
                dc.w %0001111111111111
                dc.w %0000111111111111
                dc.w %0000011111111111
                dc.w %0000001111111111
                dc.w %0000000111111111
                dc.w %0000000011111111
                dc.w %0000000001111111
                dc.w %0000000000111111
                dc.w %0000000000011111
                dc.w %0000000000001111
                dc.w %0000000000000111
                dc.w %0000000000000011
                dc.w %0000000000000001
                dc.w %0000000000000000

get_leftmask:
                    tst.w d5                                ; if d5 is 0, the mask is for the negative side
                    bne.s .lf_neg
                    add.w d2,d2                             ; d2 <- skew position * 2
                    move.w    lf_endmask(pc,d2.w),d2        ; d2 <- obtain the end data mask
                    rts
.lf_neg:
                    moveq #0, d2
                    rts

; Left end mask for the blitter
rt_endmask:
                dc.w %1111111111111111
                dc.w %1111111111111110
                dc.w %1111111111111100
                dc.w %1111111111111000
                dc.w %1111111111110000
                dc.w %1111111111100000
                dc.w %1111111111000000
                dc.w %1111111110000000
                dc.w %1111111100000000
                dc.w %1111111000000000
                dc.w %1111110000000000
                dc.w %1111100000000000
                dc.w %1111000000000000
                dc.w %1110000000000000
                dc.w %1100000000000000
                dc.w %1000000000000000
                dc.w %0000000000000000

get_rightmask:
                    tst.w d5                                ; if d5 is 0, the mask is for the negative side
                    beq.s .rt_overflow
                    add.w d1,d1                             ; d1 <- skew position * 2
                    move.w    lf_endmask(pc,d1.w),d1        ; d1 <- obtain the end data mask
                    not.w d1
                    rts
.rt_overflow:
                    moveq #-1, d1
                    rts






                section bss align 2
; The "sprites_bckgrnd" stores the background of the buffer of the screen for the sprite of the index
sprite_mask:    ds.w (DST_WIDTH * DST_HEIGHT / 2)

sprite_bckgrnd:
                ds.w ( (8 +_BUFFER_NUMBERS * SPRITE_SIZE_BACKGROUND) / 2)
                ; 8 bytes for the address on the screen (long) and size of the sprite (X and Y, word)
