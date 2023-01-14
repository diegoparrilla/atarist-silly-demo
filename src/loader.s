    XDEF    _asm_populate_bin_ptrs
    XDEF	_asm_display_picture
    XDEF	_asm_display_picture_fast


LOOP_CYCLES     equ 615
COPY_INCREMENT  equ 52

breakpoint:
                movem.l d7/a6, -(a7)
                moveq    #1,D7
                move.l   D7,A6       ; A6 = 1
                move.w   D7,-(A6)    ; Attempt to access address -1 and provokes an address error exception
                movem.l (a7)+,d7/a6
                rts

_asm_populate_bin_ptrs:
                lea.l  _asm_font_large_ready,a0
                move.l a0, _font_large_ready
                lea.l  _asm_font_large,a0
                move.l a0, _font_large_ptr
                lea.l  _asm_font_small,a0
                move.l a0, _font_small_ptr
                lea.l  _asm_c23_logo,a0
                move.l a0, _c23_logo_ptr
                rts


_asm_display_picture:
                move.l _screen, a0
                move.l _picture, a1
                lea (34,a1),a1
;                lea  _asm_font_large+34, a1      ; a1 points to picture

;                moveq    #1,D7
;                move.l   D7,A6       ; A6 = 1
;                move.w   D7,-(A6)    ; Attempt to access address -1 and provokes an address error exception

                move.l  #7999, d0                ; 8000 longwords to a screen
loop
                move.l  (a1)+, (a0)+             ; move one longword to screen
                dbf     d0, loop

                rts

_asm_display_picture_fast:
                movem.l d0-d7/a0-a6, -(a7)

                move.l _screen, a5
                move.l _picture, a6
                lea (34,a6),a6

;                lea  _asm_font_large+34, a6          ; a6 points to picture

                rept LOOP_CYCLES
                movem.l  (a6)+, d0-d7/a0-a4
                movem.l d0-d7/a0-a4, REPTN*COPY_INCREMENT(a5)
                endr

                movem.l (a7)+, d0-d7/a0-a6 
                rts

                section bss

                XDEF    _font_large_ready:
                XDEF    _font_large_ptr
                XDEF    _font_small_ptr
                XDEF    _c23_logo_ptr
                XDEF    _screen
                XDEF    _picture

_font_large_ready: ds.l 1
_font_large_ptr: ds.l 1
_font_small_ptr: ds.l 1
_c23_logo_ptr:   ds.l 1
_screen:         ds.l 1
_picture:        ds.l 1

                section data

_asm_font_large:
                incbin  resources/FONT.PI1
_asm_font_small:
                incbin  resources/FONT1616.PI1
_asm_c23_logo:
                incbin  resources/C23.PI1

NUMBER_OF_ROTATIONS         equ 1
FONT_LARGE_SIZE_WORDS       equ 400
NUMBER_FONTS                equ 48
_asm_font_large_ready:
                ds.w FONT_LARGE_SIZE_WORDS * NUMBER_FONTS * NUMBER_OF_ROTATIONS   ; The arranged memory fonts
