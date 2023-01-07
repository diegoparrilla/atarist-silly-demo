    XDEF	_asm_main_loop
    XDEF    _screen_last
    XDEF    _screen_next
    XREF    _asm_column_rotate
    XREF    _asm_print_str
    XREF    _scroll_type

                ; Scrolling section

                section code

_asm_main_loop:
                movem.l d0-d7/a0-a6, -(a7)

                move.l  #screen1, d0             ; put screen1 address in d0
                clr.b   d0                       ; put on 256 byte boundary  
                move.l  d0, _screen_next                 ; store address
                add.l   #32000, d0               ; next screen area
                move.l  d0, _screen_last                 ; store address

;                move.w  #7, -(a7)              ; wait for a keypress
;                trap    #1                     ; call gemdos
;                addq.l  #2, a7                 ; clear up stack
              
                move.w  #37, -(sp)               ; wait vbl
                trap    #14
                addq.l  #2, sp

                move.l  _screen_next, d0

                clr.b   $ffff820d               ; clear STe extra bit  
                lsr.l   #8, d0    
                move.b  d0, $ffff8203           ; put in mid screen address byte
                lsr.w   #8, d0
                move.b  d0, $ffff8201           ; put in high screen address byte

                move.w #$0, _scroll_type
                bsr print_scroll_8_byte_copy

main_loop:
                move.w  #37, -(sp)               ; wait vbl
                trap    #14
                addq.l  #2, sp

                move.l  _screen_next, d0
              
                clr.b   $ffff820d               ; clear STe extra bit  
                lsr.l   #8, d0    
                move.b  d0, $ffff8203           ; put in mid screen address byte
                lsr.w   #8, d0
                move.b  d0, $ffff8201           ; put in high screen address byte
              
                move.w  #$0, $ff8240

                bsr _asm_column_rotate

                move.l  _screen_last, a0
                move.l  _screen_next, a1                ; load screens
                move.l  a1, _screen_last                ; and flip them for next time around
                move.l  a0, _screen_next                ; double buffering

                move.w  #$545, $ff8240

;                move.w  #7, -(a7)              ; wait for a keypress
;                trap    #1                     ; call gemdos
;                addq.l  #2, a7                 ; clear up stack

                cmp.b    #$02, $fffc02            ; Key 1 pressed?
                bne.b    check_key2               ; Check next key
                move.w #$0, _scroll_type
                bsr.b print_scroll_8_byte_copy

check_key2:
                cmp.b    #$03, $fffc02            ; Key 2 pressed?
                bne.b    check_space              ; Check next key
                move.w #$1, _scroll_type
                bsr print_scroll_8_movep_copy

check_space:
                cmp.b    #$01, $fffc02            ; ESC pressed?
                bne.b      main_loop                ; if not, repeat main                

                movem.l (a7)+, d0-d7/a0-a6
                rts

;   Print the string informing of scrolling byte copy mode
print_scroll_8_byte_copy:
                lea print_scroll_8_byte_str, a0  ; The ASCII text to print
                move.l _screen_next, a3    ; The screen address
                lea (175*160,a3), a3      ; The bottom of the screen
                bsr _asm_print_str
 
                move.l _screen_last, a3    ; The screen address
                lea (175*160,a3), a3      ; The bottom of the screen
                bsr _asm_print_str

                rts

;   Print the string informing of scrolling movep copy mode
print_scroll_8_movep_copy:
                lea print_scroll_8_movep_str, a0  ; The ASCII text to print
                move.l _screen_next, a3    ; The screen address
                lea (175*160,a3), a3      ; The bottom of the screen
                bsr _asm_print_str
 
                move.l _screen_last, a3    ; The screen address
                lea (175*160,a3), a3      ; The bottom of the screen
                bsr _asm_print_str

                rts

                section bss
                ds.b    256
screen1         ds.b    32000
screen2         ds.b    32000

                section data
_screen_next            dc.l   0
_screen_last            dc.l   0

print_scroll_8_byte_str: dc.b   'BYTE COPY',0
print_scroll_8_movep_str: dc.b  'MOVEP    ',0
