    XDEF	_asm_main_loop
    XDEF    _screen_last
    XDEF    _screen_next
    XDEF    _screen_base
    XDEF    _BUFFER_NUMBERS
    XREF    _asm_save_state
    XREF    _asm_restore_state
    XREF    _asm_column_rotate
    XREF    _asm_vbl_counter
    XREF    _asm_print_str
    XREF    _asm_draw_tiles
    XREF    _asm_setup_vblank
    XREF    _scroll_type

                ; Scrolling section

                section code
_BUFFER_NUMBERS   equ     16          ; number of buffers to use. Only power of 2 allowed (2, 4, 8, 16...)
SCREEN_SIZE      equ     32000

rotate_screens:
                move.w current_screen_mask, d0
                move.l #_screen_base, d1
                move.l #_screen_base + SCREEN_SIZE, d2
                move.w d0, d3           ; calculate the screen address of the next buffers
                tst.w d0
                beq.s increment_buffer
                subq #1, d3
calculate_buffer:
                add.l #SCREEN_SIZE, d1
                add.l #SCREEN_SIZE, d2
                dbf d3, calculate_buffer

increment_buffer:
                addq.w #1, d0
                and.w #_BUFFER_NUMBERS-1,d0
                tst.w d0
                bne.s save_screen_addr
                move.l #_screen_base, d2    ; if the buffer restart, use the first buffer for the next screen

save_screen_addr:
                move.w d0, current_screen_mask
                clr.b d1    ; put on 256 byte boundary  
                clr.b d2    ; put on 256 byte boundary  
                move.l d1, _screen_last
                move.l d2, _screen_next
                rts

_asm_main_loop:
                movem.l d0-d7/a0-a6, -(a7)

                bsr.s rotate_screens            ; rotate the screen buffers for the first time
                move.w #$0, _scroll_type        ; default large text scrolling type
                bsr print_scroll_8_byte_copy    ; print the scrolling type

                jsr _asm_draw_tiles             ; draw the tiles on the buffers

                ; The setup_vblank only clear the initial raster and returns
                ; the addresses of the vblank and timer B (HBL) routines in a1 and a2
                ; respectively. The save_state routine saves the current state of the
                ; ST and the restore_state routine restores it. It expects the 
                ; addresses of the vblank and timer B routines in a1 and a2 respectively.
                bsr _asm_setup_vblank
                bsr _asm_save_state

                move.l  _screen_last, d0        ; set the next screen address
                clr.b   $ffff820d               ; clear STe extra bit  
                lsr.l   #8, d0    
                move.b  d0, $ffff8203           ; put in mid screen address byte
                lsr.w   #8, d0
                move.b  d0, $ffff8201           ; put in high screen address byte


main_loop:
            	tst.w	_asm_vbl_counter    ; Wait for the VBL
		        beq.s	main_loop           ; YOU NOT SHALL PASS!!! ...until the VBL changes the state
		        clr.w	_asm_vbl_counter    ; Clear the VBL counter

                move.l  _screen_next, d0
              
                clr.b   $ffff820d               ; clear STe extra bit  
                lsr.l   #8, d0    
                move.b  d0, $ffff8203           ; put in mid screen address byte
                lsr.w   #8, d0
                move.b  d0, $ffff8201           ; put in high screen address byte
              
                move.w  #700, $ff8240

                bsr _asm_column_rotate

                bsr rotate_screens        ; rotate the screens

                move.w  #$000, $ff8240

                ; Test keys
                cmp.b    #$02, $fffc02            ; Key 1 pressed?
                bne.b    check_key2               ; Check next key
                move.w #$0, _scroll_type
                bsr.b print_scroll_8_byte_copy

check_key2:
                cmp.b    #$03, $fffc02            ; Key 2 pressed?
                bne.b    check_key3              ; Check next key
                move.w #$1, _scroll_type
                bsr.s print_scroll_8_movep_copy

check_key3:
                cmp.b    #$04, $fffc02            ; Key 2 pressed?
                bne.b    check_escape              ; Check next key
                move.w #$2, _scroll_type
                bsr.s print_scroll_8_blitter_copy

check_escape:
                cmp.b    #$01, $fffc02            ; ESC pressed?
                bne      main_loop                ; if not, repeat main                

                bsr _asm_restore_state

                movem.l (a7)+, d0-d7/a0-a6
                rts

;   Print the string informing of scrolling byte copy mode
print_scroll_8_byte_copy:
                lea print_scroll_8_byte_str, a0  ; The ASCII text to print
                bsr.s print_all_buffers
                rts

;   Print the string informing of scrolling movep copy mode
print_scroll_8_movep_copy:
                lea print_scroll_8_movep_str, a0  ; The ASCII text to print
                bsr.s print_all_buffers
                rts

;   Print the string informing of scrolling blitter copy mode
print_scroll_8_blitter_copy:
                lea print_scroll_8_blitter_str, a0  ; The ASCII text to print
                bsr.s print_all_buffers
                rts

; Print over all the existing buffers
;  a0 = Address with the string to print
print_all_buffers:
                movem.l d0-d1/a3, -(a7)
                move.w #_BUFFER_NUMBERS - 1, d0
                move.l #_screen_base, d1
                clr.b d1
                move.l d1, a3
                lea (175*160,a3), a3      ; The bottom of the screen
print_next_buffer:
                bsr _asm_print_str
                lea (SCREEN_SIZE,a3), a3
                dbf d0, print_next_buffer
                movem.l (a7)+, d0-d1/a3

                rts

                section bss
                ds.b    256
_screen_base:   ds.b    _BUFFER_NUMBERS * SCREEN_SIZE


                section data
current_screen_mask     dc.w   0
_screen_next            dc.l   0
_screen_last            dc.l   0

print_scroll_8_byte_str: dc.b   'BYTE COPY',0
print_scroll_8_movep_str: dc.b  'MOVEP    ',0
print_scroll_8_blitter_str: dc.b  'BLITTER  ',0
