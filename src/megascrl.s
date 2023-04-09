                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_draw_slice
    XDEF    _asm_rotate_small_sprites
    XREF    _screen_phys_next
    XREF    _font_small_ready

    XREF    _asm_nf_debugger

NUMBER_OF_CHARS         equ 40     ; Number of characters in the font
BITS_PER_LINE           equ 16     ; Number of bits per line in the font
BITPLANE_SCREEN         equ 0      ; Bitplane of the screen to display the sprite: 0..3
BITPLANES               equ 1      ; Number of bitplanes
SRC_WIDTH               equ 1      ; Original width of the sprite in WORDS
SRC_HEIGHT              equ 16     ; Original height of the sprite in lines
DST_WIDTH               equ 1      ; Original width of the sprite in WORDS
DST_HEIGHT              equ SRC_HEIGHT     ; Original height of the sprite in lines
SPRITE_SIZE_ORIGINAL    equ (SRC_WIDTH * SRC_HEIGHT * BITPLANES * 2)              ; Size of the original sprite (1 bitplane 16 bits 16 lines) in bytes

MEGA_PIXEL_HEIGHT       equ 12     ; Height of each of the megapixels in lines
MEGA_PIXEL_HEIGHT_VISIBLE equ 8     ; Height of each of the megapixels in lines visible
MEGA_PIXEL_HEIGHT_NOT_VISIBLE equ MEGA_PIXEL_HEIGHT - MEGA_PIXEL_HEIGHT_VISIBLE ; Height of each of the megapixels in lines not visible
MEGA_PIXEL_WIDTH_MASK  equ $3FFF   ; Visible left side of the mask
MEGA_PIXEL_TOP_OFFSET  equ 1       ; Offset of the top of the megapixel  to delete the rotating buffer
MEGA_PIXEL_START_POSITION equ 32   ; Start position of the megapixel in the screen
TEXTROLL_SIZE           equ 20

               section code

                MACRO BLIT_MODE
                or.b #F_LINE_BUSY,BLITTER_CONTROL_REG(a6)    ; << START THE BLITTER >>
.\@wait_blitter:
                bset.b    #M_LINE_BUSY,BLITTER_CONTROL_REG(a6)       ; Restart BLiTTER and test the BUSY
                nop                      ; flag state.  The "nop" is executed
                bne.s  .\@wait_blitter     ; prior to the BLiTTER restarting.
                ENDM

                MACRO HOG_MODE
                move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                ENDM


; Rotate 90 degrees right the 16x16x1 fonts
; 1 bitplane for the sprite no mask
_asm_rotate_small_sprites:
;                    IIF _DEBUG jsr _asm_nf_debugger

                    bsr init_tiles

                    move.l _font_small_ready,a0    ; a0 <- font_small_ready address
                    lea sprites_rotated,a1        ; a1 <- sprites_ready address
                    move.w #NUMBER_OF_CHARS - 1,d0  ; d0 <- NUMBER_OF_CHARS -1. Count the number of chars in the font
next_sprite:
                    moveq #0,d2                 ; d2 <- 0. Count the total lines of each sprite in DST_HEIGHT
                    moveq #0,d1                 ; d1 <- 0. Bit to rotate from 0 to 15
next_line:
                    move.w #%1000000000000000, d4
                    lsr.w d1,d4

                    move.w (a0, d2),d3          ; d3 <- read the next word from the font
                    btst #15, d3
                    beq.s .next_bit_14          ; if bit 15 == 0 then next bit
                    or.w d4, (a1)               ; if bit 15 == 1 then write the bit to the sprite
.next_bit_14:       btst #14, d3                ; if bit 14 == 0 then next bit
                    beq.s .next_bit_13          ; if bit 14 == 0 then next bit
                    or.w d4, (2, a1)            ; if bit 14 == 1 then write the bit to the sprite
.next_bit_13:       btst #13, d3                ; if bit 13 == 0 then next bit
                    beq.s .next_bit_12          ; if bit 13 == 0 then next bit
                    or.w d4, (4, a1)            ; if bit 13 == 1 then write the bit to the sprite
.next_bit_12:       btst #12, d3                ; if bit 12 == 0 then next bit
                    beq.s .next_bit_11          ; if bit 12 == 0 then next bit
                    or.w d4, (6, a1)            ; if bit 12 == 1 then write the bit to the sprite
