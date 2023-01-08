    XDEF    _asm_column_rotate
    XDEF    _scroll_type
    XREF    _screen_next
    XREF    _screen_last
    XREF    _font_large_ready

                ; Scrolling section

FONT_LARGE_SIZE equ 400
COLUMN_SIZE     equ 8
MAX_WIDTH_SIZE  equ 9      ; MAX_WIDTH_SIZE + 1 chars per line

; Blitter section
HALFTONE_RAM        equ $00
SRC_ADDR            equ $24
SRC_X_INCREMENT     equ $20
SRC_Y_INCREMENT     equ $22
ENDMASK1_REG        equ $28
ENDMASK2_REG        equ $2A
ENDMASK3_REG        equ $2C
DEST_ADDR           equ $32
DEST_X_INCREMENT    equ $2E
DEST_Y_INCREMENT    equ $30
BLOCK_X_COUNT       equ $36
BLOCK_Y_COUNT       equ $38
BLITTER_HOP         equ $3A
BLITTER_OPERATION   equ $3B
BLITTER_CONTROL_REG equ $3C
BLITTER_SKEW        equ $3D

M_LINE_BUSY           equ  7
F_LINE_BUSY           equ  %10000000

                section code

;   Print the column and scroll to the left
_asm_column_rotate:
                moveq #0, d1
                move.l demo_text_ptr,a0
                cmp.w #0, a0
                bne.s ptr_col_exists

                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
ptr_col_exists:
                move.b (a0), d1
                tst.b d1
                bne.s not_end_col

                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
                move.b (a0), d1
not_end_col:
                move.w scroll_shift, d0
                lsl.w #8, d1
                or.w d1,d0

                bsr.s _asm_scroll_left
                
                move.w scroll_shift, d0
                addq #1, d0
                and.w #3, d0
                move.w d0, scroll_shift
                
                tst.b d0
                bne.s not_increment_yet_char
                addq #1, a0
                move.l a0, demo_text_ptr 
not_increment_yet_char:
                rts

;   Scroll to the left and print the column in the gap
;   Need to pass:
;       D0.W.H -> CHAR in ASCII encoding to print
;       D0.W.L -> Column to print of the char
_asm_scroll_left:

                move.l  _screen_last, a3
                move.l  _screen_next, a4

                tst.w _scroll_type
                bne.s scroll_type_movep   
                bsr.b _asm_scroll_left_by_byte
                bra.b update_text

scroll_type_movep:
                cmp.w #1, _scroll_type
                bne.s scroll_type_blitter
                jsr _asm_scroll_left_by_byte_movep
                bra.b update_text

scroll_type_blitter:
                jsr _asm_scroll_left_by_byte_blitter

update_text:
                lea ascii_index, a1     ; The translation table from ASCII to local encoding 
                move.l _font_large_ready, a2    ; The memory address where the font is cooked

                move.w d0, d1           ; The memory location of the char
                and.w #$ff, d0         ; Keep in d0 the column to print
                lsr.w #8, d1            ; get the char from ascii to custom encoding
                sub.w #32,d1            ; substract 32 to start the index in 0
                move.b (a1,d1),d1       ; get the char from ascii to custom encoding
                mulu.w #FONT_LARGE_SIZE,d1          ; each char 'cost' 800 bytes.

                move.l d1, a6
                add.l a2, a6        ; a6 -> font memory

                move.l  _screen_next, a5
                lea  (152,a5), a5   

                jsr _asm_print_font32x25_col  
                rts

;   Simple scroll to the left byte by byte
;   Need to pass:
;       A3 -> Screen origin address
;       A4 -> Screen destination address
_asm_scroll_left_by_byte:
                rept 500
                move.b  1(a3), (a4)
                move.b  3(a3), 2(a4)
                move.b  5(a3), 4(a4)
;                move.b  7(a3), 6(a4)            ; 8 pixels moved
                move.b  8(a3), 1(a4)            ; watch carefully!
                move.b  10(a3), 3(a4)          
                move.b  12(a3), 5(a4)         
;                move.b  14(a3), 7(a4)           ; first 4 word area filled
                addq   #8, a3                  ; point to beginning of next line
                addq   #8, a4                  ; point to beginning of next line
                endr
                rts

;   Simple scroll to the left byte by byte using movep
;   Need to pass:
;       A3 -> Screen origin address
;       A4 -> Screen destination address
_asm_scroll_left_by_byte_movep:
                rept 500
                movep.l (1+(REPTN * 8), a3), d6
                movep.l d6, ((REPTN * 8),a4)
                movep.l (8+(REPTN * 8), a3), d7
                movep.l d7, (1+ (REPTN * 8),a4)
                endr
                rts

