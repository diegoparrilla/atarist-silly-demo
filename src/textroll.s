                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_textroll_init
    XDEF    _asm_show_textroll_bar
    XDEF    _asm_restore_textroll_bar
    XREF    _screen_next
    XREF    _current_screen_mask        ; The buffered screen index
    XREF    _screen_absolute_offset
    XREF    _screen_pixel_offset
    XREF    _screen_dither_tiktok
    XREF    _raster_y_pos_start
    XREF    _asm_font_large_ready_f0
    XREF    _asm_font_large_ready_f1

    XREF    _asm_nf_debugger

                ; Scrolling section

FONT_REAL_HEIGHT        equ 25
FONT_HEIGHT             equ 28
FONT_BITPLANES          equ 4
FONT_VISIBLE_BITPLANES  equ 4
FONT_WIDTH              equ 6 * FONT_BITPLANES ; 6 bytes per char (32 pixels + 16 buffer) x 4 bitplanes
FONT_VISIBLE_WIDTH      equ 4 * FONT_VISIBLE_BITPLANES ; 4 bytes per char (32 pixels) x 3 bitplanes + 1 mask bitplane
FONT_LARGE_SIZE_NO_GUARDS   equ FONT_REAL_HEIGHT * FONT_WIDTH
FONT_LARGE_SIZE         equ FONT_HEIGHT * FONT_WIDTH
TEXT_ROLL_LENGTH        equ 147; 147 chars in demo_text + 1 for the end of string
MEMORY_BUFFER_WIDTH_BYTES equ TEXT_ROLL_LENGTH * FONT_VISIBLE_WIDTH
SCROLL_SPEED            equ 2      ; Bits to rotate the scroll. Must be 2^n
TEXT_ROLL_BUFFERS       equ 24      ; Number of buffers to use for the text roll

                section code

                MACRO BLIT_MODE
                or.b #F_LINE_BUSY,BLITTER_CONTROL_REG(a3)    ; << START THE BLITTER >>
.\@wait_blitter:
                bset.b    #M_LINE_BUSY,BLITTER_CONTROL_REG(a4)       ; Restart BLiTTER and test the BUSY
                nop                      ; flag state.  The "nop" is executed
                bne.s  .\@wait_blitter     ; prior to the BLiTTER restarting.
                ENDM

                MACRO HOG_MODE
                move.b #HOG_MODE, BLITTER_CONTROL_REG(a3) ; Hog mode
                ENDM


; Init the scroll routine. It pre-print all the chars of the text roll and
; made all the calculations to rotate the scroll
_asm_textroll_init:
;                IIF _DEBUG jsr _asm_nf_debugger

                move.w #(32-SCROLL_SPEED), scroll_shift    ; The shift init value for the scroll (skew)
                clr.w text_index
                clr.l scroll_last_mem
                clr.l scroll_next_mem

                moveq #(TEXT_ROLL_BUFFERS / 2) - 1, d7
                lea textroll_buffer, a6 ; The memory address where the font is cooked
                moveq #0, d0

.twist_all_str:
                lea demo_text, a0           ; The ASCII text to demo
                move.l a6,a3
                lea _asm_font_large_ready_f0, a2    ; The memory address where the font is stored
                bsr print_str
                move.l a6,a3
                bsr.s twist_str

                addq #2, d0
                add.l #FONT_LARGE_SIZE*TEXT_ROLL_LENGTH, a6

                lea demo_text, a0           ; The ASCII text to demo
                move.l a6, a3
                lea _asm_font_large_ready_f1, a2    ; The memory address where the font is stored
                bsr print_str
                move.l a6,a3
                bsr.s twist_str

                add.l #FONT_LARGE_SIZE*TEXT_ROLL_LENGTH, a6
                addq #2, d0
.no_reset_sinwave_index:
                dbf d7, .twist_all_str
                rts

; Twist the whole text roll
; Need to pass:
;       A3 -> The memory address of the text roll
;       D0 -> The scroll Y skew position (0 to 24) (0 = skew 1, 24 = skew 25)
twist_str:
;                IIF _DEBUG jsr _asm_nf_debugger

                move.w d0, -(a7)
                move.w #TEXT_ROLL_LENGTH * (32 / 8), d1 ; Calculate the number of bytes to rotate
                move.w d0, textroll_sinwave_index
                lea textroll_sinwave, a5
                add.w d0, a5
.twist_next_byte:
                move.w (a5)+, d2           ; Save the skew value
                beq .twist_next_byte_skip
                subq #1, d2