.next_bit_11:       btst #11, d3                ; if bit 11 == 0 then next bit
                    beq.s .next_bit_10          ; if bit 11 == 0 then next bit
                    or.w d4, (8, a1)            ; if bit 11 == 1 then write the bit to the sprite
.next_bit_10:       btst #10, d3                ; if bit 10 == 0 then next bit
                    beq.s .next_bit_9           ; if bit 10 == 0 then next bit
                    or.w d4, (10, a1)           ; if bit 10 == 1 then write the bit to the sprite
.next_bit_9:        btst #9, d3                 ; if bit 9 == 0 then next bit
                    beq.s .next_bit_8           ; if bit 9 == 0 then next bit
                    or.w d4, (12, a1)           ; if bit 9 == 1 then write the bit to the sprite
.next_bit_8:        btst #8, d3                 ; if bit 8 == 0 then next bit
                    beq.s .next_bit_7           ; if bit 8 == 0 then next bit
                    or.w d4, (14, a1)           ; if bit 8 == 1 then write the bit to the sprite
.next_bit_7:        btst #7, d3                 ; if bit 7 == 0 then next bit
                    beq.s .next_bit_6           ; if bit 7 == 0 then next bit
                    or.w d4, (16, a1)           ; if bit 7 == 1 then write the bit to the sprite
.next_bit_6:        btst #6, d3                 ; if bit 6 == 0 then next bit
                    beq.s .next_bit_5           ; if bit 6 == 0 then next bit
                    or.w d4, (18, a1)           ; if bit 6 == 1 then write the bit to the sprite
.next_bit_5:        btst #5, d3                 ; if bit 5 == 0 then next bit
                    beq.s .next_bit_4           ; if bit 5 == 0 then next bit
                    or.w d4, (20, a1)           ; if bit 5 == 1 then write the bit to the sprite
.next_bit_4:        btst #4, d3                 ; if bit 4 == 0 then next bit
                    beq.s .next_bit_3           ; if bit 4 == 0 then next bit
                    or.w d4, (22, a1)           ; if bit 4 == 1 then write the bit to the sprite
.next_bit_3:        btst #3, d3                 ; if bit 3 == 0 then next bit
                    beq.s .next_bit_2           ; if bit 3 == 0 then next bit
                    or.w d4, (24, a1)           ; if bit 3 == 1 then write the bit to the sprite
.next_bit_2:        btst #2, d3                 ; if bit 2 == 0 then next bit
                    beq.s .next_bit_1           ; if bit 2 == 0 then next bit
                    or.w d4, (26, a1)           ; if bit 2 == 1 then write the bit to the sprite
.next_bit_1:        btst #1, d3                 ; if bit 1 == 0 then next bit
                    beq.s .next_bit_0           ; if bit 1 == 0 then next bit
                    or.w d4, (28, a1)           ; if bit 1 == 1 then write the bit to the sprite
.next_bit_0:        btst #0, d3                 ; if bit 0 == 0 then next bit
                    beq.s .next_line            ; if bit 0 == 0 then next bit
                    or.w d4, (30, a1)           ; if bit 0 == 1 then write the bit to the sprite
.next_line
                    addq #1,d1                  ; d1 <- d1 + 1. Increment the bit counter
                    addq #2,d2                  ; d2 <- d2 + 2 (1 word two bytes). Increment the line counter
                    and.w #(BITS_PER_LINE)-1,d1 ; d1 <- d1 & (BITS_PER_LINE)-1. Keep the shift counter in the range 0..15
                    and.w #(DST_HEIGHT*2)-1,d2  ; d2 <- d2 & (DST_HEIGHT * 2bytes)-1. Keep the line counter in the range 0..15
                    bne next_line               ; if d2 != 0 then next line of the sprite. If d2 == 0 then we are done with
                                                ; this sprite for this shift

                    add.w #SPRITE_SIZE_ORIGINAL, a0 ; a0 <- a0 + SPRITE_SIZE_ORIGINAL
                    add.w #SPRITE_SIZE_ORIGINAL, a1 ; a1 <- a1 + SPRITE_SIZE_ORIGINAL
                                                ; Calculate address of next source sprite and loop again. We are done with this sprite
                    dbf d0,next_sprite          ; d0 <- d0 - 1. Decrement the sprite counter and loop again. We are done with this char
                    rts                         ; We are done