;   Simple scroll to the left byte by byte using BLITTER
;   Need to pass:
;       A3 -> Screen origin address
;       A4 -> Screen destination address
_asm_scroll_left_by_byte_blitter:


        lea  $FF8A00,a5          ; a5-> BLiTTER register block

        move.w #$8, SRC_X_INCREMENT(a5) ; source X increment. Jump 3 (2 + 2 + 2) planes.
        move.w #8, SRC_Y_INCREMENT(a5) ; source Y increment. Increase the 4 planes.
        move.w #8, DEST_X_INCREMENT(a5) ; dest X increment. Jump 3 (2 + 2 +2) planes.
        move.w #8, DEST_Y_INCREMENT(a5) ; dest Y increment. Increase the 4 planes.
        move.w #20, BLOCK_X_COUNT(a5) ; block X count. It seems don't need to reinitialize every bitplane.
        move.w #$FFFF, ENDMASK1_REG(a5) ; endmask1 register
        move.w #$FFFF, ENDMASK2_REG(a5) ; endmask2 register
        move.w #$FF00, ENDMASK3_REG(a5) ; endmask3 register. The mask should covers the char column. 
        move.b #$2, BLITTER_HOP(a5) ; blitter HOP operation. Copy src to dest, 1:1 operation.
        move.b #$3, BLITTER_OPERATION(a5) ; blitter operation. Copy src to dest, replace copy.
        move.b #%11001000, BLITTER_SKEW(a5) ; blitter skew: -8 pixels and NFSR and FXSR.

        moveq #$2, d3     ; 3 Bitplanes
bitplanes:
        move.l a3, SRC_ADDR(a5)  ; source address
        move.l a4, DEST_ADDR(a5) ; destination address
        move.w #25, BLOCK_Y_COUNT(a5) ; block Y count. This one must be reinitialized every bitplane
        or.b #F_LINE_BUSY,BLITTER_CONTROL_REG(a5)    ; << START THE BLITTER >>
     restart:
          bset.b    #M_LINE_BUSY,BLITTER_CONTROL_REG(a5)       ; Restart BLiTTER and test the BUSY
          nop                      ; flag state.  The "nop" is executed
          bne  restart             ; prior to the BLiTTER restarting.
                                   ; Quit if the BUSY flag was clear.  

        addq.w #2, a3               ; Next bitplane src
        addq.w #2, a4               ; Next bitplane dest
        dbf d3, bitplanes

        rts


;   Print the column of the font 32x25
;   Need to pass:
;       A5 -> Screen destination address
;       A6 -> Font source address
;       D0 -> Column to print (0-3)
_asm_print_font32x25_col:
                tst.w d0              ; Column 0
                beq.s print_font32x25_start

                addq #1, a6               ; Column 1
                cmp.w #1, d0
                beq.s print_font32x25_start

                addq #7, a6               ; Column 2
                cmp.w #2, d0
                beq.s print_font32x25_start

                addq #1, a6               ; Column 3

print_font32x25_start:
                move.b  (a6), 1(a5)
                move.b  2(a6), 3(a5)
                move.b  4(a6), 5(a5)
;                move.b  6(a6), 7(a5)
                lea (16,a6), a6

                rept 24
                move.b  (a6), (1 + (REPTN + 1)*160, a5)
                move.b  2(a6),(3 + (REPTN + 1)*160, a5)
                move.b  4(a6),(5 + (REPTN + 1)*160, a5)
;                move.b  6(a6),(7 + (REPTN + 1)*160, a5)
                lea (16,a6), a6
                endr
                rts

;   Print the column of the font 32x25 with movep
;   Need to pass:
;       A5 -> Screen destination address
;       A6 -> Font source address
;       D0 -> Column to print (0-3)
_asm_print_font32x25_col_movep:
                tst.w d0              ; Column 0
                beq.s print_font32x25_start_movep

                addq #1, a6               ; Column 1
                cmp.w #1, d0
                beq.s print_font32x25_start_movep

                addq #7, a6               ; Column 2
                cmp.w #2, d0
                beq.s print_font32x25_start_movep

                addq #1, a6               ; Column 3
print_font32x25_start_movep:
                rept 25
                movep.l ((REPTN*16),a6), d6
                movep.l d6, (1 + (REPTN * 160),a5)
                endr
                rts

                section bss
demo_text_ptr   ds.l 1  ; Memory address of the current text to scroll left

                ds.b    256

                section data
scroll_shift:   dc.w    0
_scroll_type:   dc.w    0   ; 0 = byte by byte, 1 = movep

ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 47, 26, 40, 47,47, 47, 47, 46, 41, 42     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 47, 47, 46, 44, 45, 47, 30, 31, 32, 33    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 34, 35, 36, 37, 38, 39, 28, 29, 47, 47    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 47, 27, 47, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

demo_text:      dc.b "ESTA ES UNA PRUEBA DE SCROLL HORIZONTAL. VAMOS A VER SI FUNCIONA COMO ESPERAMOS.",0

