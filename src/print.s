                        include src/constants.s     ; Global constants. Start with '_'

    XDEF	_asm_print_str
    XDEF    _asm_print_rot
    XREF    _font_large_ready

FONT_LARGE_SIZE equ 400
LINE_SIZE       equ 24     ; Number of lines of the char - 1
COLUMN_SIZE     equ 16     ; Number of bytes per char line      
MAX_WIDTH_SIZE  equ 9      ; MAX_WIDTH_SIZE + 1 chars per line

                section code

;   Print the string and rotate incrementing the loop
;   Need to pass:
;       A3 -> Pointer to the memory screen to print
_asm_print_rot:
                move.l a0, -(a7)
                move.l demo_text_ptr,a0
                cmp.w #0, a0
                bne.s ptr_exists

                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
ptr_exists:
                tst.b (a0)
                bne.s not_end_string

                lea demo_text, a0           ; The ASCII text to demo
                move.l a0, demo_text_ptr    ; initialize the variable
not_end_string:
                bsr.s _asm_print_str
                
                addq #1, a0
                move.l a0, demo_text_ptr 

                move.l (a7)+, a0
                rts

;   Print the whole string
;   Need to pass:
;       A0 -> Pointer to the string to print on screen
;       A3 -> Pointer to the memory screen to print
_asm_print_str:
                movem.l d0-d7/a0-a6, -(a7)
                lea ascii_index, a1     ; The translation table from ASCII to local encoding 
                move.l _font_large_ready, a2    ; The memory address where the font is cooked

                moveq #0, d2                ; Relative X position in bytes of screen memory
                moveq #MAX_WIDTH_SIZE,d3    ; Number of chars per line
print_char:
                moveq #0, d0                ; Char in local format
                move.b (a0)+,d0        ; Obtain the char to print in ascii encoding
                beq.s end_print
                sub.w #32,d0            ; substract 32 to start the index in 0
                moveq #0, d1            ; The memory location of the char
                move.b (a1,d0),d1       ; get the char from ascii to custom encoding
                mulu.w #FONT_LARGE_SIZE_WORDS,d1          ; each char 'cost' 400 bytes.

                move.l d1, a6
                add.l a2, a6

                move.l d2,a5            
                add.l a3, a5

                bsr.s _asm_print_font32x25

                add.w #COLUMN_SIZE, d2            ; Next column
                dbf d3, print_char    

end_print:
                movem.l (a7)+, d0-d7/a0-a6 
                rts

;   Print the font 32x25
;   Need to pass:
;       A5 -> Screen destination address
;       A6 -> Font source address  
_asm_print_font32x25:
                movem.l d0-d7, -(a7)

;                movem.l  (a6)+, d0-d7
;                movem.l d0-d3, (a5)
                movem.l  (a6)+, d0-d3
                move.l d0, (a5)
                swap d1
                move.w d1, 4(a5)
                move.l d2, 8(a5)
                swap d3
                move.w d3, 12(a5)

                rept LINE_SIZE - 1
;                movem.l  (a6)+, d0-d7
;                movem.l d0-d3, ((REPTN + 1)*320,a5)
;                movem.l d4-d7, (_SCREEN_WIDTH_BYTES + (REPTN + 1)*320,a5)

                movem.l  (a6)+, d0-d3
                move.l d0, ((REPTN + 1)*_SCREEN_WIDTH_BYTES,a5)
                swap d1
                move.w d1, (4 +(REPTN + 1)*_SCREEN_WIDTH_BYTES,a5)
                move.l d2, (8 + (REPTN + 1)*_SCREEN_WIDTH_BYTES,a5)
                swap d3
                move.w d3, (12 + (REPTN + 1)*_SCREEN_WIDTH_BYTES,a5)
                endr

;                movem.l  (a6)+, d0-d3
;                movem.l d0-d3, (3840,a5)

                movem.l (a7)+, d0-d7
                rts

                section bss
demo_text_ptr   ds.l 1  ; Memory address of the current text to print
                ds.b    256

                section data
ascii_index:                                                   ; Index table to translate ASCII to chars
                dc.b 47, 26, 40, 47,47, 47, 47, 46, 41, 42     ; SPACE, !, ", #, $, %, &, ', (, )
                dc.b 47, 47, 46, 44, 45, 47, 30, 31, 32, 33    ; *, +, ,, -, ., /, 0, 1, 2, 3
                dc.b 34, 35, 36, 37, 38, 39, 28, 29, 47, 47    ; 4, 5, 6, 7, 8, 9, :, ;, <, =
                dc.b 47, 27, 47, 0, 1, 2, 3, 4, 5, 6           ; >, ?, @, A, B, C, D, E, F, G
                dc.b 7, 8, 9, 10, 11, 12, 13, 14, 15, 16       ; H, I, J, K, L, M, N, O, P, Q
                dc.b 17, 18, 19, 20, 21, 22, 23, 24, 25        ; R, S, T, U, V, W, X, Y, Z

demo_text:      dc.b "BIENVENIDOS A LA DEMOSCENE! HOY TE INVITAMOS A DISFRUTAR DE NUESTRA ULTIMA CREACION: UN SCROLL DE DEMOSCENE LLENO DE COLORES Y EFECTOS VISUALES QUE TE DEJARAN SIN ALIENTO.",0