.twist_next_skew:
                move.l a3, a0           ; Save the memory address
                add.l #MEMORY_BUFFER_WIDTH_BYTES * (FONT_HEIGHT - 1), a0
                moveq #0, d3
                move.b (0, a0), d3      ; Get the first plane
                lsl.l #8, d3
                move.b (2, a0), d3      ; Get the second plane
                lsl.l #8, d3
                move.b (4, a0), d3      ; Get the third plane
                lsl.l #8, d3
                move.b (6, a0), d3      ; Get the fourth plane

                REPT FONT_HEIGHT - 1
                moveq #0, d4
                move.b (0 - MEMORY_BUFFER_WIDTH_BYTES, a0), d4      ; Get the first plane
                move.b d4, (0, a0) 

                move.b (2 - MEMORY_BUFFER_WIDTH_BYTES, a0), d4      ; Get the second plane
                move.b d4, (2, a0)

                move.b (4 - MEMORY_BUFFER_WIDTH_BYTES, a0), d4      ; Get the third plane
                move.b d4, (4, a0)

                move.b (6 - MEMORY_BUFFER_WIDTH_BYTES, a0), d4      ; Get the fourth plane
                move.b d4, (6, a0)

                sub.l #MEMORY_BUFFER_WIDTH_BYTES, a0
                ENDR

                move.b d3, (6, a0)     ; Put the fourth plane of the top line
                lsr.l #8, d3
                move.b d3, (4, a0)      ; Put the third plane of the top line
                lsr.l #8, d3
                move.b d3, (2, a0)      ; Put the second plane of the top line
                lsr.l #8, d3
                move.b d3, (0, a0)      ; Put the first plane of the top line

                dbf d2, .twist_next_skew

.twist_next_byte_skip:
                addq.w #1, a3       ; Increment the memory address by one byte
                move.l a3, d3
                btst #0, d3         ; Check if the memory address is odd
                bne.s .no_plane_jump    ; If odd, jump to the next byte
                addq #6, a3         ; If even, jump to the next byte + 7 bytes (to skip all the planes
.no_plane_jump:
                move.w textroll_sinwave_index, d0
                addq #2, d0
                move.w d0, textroll_sinwave_index
                cmp.w textroll_table_size, d0
                bne.s .no_skew_restart
                lea textroll_sinwave, a5
                clr.w textroll_sinwave_index
.no_skew_restart:
                dbf d1, .twist_next_byte
                move.w (a7)+, d0
                rts





;   Print the whole string
;   Need to pass:
;       A0 -> Pointer to the string to print on screen
;       A2 -> Pointer to large font memory
;       A3 -> Pointer to the memory screen to print
print_str:
                movem.l d0-d7/a0-a6, -(a7)
                lea ascii_index, a1     ; The translation table from ASCII to local encoding 

                moveq #0, d2                ; Relative X position in bytes of screen memory
print_char:
                moveq #0, d0                ; Char in local format
                move.w d0, d1
                move.b (a0)+,d0        ; Obtain the char to print in ascii encoding
                beq.s end_print
                sub.w #32,d0            ; substract 32 to start the index in 0
                move.b (a1,d0),d1       ; get the char from ascii to custom encoding
                mulu.w #FONT_LARGE_SIZE_NO_GUARDS,d1          ; each char 'cost' FONT_LARGE_SIZE bytes.

                move.l d1, a6
                add.l a2, a6             ; a6 -> Font char source address

                move.l d2,a5             ; a5 -> Memory destination address            
                add.l a3, a5

                bsr.s print_font32x25

                add.l #FONT_VISIBLE_WIDTH, d2            ; Next column
                bra.s print_char    

end_print:
                movem.l (a7)+, d0-d7/a0-a6 
                rts

;   Print the font 32x25
;   Need to pass:
;       A5 -> Screen destination address
;       A6 -> Font source address  
print_font32x25:
                movem.l d0-d5, -(a7)
                move.w #FONT_REAL_HEIGHT - 1, d4
