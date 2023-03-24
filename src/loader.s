
                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_populate_bin_ptrs
    XDEF	_asm_display_picture
    XDEF	_asm_display_picture_fast
    XDEF    _asm_get_machine_type
    XDEF    _asm_get_memory_size

    XREF    _asm_nf_stderr
    XREF    _asm_nf_debugger

                section code


LOOP_CYCLES     equ 615
COPY_INCREMENT  equ 52
;FILE_FORMAT_OFFSET equ 34     ; 34 bytes of file format header for PI1
FILE_FORMAT_OFFSET equ 38     ; 34 bytes of file format header for PBM


breakpoint:
                movem.l d7/a6, -(a7)
                moveq    #1,D7
                move.l   D7,A6       ; A6 = 1
                move.w   D7,-(A6)    ; Attempt to access address -1 and provokes an address error exception
                movem.l (a7)+,d7/a6
                rts

_asm_populate_bin_ptrs:
                lea.l  _asm_font_small_ready,a0
                move.l a0, _font_small_ready
                rts


_asm_display_picture:
                move.l _screen, a0
                move.l _picture, a1
                lea (FILE_FORMAT_OFFSET,a1),a1
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
                lea (FILE_FORMAT_OFFSET,a6),a6

;                lea  _asm_font_large+34, a6          ; a6 points to picture

                rept LOOP_CYCLES
                movem.l  (a6)+, d0-d7/a0-a4
                movem.l d0-d7/a0-a4, REPTN*COPY_INCREMENT(a5)
                endr

                movem.l (a7)+, d0-d7/a0-a6 
                rts

; ABOUT INTERFACING C AND ASSEMBLY LANGUAGE FUNCTIONS
; https://gendev.spritesmind.net/files/xgcc/xgcc.pdf
; Chapter 4.2 

; Returns in D0.L the machine type. 0 if no cookie found.
; Cookie is '_MCH' followed by a longword with the machine type.
; Cookie is located at $5a0.
; https://freemint.github.io/tos.hyp/en/bios_cookiejar.html#Cookie_2C_20_MCH

P_COOKIE        equ $5a0
P_COOKIE_MCH    equ '_MCH'
MEMTOP          equ $436
_asm_get_machine_type:
                movem.l d1-d7/a0-a6, -(a7)
                moveq #0, d0
                move.l P_COOKIE, a0
                cmp.l #0, a0
                beq .no_cookies
.find_cookie:
                move.l (a0)+, d1
                move.l (a0)+, d0
                tst.l d1
                beq .no_cookies
                cmp.l #P_COOKIE_MCH, d1
                bne.s .find_cookie                
.no_cookies:
                movem.l (a7)+, d1-d7/a0-a6 
                rts

; Returns in D0.L the memory size in bytes.
; _memtop is in $436
; https://freemint.github.io/tos.hyp/en/bios_sysvars.html
_asm_get_memory_size:
                movem.l d1-d7/a0-a6, -(a7)
                move.l MEMTOP, d0
                movem.l (a7)+, d1-d7/a0-a6
                rts



                section bss
                XDEF    _font_small_ready:
                XDEF    _font_small_ptr
                XDEF    _screen
                XDEF    _picture
                XDEF    _asm_font_c23_source_f0
                XDEF    _asm_font_c23_source_f1
                XDEF    _asm_font_large_ready_f0
                XDEF    _asm_font_large_ready_f1
                XDEF    _asm_c23_logo_ready_f0
                XDEF    _asm_c23_logo_ready_f1

_font_small_ready:  ds.l 1
_font_small_ptr:    ds.l 1
_screen:            ds.l 1
_picture:           ds.l 1

NUMBER_OF_ROTATIONS         equ 1
FONT_SMALL_SIZE_WORDS       equ 32 / 2 ; 32 bytes in words
C23_LOGO_WORDS              equ (C23LOGO_WIDTH_BYTES * C23LOGO_HEIGHT_LINES) / 2 ; Words. Only 3 planes.
NUMBER_LARGE_FONTS          equ 48
NUMBER_SMALL_FONTS          equ 40

;_asm_font_large_ready_f0:   ds.w NUMBER_LARGE_FONTS * FONT_LARGE_SIZE_WORDS
;_asm_font_large_ready_f1:   ds.w NUMBER_LARGE_FONTS * FONT_LARGE_SIZE_WORDS
;_asm_c23_logo_ready_f0:     ds.w C23_LOGO_WORDS
;_asm_c23_logo_ready_f1:     ds.w C23_LOGO_WORDS

                section data align 2
_asm_font_small_ready:
                incbin "resources/FONT1616.BIN"
;_asm_font_c23_source_f0:
;                incbin "resources/fontc23_f0_p1.rbp"
;_asm_font_c23_source_f1:
;                incbin "resources/fontc23_f1_p1.rbp"

_asm_font_large_ready_f0:
                incbin "resources/F3225_P0.BIN"
_asm_font_large_ready_f1:
                incbin "resources/F3225_P1.BIN"
_asm_c23_logo_ready_f0:
                incbin "resources/C23LG_P0.BIN"
_asm_c23_logo_ready_f1:
                incbin "resources/C23LG_P1.BIN"