;   Init the tiles routines
init_tiles:
                    move.w #_SCROLL_BACKGROUND_START,tiles_pixel_offset; We should start with minus one because the first time we call the routine we will add 1 to it.
                    move.w #0 ,tiles_offset
                    move.w #0, slice_column
                    move.l #text, text_index
                    rts

                MACRO WRITE_MEGA_PIXEL
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #MEGA_PIXEL_HEIGHT_NOT_VISIBLE, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    BLIT_MODE
                    add.w #_SCREEN_WIDTH_BYTES * MEGA_PIXEL_HEIGHT_NOT_VISIBLE, a1

                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.b #$3, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #MEGA_PIXEL_HEIGHT_VISIBLE, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    add.w #_SCREEN_WIDTH_BYTES * MEGA_PIXEL_HEIGHT_VISIBLE, a1
                ENDM

                MACRO CLEAR_MEGA_PIXEL
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #MEGA_PIXEL_HEIGHT_VISIBLE + MEGA_PIXEL_HEIGHT_NOT_VISIBLE, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    add.w #_SCREEN_WIDTH_BYTES * (MEGA_PIXEL_HEIGHT_VISIBLE + MEGA_PIXEL_HEIGHT_NOT_VISIBLE), a1
                ENDM



;   Draw the vertical slice of the tile when needed
_asm_draw_slice:
;                    IIF _DEBUG jsr _asm_nf_debugger
                    move.w tiles_pixel_offset, d0
                    addq #_SCROLL_BACKGROUND_SPEED, d0
                    and.w #15, d0
                    move.w d0, tiles_pixel_offset
                    IIF _SCROLL_BACKGROUND_SPEED == 1 lsr.w #1,d0
                    IIF _SCROLL_BACKGROUND_SPEED == 2 lsr.w #2,d0
                    IIF _SCROLL_BACKGROUND_SPEED == 4 lsr.w #3,d0
                    IIF _SCROLL_BACKGROUND_SPEED == 8 lsr.w #4,d0
                    IIF _SCROLL_BACKGROUND_SPEED == 16 lsr.w #5,d0
                    beq.s .repaint_slice_tiles
                    rts


.repaint_slice_tiles:
; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w #(2 * _SCREEN_BITPLANES), DEST_X_INCREMENT(a6) ; dest X increment. Jump to the next line.
                    move.w #(_SCREEN_WIDTH_BYTES), DEST_Y_INCREMENT(a6) ; dest Y increment. Jump to the next line.
                    move.w #1, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #1, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.w #MEGA_PIXEL_WIDTH_MASK, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask3 register
                    move.b #0, BLITTER_SKEW(a6) ; blitter skew:


                    move.w #%0001111111000, HALFTONE_RAM(a6) ; halftone RAM
                    move.w #%0011111111100, HALFTONE_RAM+2(a6) ; halftone RAM
                    move.w #%0111111111110, HALFTONE_RAM+4(a6) ; halftone RAM
                    move.w #%0111111111110, HALFTONE_RAM+6(a6) ; halftone RAM
                    move.w #%0111111111110, HALFTONE_RAM+8(a6) ; halftone RAM
                    move.w #%0111111111110, HALFTONE_RAM+10(a6) ; halftone RAM
                    move.w #%0011111111100, HALFTONE_RAM+12(a6) ; halftone RAM
                    move.w #%0001111111000, HALFTONE_RAM+14(a6) ; halftone RAM

;                    move.w #%0000011100000, HALFTONE_RAM(a6) ; halftone RAM
;                    move.w #%0001111111000, HALFTONE_RAM+2(a6) ; halftone RAM
;                    move.w #%0011111111100, HALFTONE_RAM+4(a6) ; halftone RAM
;                    move.w #%0111100011110, HALFTONE_RAM+6(a6) ; halftone RAM
;                    move.w #%0111000001110, HALFTONE_RAM+8(a6) ; halftone RAM
;                    move.w #%0111000001110, HALFTONE_RAM+10(a6) ; halftone RAM
;                    move.w #%0111100011110, HALFTONE_RAM+12(a6) ; halftone RAM
;                    move.w #%0011111111100, HALFTONE_RAM+14(a6) ; halftone RAM
;                    move.w #%0001111111000, HALFTONE_RAM+16(a6) ; halftone RAM
;                    move.w #%0000011100000, HALFTONE_RAM+18(a6) ; halftone RAM
;                    move.w #%11111111111111, HALFTONE_RAM(a6) ; halftone RAM
;                    move.w #%10000000000001, HALFTONE_RAM+2(a6) ; halftone RAM
;                    move.w #%10011111111101, HALFTONE_RAM+4(a6) ; halftone RAM
;                    move.w #%10010111110101, HALFTONE_RAM+6(a6) ; halftone RAM
;                    move.w #%10011111111101, HALFTONE_RAM+8(a6) ; halftone RAM
;                    move.w #%10011111111101, HALFTONE_RAM+10(a6) ; halftone RAM
;                    move.w #%10010111110101, HALFTONE_RAM+12(a6) ; halftone RAM
;                    move.w #%10011111111101, HALFTONE_RAM+14(a6) ; halftone RAM
;                    move.w #%10000000000001, HALFTONE_RAM+16(a6) ; halftone RAM
;                    move.w #%11111111111111, HALFTONE_RAM+18(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+16(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+18(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+20(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+22(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+24(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+26(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+28(a6) ; halftone RAM
                    move.w #%0, HALFTONE_RAM+30(a6) ; halftone RAM