.print_next_line:
                ; Jump the 16 pixels buffer of the font
                addq #8, a6

                movem.l  (a6)+, d0-d3
                ; Write first 16 pixels
                move.l d0, (a5)
                move.w d0, d5
                swap d0
                or.w d0, d5
                swap d1
                or.w d1, d5
                not.w d5
                move.w d1, (4, a5)
                move.w d5, (6, a5)

                ; Write next 16 pixels
                move.l d2, (8, a5)
                move.w d2, d5
                swap d2
                or.w d2, d5
                swap d3
                or.w d3, d5
                not.w d5
                move.w d3, (12, a5)
                move.w d5, (14, a5)

                ; Jump to the next line
                add.l #MEMORY_BUFFER_WIDTH_BYTES, a5
                dbf d4, .print_next_line


                moveq #0, d0
                moveq #-1, d1
                REPT FONT_HEIGHT - FONT_REAL_HEIGHT

                move.l d0, (a5)
                move.w d0, (4, a5)
                move.w d1, (6, a5)
                move.l d0, (8, a5)
                move.w d0, (12, a5)
                move.w d1, (14, a5)

                ; Jump to the next line
                add.l #MEMORY_BUFFER_WIDTH_BYTES, a5
                ENDR

                movem.l (a7)+, d0-d5
                rts

;   Print the text roll bar
_asm_show_textroll_bar:
;                IIF _DEBUG jsr _asm_nf_debugger

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

                move.l _screen_next, a5; The screen position to print
                mulu #_SCREEN_WIDTH_BYTES, d7
                add.l d7, a5  

                add.l #_SCREEN_WIDTH_BYTES - 16, a5
;                tst.w _screen_dither_tiktok
;                bne.s .dither_tok
;                lea textroll_buffer, a6
;                bra.s .continue_dither
;.dither_tok:
;                lea textroll_buffer + MEMORY_BUFFER_WIDTH_BYTES, a6
;.continue_dither:
                lea textroll_buffer, a6
                moveq   #0, d7
                move.w textroll_buffer_index, d7
                move.w d7, d6
                addq #1, d6
                cmp.w #TEXT_ROLL_BUFFERS-1, d6
                blt.s .no_reset_textroll_buffer_index
                moveq #0, d6
.no_reset_textroll_buffer_index:
                move.w d6, textroll_buffer_index
                mulu #FONT_LARGE_SIZE, d7
                mulu #TEXT_ROLL_LENGTH, d7
                add.l d7, a6
                add.w text_index, a6
                move.w scroll_shift, d3
                add.b _screen_pixel_offset, d3
                move.w d3, d0

                lsr.w #4, d3
                add.w d3, d3
                add.w d3, d3
                add.w d3, d3
                add.w d3, a5                 ; Move 16 bits to the left for bits 16 to 31

                move.l scroll_last_mem, scroll_next_mem
                move.l a5, scroll_last_mem

                lea  $FF8A00,a3          ; a3-> BLiTTER register block
                move.w #FONT_VISIBLE_BITPLANES * 2, SRC_X_INCREMENT(a3) ; source X increment. Jump 3 (2 + 2 + 2) planes.
                move.w #MEMORY_BUFFER_WIDTH_BYTES - ((_SCREEN_WIDTH_BYTES / _SCREEN_BITPLANES) * FONT_VISIBLE_BITPLANES) + FONT_VISIBLE_BITPLANES * 2, SRC_Y_INCREMENT(a3) ; source Y increment. Increase the 4 planes.
                move.w #_SCREEN_BITPLANES * 2, DEST_X_INCREMENT(a3) ; dest X increment. Jump 3 (2 + 2 + 2) planes.
                move.w #_SCREEN_BITPLANES * 2, DEST_Y_INCREMENT(a3) ; dest Y increment. Increase the 4 planes.
                move.w #( _SCREEN_WIDTH_BYTES / _SCREEN_BITPLANES) / 2, BLOCK_X_COUNT(a3) ; block X count. It seems don't need to reinitialize every bitplane.
                move.w #$FFFF, ENDMASK2_REG(a3) ; endmask2 register
                move.w #$FFFF, ENDMASK3_REG(a3) ; endmask3 register. The mask should covers the char column.
                move.w #$FFFF, ENDMASK1_REG(a3) ; endmask1 register
                move.b d0, BLITTER_SKEW(a3) ; blitter skew: -8 pixels and NFSR and FXSR.

.apply_AND:
                move.b #$2, BLITTER_HOP(a3) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                move.b #$1, BLITTER_OPERATION(a3) ; blitter operation. Source AND Target (inverse copy)

                ; The mask is the fourth bitplane
                addq #6, a6
                ; copy first plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a5               ; Next bitplane dest

                ; copy second plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a5               ; Next bitplane dest

                ; copy third plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
