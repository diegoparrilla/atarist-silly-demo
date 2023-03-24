                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_scroll_init
    XDEF    _asm_scroll_rotate
    XREF    _screen_next
    XREF    _current_screen_mask        ; The buffered screen index
    XREF    _screen_absolute_offset
    XREF    _screen_pixel_offset
    XREF    _screen_dither_tiktok
    XREF    _raster_y_pos_start
    XREF    _asm_font_large_ready_f0
    XREF    _asm_font_large_ready_f1

                ; Scrolling section

FONT_LARGE_SIZE         equ 600
FONT_HEIGHT             equ 25
FONT_WIDTH              equ 6
DELETE_BAR_HEIGHT       equ 8
DST_WIDTH               EQU FONT_WIDTH * _SCREEN_BITPLANES
MAX_WIDTH_SIZE          equ 11      ; MAX_WIDTH_SIZE + 1 chars per line
SCROLL_SPEED            equ 4      ; Bits to rotate the scroll. Must be 2^n

                section code

; Init the scroll routine. It needs to be called once at the beginning of the program
_asm_scroll_init:
                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
                move.w #(32-SCROLL_SPEED), scroll_shift    ; The shift init value for the scroll (skew)
                rts

;   Print the column and scroll to the left
_asm_scroll_rotate:

; Calculate the start value of the memory address of Y position for X=0
                lea scroll_y_pos, a5            ; The travelling routine for the scroll Y axis
                move.w scroll_y_pointer, d7
                cmp.w scroll_table_size, d7
                bne.s .increase_scroll_y_pointer
                moveq #0,d7                     ; reset the sprite X pointer
.increase_scroll_y_pointer:
                add.w d7,a5                     ; The address of the scroll Y axis
                addq #2, d7
                move.w d7, scroll_y_pointer     ; Store the next value for the future
                move.w (a5), d7
                move.l _raster_y_pos_start, _raster_y_pos_start + 4
                move.w d7, _raster_y_pos_start  ; Set the raster start Y position
                move.w d7, d0
                add.w #FONT_HEIGHT - 2, d0      ; Minus 2 because the raster is 2 pixels before the real start
                move.w d0, _raster_y_pos_start + 2    ; Set the raster end Y position

; d2 -> The memory offset to start to print the scroll (X=0, Y=(0..175))

; Exctract the next char to print from the demo text
                move.l demo_text_ptr,a0     ; We assume the _asm_scroll_init has been called before!
                move.b (MAX_WIDTH_SIZE,a0), d1
                tst.b d1                    ; If we are at the end of the scroll text, load init and start again
                bne.s .not_end_col
                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
.not_end_col:

; a6 -> The font to print memory address
                move.l _screen_next, a1; The screen position to print
                mulu #_SCREEN_WIDTH_BYTES, d7  

                move.w scroll_shift, d3
                add.b _screen_pixel_offset, d3

                lsr.w #4, d3
                add.w d3, d3
                add.w d3, d3
                add.w d3, d3
                add.w d3, a1                 ; Move 16 bits to the left for bits 16 to 31

                lea ascii_index, a2         ; The translation table from ASCII to local encoding 

                lea (a1, d7),a5
                sub.l #_SCREEN_WIDTH_BYTES * DELETE_BAR_HEIGHT, a5
                bsr delete_upper_lower_scroll
                add.l #_SCREEN_WIDTH_BYTES * (FONT_HEIGHT + DELETE_BAR_HEIGHT) , a5
                bsr delete_upper_lower_scroll

                sub.w #16,a1
                sub.w #16,a1                 ; Disappear behind the line offset

                REPT MAX_WIDTH_SIZE

                moveq #0, d1
                move.b (REPTN, a0), d1  
                sub.w #32,d1                ; substract 32 to start the index in 0
                move.b (a2,d1),d1           ; get the char from ascii to custom encoding
                mulu.w #FONT_LARGE_SIZE_WORDS * 2,d1  ; each char 'cost' FONT_LARGE_SIZE_WORDS bytes.

                bsr get_dithered_font

                add.w d1, a6                 ; a6 -> font memory

                move.w scroll_shift, d0
                add.b _screen_pixel_offset, d0
                and.w #15,d0                    ; d0 -> the bit shift (skew)
                move.w #REPTN, d1               ; d1 -> the char index
                add.w #16, a1
                lea (a1, d7),a5

                bsr print_font32x25_blitter

                ENDR 

                move.w scroll_shift, d0
                tst.w d0
                bne.s .not_increment_yet_char
                addq.l #1, demo_text_ptr