; Init blitter registers
.print_char:

                    move.l text_index, a0               ; a0 -> pointer to the text to print in ascii encoding 
                    moveq #0, d0                        ;
                    move.b (a0)+,d0                     ; Obtain the char to print in ascii encoding
                    bne.s .not_reset_text_index         ; if d0 != 0 then end of text
                    move.l #text, text_index            ; reset the text index
                    bra.s .print_char                   ; print the first char again   
.not_reset_text_index:
                    sub.b #32,d0                        ; substract 32 to start the index in 0
                    lea ascii_index, a1
                    move.b (a1,d0),d0                   ; get the char from ascii to custom encoding
                    mulu.w #SPRITE_SIZE_ORIGINAL,d0     ; each char 'cost' SPRITE_SIZE_ORIGINAL bytes.


                    move.w slice_column, d1             ; d1 <- slice_column
                    move.w d1, d2
                    addq.w #1, slice_column             ; slice_column <- slice_column + 1
                    and.w #31, slice_column             ; slice_column <- slice_column & 31
                    lsr.w #1, d1                        ; Try to repeat the same char twice for both planes
                    tst.w slice_column                  ; if slice_column == 0 then
                    bne.s .not_reset_slice_column      ;   slice_column <- slice_column + 1
                    move.l a0, text_index               ; save the new text index

.not_reset_slice_column:
                    lea sprites_rotated, a0             ; a0 -> pointer to the sprites rotated
                    add.w d1, d1                        ; d1 <- d1 + d1. Column offset of the char to print now
                    add.w d1, D0                        ; d0 <- d0 + d1 + d1. Char mem addres plus Column offset of the char to print now
                    move.w (a0, d0), d0                 ; Word to print on screen

                    move.l _screen_phys_next, a1     ; a1 -> screen base address
                    add.w #(4 * 42 + 6) + (MEGA_PIXEL_START_POSITION * _SCREEN_WIDTH_BYTES), a1  ; a1 -> now is in the non visible part of the screen

                    and.w #%0001, d2
                    tst.w d2
                    beq.s .not_skew
                    subq #8, a1
.not_skew:

                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #MEGA_PIXEL_TOP_OFFSET, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    add.w #_SCREEN_WIDTH_BYTES * MEGA_PIXEL_TOP_OFFSET, a1

                    moveq #15, d1
.paint_pixel:
                    btst d1, d0
                    beq.s .clear_pixel 
.set_pixel:
                    move.b #$3, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #1, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    WRITE_MEGA_PIXEL
                    dbf d1, .paint_pixel
                    rts

.clear_pixel:
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    CLEAR_MEGA_PIXEL
                    dbf d1, .paint_pixel
                    rts

                section data
                EVEN
scroll_counter:
                dc.w 0

ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 39, 39, 39, 39, 39, 39, 39, 39, 39, 39     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 39, 39, 38, 39, 37, 39, 35, 26, 27, 28    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 29, 30, 31, 32, 33, 34, 39, 39, 39, 39    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 39, 36, 39, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

text:
                dc.b "THIS IS A TEST OF THE TEXT ROLLING SYSTEM", 0

                section bss
tiles_pixel_offset:
                ds.w 1
tiles_offset:
                ds.w 1
slice_column:
                ds.w 1
text_index:
                ds.l 1

; The "sprite_ready" stores the 16x16x1 sprites without mask
sprites_rotated:  ds.l  NUMBER_OF_CHARS * DST_WIDTH * DST_HEIGHT


                end




