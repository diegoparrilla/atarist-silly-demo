
                        include src/constants.s     ; Global constants. Start with '_'

    XDEF	_asm_main_loop
    XDEF    _screen_visible
    XDEF    _screen_next
    XDEF    _screen_last
    XDEF    _screen_base
    XDEF    _current_screen_mask
    XREF    _asm_save_state
    XREF    _asm_restore_state
    XREF    _asm_vbl_counter
    XREF    _asm_print_small_str
    XREF    _asm_draw_tiles
    XREF    _asm_setup_vblank
    XREF	_asm_cook_small_sprites
    XREF    _asm_restore_all_sprites
    XREF    _asm_show_all_sprites
    XREF    _asm_scroll_init
    XREF    _asm_scroll_rotate
    XREF    _asm_restore_background_scroll
    XREF    _asm_music_ym_init
    XREF    _asm_music_ym_play
    XREF    _asm_music_ym_exit
    XREF    _asm_display_big_sprite
    XREF    _asm_clean_big_sprite



TEXT_INFO_POSITION  equ     184         ; 200 lines - 16 pixels height
TEXT_INFO_PLANE     equ     0           ; 0 = plane A, 1 = plane B; 2 = plane C, 3 = plane D

                ; Scrolling section

                section code
rotate_screens:
                move.w _current_screen_mask, d0
                addq #1, d0
                and.w #_BUFFER_NUMBERS-1,d0
                move.w d0, _current_screen_mask
                add.w d0,d0
                add.w d0,d0
                move.w d0,d1
                addq #4, d1
                and.w #(_BUFFER_NUMBERS*4)-1,d1
                lea screen_buffer_index, a0
                move.l (a0, d0.w), d0
                move.l (a0, d1.w), d1
                move.l #_screen_base, a0
                add.l a0, d0
                add.l a0, d1
                clr.b d0                            ; put on 256 byte boundary  
                clr.b d1                            ; put on 256 byte boundary  
                move.l d0, _screen_visible             ; IMPORTANT: _screen_visible is the _current_screen_mask value
                move.l d1, _screen_next             ; IMPORTANT: _screen_next is the next _current_screen_mask value
                rts                                 

_asm_main_loop:
                movem.l d0-d7/a0-a6, -(a7)

; Initialize the first two buffered screens
                clr.w _current_screen_mask                          ; set the current screen mask to 0s

                lea _screen_base, a0
                move.l  #((_SCREEN_SIZE * _BUFFER_NUMBERS)/4)-1, d0 ; Clean all the screens
                moveq #0, d1                     ; clear with 0
clean_screen_loop:
                move.l  d1, (a0)+             ; move one longword to screen
                dbf     d0, clean_screen_loop

                jsr _asm_cook_small_sprites     ; cook the small sprites

                jsr _asm_draw_tiles             ; draw the tiles on the buffers

                jsr _asm_scroll_init            ; Init scroll variables

                jsr _asm_music_ym_init          ; Init YM music

                ; The setup_vblank only clear the initial raster and returns
                ; the addresses of the vblank and timer B (HBL) routines in a1 and a2
                ; respectively. The save_state routine saves the current state of the
                ; ST and the restore_state routine restores it. It expects the 
                ; addresses of the vblank and timer B routines in a1 and a2 respectively.
                bsr _asm_setup_vblank
                bsr _asm_save_state             ; save the current state of the interrupts and screen

change_screen_buffers:
; Set the next screen address to be displayed BEFORE THE VERTICAL BLANK HAPPENS
; IMPORTANT: _screen_next is visible AFTER the vblank interrupt
                move.l  _screen_next, d0              
                clr.b   $ffff820d               ; clear STe extra bit  
                lsr.l   #8, d0    
                move.b  d0, $ffff8203           ; put in mid screen address byte
                lsr.w   #8, d0
                move.b  d0, $ffff8201           ; put in high screen address byte   

; WARNING: the screen_next is visible now. So we need to rotate the screen buffers before drawing anything
                move.l _screen_visible, _screen_last
                bsr rotate_screens              ; rotate the screen buffers. YOU SHOULD SAFELY DRAW NOW AFTER THIS POINT
; after this routine, the screen_next is the next in the buffer and not displayed
; IMPORTANT: _screen_visible is the _current_screen_mask value
; IMPORTANT: _screen_next is the next _current_screen_mask value
; IMPORTANT: _screen_next NOW IS HIDDEN 
; IMPORTANT: so immediately after the vblank interrupt, the screen should rotate with this routine

main_loop:
;
; When entering here, _screen_next should be last hidden buffer. The VBL interrupt will change it to the visible buffer
;
            	tst.w	_asm_vbl_counter    ; Wait for the VBL
		        beq.s	main_loop           ; YOU NOT SHALL PASS!!! ...until the VBL changes the state
		        clr.w	_asm_vbl_counter    ; Clear the VBL counter

                tst.w exit_program
                bne exit

                jsr _asm_music_ym_play

                IIF _DEBUG move.w  #$002, $ff8240
;
; All the drawing coding should START here
;

                jsr _asm_restore_all_sprites        ; restore all sprites

;                jsr _asm_clean_big_sprite           ; clean the big sprite

                bsr _asm_restore_background_scroll  ; restore the background scroll


                bsr _asm_scroll_rotate              ; rotate the large scroll text

                jsr _asm_display_big_sprite         ; display the big sprite

                jsr _asm_show_all_sprites           ; show all sprites

;
; All the drawing coding should END here
;
                IIF _DEBUG move.w  #0, $ff8240
; Test keys
                cmp.b #$0A, $fffc02
                bne.s check_key0
                cmp.w #$F, skew
                beq.s check_key0
                addq #1, skew

check_key0:
                cmp.b    #$0B, $fffc02            ; Key 0 pressed?
                bne.b    check_escape               ; Check next key
                cmp.w #$0, skew
                beq.s check_escape
                subq #1, skew                   ; decrease the skew

check_escape:
                cmp.b    #$01, $fffc02            ; ESC pressed?
                bne      change_screen_buffers    ; if not, repeat main
                move.w #1, exit_program
                bra change_screen_buffers                

exit:
                jsr _asm_music_ym_exit
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
                lea ((TEXT_INFO_PLANE * 2) + (TEXT_INFO_POSITION * _SCREEN_WIDTH_BYTES),a3), a3      ; The bottom of the screen
print_next_buffer:
                bsr _asm_print_small_str
                lea (_SCREEN_SIZE,a3), a3
                dbf d0, print_next_buffer
                movem.l (a7)+, d0-d1/a3

                rts

                section bss 
                ds.b    256
_screen_base:   ds.b    _BUFFER_NUMBERS * _SCREEN_SIZE


                section data
_current_screen_mask    dc.w   0
_screen_next            dc.l   0
_screen_visible         dc.l   0
_screen_last            dc.l   0
_sprite_x               dc.w   8
_sprite_y               dc.w   8
_sprite_text_x          dc.w   8
_sprite_text_y          dc.w   8
skew                    dc.w   15
exit_program            dc.w   0    

screen_buffer_index     
                        REPT   _BUFFER_NUMBERS
                        dc.l   REPTN * _SCREEN_SIZE
                        ENDR
    


print_scroll_8_byte_str: dc.b   'BYTE COPY',0
print_scroll_8_movep_str: dc.b  'MOVEP    ',0
print_scroll_8_blitter_str: dc.b  'BLITTER  ',0