.not_increment_yet_char:
                subq.w #SCROLL_SPEED, d0
                and.w #31, d0
                move.w d0, scroll_shift
                rts

get_dithered_font:
                tst.w _screen_dither_tiktok
                bne.s .dither_f1
                lea _asm_font_large_ready_f0, a6
                rts
.dither_f1:     lea _asm_font_large_ready_f1, a6
                rts

; Right end mask for the blitter
rt_endmask:
                dc.w %0000000000000000
                dc.w %1000000000000000
                dc.w %1100000000000000
                dc.w %1110000000000000
                dc.w %1111000000000000
                dc.w %1111100000000000
                dc.w %1111110000000000
                dc.w %1111111000000000
                dc.w %1111111100000000
                dc.w %1111111110000000
                dc.w %1111111111000000
                dc.w %1111111111100000
                dc.w %1111111111110000
                dc.w %1111111111111000
                dc.w %1111111111111100
                dc.w %1111111111111110
                dc.w %1111111111111111

;   Print the font 32x25
;   Need to pass:
;       D0.W -> Skew position
;       D1.W -> Char index (0 to MAX_WIDTH_SIZE)
;       A5 -> Screen destination address
;       A6 -> Font source address  
print_font32x25_blitter:
; Allow a0,a1,a2 to cross the routine
; Allow d3,d4,d5,d6 and d7 to cross the routine
                mulu #(_BUFFER_NUMBERS * 4), d1 ; d1 <- points to init of the offset of the background buffer for the char as argument
                lea scroll_bckgrnd_idx, a4      ; a4 <- points to init of the offset of the background buffer for the char
                move.w _current_screen_mask, d2 ; d2 <- current screen mask
                add.w d2,d2                     ; d2 <- current screen mask * 2
                add.w d2,d2                     ; d2 <- current screen mask * 4
                add.w d1,d2                     ; d2 <- current screen mask * 4 + (char index * BUFFER_NUMBERS * 4)
                add.w d2, a4                    ; a4 <- background index buffer + current screen mask * 4 + (char index * BUFFER_NUMBERS * 4)
                move.l a5, (a4)                 ; Store the screen address in the background buffer

                move.w     d0,d2                        ; d2 <- skew position
                add.w      d2,d2                        ; d2 <- skew position * 2
                move.w    rt_endmask(pc,d2.w),d2        ; d2 <- obtain the end data mask

                or.b #%11000000, d0
                lea  $FF8A00,a3          ; a3-> BLiTTER register block
                move.w #8, SRC_X_INCREMENT(a3) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                move.w #8, SRC_Y_INCREMENT(a3) ; source Y increment. Increase the 4 planes.
                move.w #8, DEST_X_INCREMENT(a3) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                move.w #(_SCREEN_WIDTH_BYTES - DST_WIDTH + 2 * _SCREEN_BITPLANES), DEST_Y_INCREMENT(a3) ; dest Y increment. Increase the 4 planes.
                move.w #3, BLOCK_X_COUNT(a3) ; block X count. It seems don't need to reinitialize every bitplane.
                move.w #$FFFF, ENDMASK2_REG(a3) ; endmask2 register
                move.w d2, ENDMASK3_REG(a3) ; endmask3 register. The mask should covers the char column.
                not.w d2
                move.w d2, ENDMASK1_REG(a3) ; endmask1 register
                move.b #$2, BLITTER_HOP(a3) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                move.b #$3, BLITTER_OPERATION(a3) ; blitter operation. Copy src to dest, replace copy.
                move.b d0, BLITTER_SKEW(a3) ; blitter skew: -8 pixels and NFSR and FXSR.

                ; copy first plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                move.b #HOG_MODE, BLITTER_CONTROL_REG(a3) ; Hog mode
                addq.w #2, a6               ; Next bitplane src
                addq.w #2, a5               ; Next bitplane dest

                ; copy second plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                move.b #HOG_MODE, BLITTER_CONTROL_REG(a3) ; Hog mode
                addq.w #2, a6               ; Next bitplane src
                addq.w #2, a5               ; Next bitplane dest

                ; copy third plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                move.b #HOG_MODE, BLITTER_CONTROL_REG(a3) ; Hog mode

                rts