.apply_OR:
                ; Restore to the first bitplane origin
                subq #6, a6

                ; Go back to the first bitplane of the destination screen
                subq #4, a5

                move.b #$2, BLITTER_HOP(a3) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                move.b #$7, BLITTER_OPERATION(a3) ; blitter operation. Source OR Target (combine copy)
                ; copy first plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a6               ; Next bitplane src
                addq.w #2, a5               ; Next bitplane dest

                ; copy second plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a6               ; Next bitplane src
                addq.w #2, a5               ; Next bitplane dest

                ; copy third plane
                move.l a6, SRC_ADDR(a3)  ; source address
                move.l a5, DEST_ADDR(a3) ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3) ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE

.clean_previous_textroll_bar_end:
                move.w scroll_shift, d0
                tst.w d0
                bne.s .not_increment_yet_char                
                add.w #FONT_VISIBLE_WIDTH, text_index
                cmp.w #(TEXT_ROLL_LENGTH - 1) * FONT_VISIBLE_WIDTH, text_index
                blt.s .not_increment_yet_char
                clr.w text_index
.not_increment_yet_char:
                subq.w #SCROLL_SPEED, d0
                and.w #31, d0
                move.w d0, scroll_shift

                rts

;   Restore the text roll bar
_asm_restore_textroll_bar:

                move.l scroll_next_mem, a5            ; The travelling routine for the scroll Y axis
                cmp.l #0, a5
                beq .no_scroll_y

                lea  $FF8A00,a3          ; a3-> BLiTTER register block
                move.w #_SCREEN_BITPLANES * 2, DEST_X_INCREMENT(a3) ; dest X increment. Jump 3 (2 + 2 + 2) planes.
                move.w #_SCREEN_BITPLANES * 2, DEST_Y_INCREMENT(a3) ; dest Y increment. Increase the 4 planes.
                move.w #( _SCREEN_WIDTH_BYTES / _SCREEN_BITPLANES) / 2, BLOCK_X_COUNT(a3) ; block X count. It seems don't need to reinitialize every bitplane.
                move.w #$FFFF, ENDMASK2_REG(a3) ; endmask2 register
                move.w #$FFFF, ENDMASK3_REG(a3) ; endmask3 register. The mask should covers the char column.
                move.w #$FFFF, ENDMASK1_REG(a3) ; endmask1 register
                move.b #$0, BLITTER_SKEW(a3) ; blitter skew: -8 pixels and NFSR and FXSR.
                move.b #$0, BLITTER_HOP(a3) ; blitter HOP operation. Zeroing the destination.
                move.b #$0, BLITTER_OPERATION(a3) ; blitter operation. Zeroing the destination.

                ; Repeat three times for the three planes
                ; first plane
                move.l a5, DEST_ADDR(a3)                                ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3)            ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a5                                           ; Next bitplane dest

                ; second plane
                move.l a5, DEST_ADDR(a3)                                ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3)            ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
                addq.w #2, a5                                           ; Next bitplane dest

                ; third plane
                move.l a5, DEST_ADDR(a3)                                ; destination address
                move.w #FONT_HEIGHT, BLOCK_Y_COUNT(a3)            ; block Y count. This one must be reinitialized every bitplane
                BLIT_MODE
.no_scroll_y:
                rts



                section bss
                EVEN
textroll_buffer:
                REPT TEXT_ROLL_BUFFERS
                ds.l FONT_LARGE_SIZE*TEXT_ROLL_LENGTH / 4
                ENDR

                section data
                
                section data
                include src/scroller.inc    ; The scroller trigonometric tables
                include src/textroll.inc    ; The texroll trigonometric tables

scroll_y_pointer: dc.w 0  ; Current pointer to the scroll_y_pos table. Even words

scroll_last_mem:
                dc.l 0  ; Previous memory address of the scroll
scroll_next_mem:
                dc.l 0  ; Next memory address of the scroll

scroll_shift:   dc.w    0
text_index:     dc.w    0
textroll_buffer_index: dc.w 0
textroll_sinwave_index: dc.w 0

ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 47, 26, 40, 47,47, 47, 47, 46, 41, 42     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 47, 47, 46, 44, 45, 47, 30, 31, 32, 33    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 34, 35, 36, 37, 38, 39, 28, 29, 47, 47    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 47, 27, 47, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

demo_text:      dc.b "          THIS IS THE ATARI ST SILLY DEMO. A SIMPLE DEMO ONLY TO REFRESH MY M68K CODING SKILLS AND WASTE TIME DOING USELESS STUFF THAT NOBODY CARES",0

                EVEN

                end

