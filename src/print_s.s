                        include src/constants.s     ; Global constants. Start with '_'

; Small chars print routine
; 16x16 pixels and 1 bit plane

    XDEF	_asm_print_small_str
    XREF    _font_small_ready

FONT_SMALL_SIZE         equ 32     ; 2 bytes per line x 16 lines x 1 plane
LINE_SIZE               equ 16     ; Number of lines of the char
SCREEN_COLUMN_SIZE      equ 8      ; Number of bytes per char line      
MAX_WIDTH_SIZE          equ 19     ; MAX_WIDTH_SIZE + 1 chars per line

                section code

;   Print the whole string
;   Need to pass:
;       A0 -> Pointer to the string to print on screen
;       A3 -> Pointer to the memory screen to print
_asm_print_small_str:
                movem.l d0-d7/a0-a6, -(a7)
                lea ascii_index, a1     ; The translation table from ASCII to local encoding 
                move.l _font_small_ready, a2    ; The memory address where the font is cooked

                moveq #0, d2                ; Relative X position in bytes of screen memory
                moveq #MAX_WIDTH_SIZE,d3    ; Number of chars per line
print_char:
                moveq #0, d0                ; Char in local format
                move.b (a0)+,d0        ; Obtain the char to print in ascii encoding
                beq.s end_print
                sub.b #32,d0            ; substract 32 to start the index in 0
                moveq #0, d1            ; The memory location of the char
                move.b (a1,d0),d1       ; get the char from ascii to custom encoding
                mulu.w #FONT_SMALL_SIZE,d1          ; each char 'cost' FONT_SMALL_SIZE bytes.

                move.l d1, a6
                add.l a2, a6

                move.l d2,a5            
                add.l a3, a5

                bsr.s _asm_print_font16x16

                add.w #SCREEN_COLUMN_SIZE, d2            ; Next column
                dbf d3, print_char    

end_print:
                movem.l (a7)+, d0-d7/a0-a6 
                rts

;   Print the font 16x16
;   Need to pass:
;       A5 -> Screen destination address
;       A6 -> Font source address  
_asm_print_font16x16:
                rept LINE_SIZE
                move.w  (a6)+, (REPTN*_SCREEN_WIDTH_BYTES,a5)
                endr
                rts

                section bss
demo_text_ptr   ds.l 1  ; Memory address of the current text to print
                ds.b    256

                section data align 2
ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 39, 39, 39, 39, 39, 39, 39, 39, 39, 39     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 39, 39, 38, 39, 37, 39, 35, 26, 27, 28    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 29, 30, 31, 32, 33, 34, 39, 39, 39, 39    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 39, 36, 39, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