;  Delete the full scroll block from the screen
;  Need to pass:
;  a5 = screen address
delete_upper_lower_scroll:
        ; we are zeroing old buffer, so we dont need a source address to configure the blitter
        lea  $FF8A00,a4          ; a4-> BLiTTER register block
        move.w #8, DEST_X_INCREMENT(a4) ; dest X increment. Jump 3 (2 + 2 +2) planes.
        move.w #(_SCREEN_WIDTH_BYTES - 176 + 2 * _SCREEN_BITPLANES), DEST_Y_INCREMENT(a4) ; dest Y increment. Increase the 4 planes.
        move.w #(MAX_WIDTH_SIZE*2), BLOCK_X_COUNT(a4) ; block X count. It seems don't need to reinitialize every bitplane.
        move.w #$FFFF, ENDMASK1_REG(a4) ; endmask1 register
        move.w #$FFFF, ENDMASK2_REG(a4) ; endmask2 register
        move.w #$FFFF, ENDMASK3_REG(a4) ; endmask3 register. 
        move.b #$0, BLITTER_HOP(a4) ; blitter HOP operation. Zeroing the destination.
        move.b #$0, BLITTER_OPERATION(a4) ; blitter operation. Zeroing the destination.
        move.b #%00000000, BLITTER_SKEW(a4) ; blitter skew: No skew

        ; Repeat three times for the three planes
        ; first plane
        move.l a5, DEST_ADDR(a4)                                ; destination address
        move.w #DELETE_BAR_HEIGHT, BLOCK_Y_COUNT(a4)                           ; block Y count. This one must be reinitialized every bitplane
        move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode
        addq.w #2, a5                                           ; Next bitplane dest

        ; second plane
        move.l a5, DEST_ADDR(a4)                                ; destination address
        move.w #DELETE_BAR_HEIGHT, BLOCK_Y_COUNT(a4)                           ; block Y count. This one must be reinitialized every bitplane
        move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode
        addq.w #2, a5                                           ; Next bitplane dest
        ; third plane

        move.l a5, DEST_ADDR(a4)                                ; destination address
        move.w #DELETE_BAR_HEIGHT, BLOCK_Y_COUNT(a4)                           ; block Y count. This one must be reinitialized every bitplane
        move.b #HOG_MODE, BLITTER_CONTROL_REG(a4) ; Hog mode

        subq #4, a5
        rts


                section bss

demo_text_ptr   ds.l 1  ; Memory address of the current text to scroll left
scroll_bckgrnd_idx:
                REPT _BUFFER_NUMBERS * MAX_WIDTH_SIZE
                ds.l 1
                ENDR

                section data
                include src/scroller.inc    ; The scroller trigonometric tables

scroll_y_pointer: dc.w 0  ; Current pointer to the scroll_y_pos table. Even words


scroll_shift:   dc.w    0
scroll_last_y:  dc.w    0


ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 47, 26, 40, 47,47, 47, 47, 46, 41, 42     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 47, 47, 46, 44, 45, 47, 30, 31, 32, 33    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 34, 35, 36, 37, 38, 39, 28, 29, 47, 47    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 47, 27, 47, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

demo_text:      dc.b "          THIS IS THE ATARI ST SILLY DEMO. A SIMPLE DEMO ONLY TO REFRESH MY M68K CODING SKILLS AND WASTE TIME DOING USELESS STUFF THAT NOBODY CARES...          ",0
                EVEN

                end

