
                        include src/constants.s     ; Global constants. Start with '_'

    XDEF	_asm_main_loop
    XDEF    _screen_visible
    XDEF    _screen_next
    XDEF    _screen_base_ptr
    XDEF    _current_screen_mask
    XDEF    _screen_pixel_offset
    XDEF    _screen_absolute_offset
    XDEF    _screen_dither_tiktok
    XREF    _asm_init_nativefeatures
    XREF    _asm_get_memory_size
    XREF    _asm_save_state
    XREF    _asm_restore_state
    XREF    _asm_vbl_counter
    XREF    _asm_print_small_str
    XREF    _asm_init_tiles
    XREF    _asm_draw_tiles
    XREF    _asm_draw_uridium
    XREF    _asm_setup_vblank
    XREF	_asm_cook_small_sprites
    XREF    _asm_restore_all_sprites
    XREF    _asm_show_all_sprites
    XREF    _asm_scroll_init
    XREF    _asm_scroll_rotate
    XREF    _asm_display_big_sprite
    XREF    _asm_clean_big_sprite

    XREF    _asm_textroll_init
    XREF    _asm_show_textroll_bar
    XREF    _asm_restore_textroll_bar

    XREF   tuneinit
    XREF   tunedeinit
    XREF   tuneinter


TEXT_INFO_POSITION          equ 184         ; 200 lines - 16 pixels height
TEXT_INFO_PLANE             equ 0           ; 0 = plane A, 1 = plane B; 2 = plane C, 3 = plane D
                ; Scrolling section

                section code
rotate_screens:
; First, do tik-tok dithering
                eor.w #1, _screen_dither_tiktok

; Increment the current screen pixel offset
                moveq.l #0, d0
                move.b _screen_pixel_offset, d0
                addq.b #_SCROLL_BACKGROUND_SPEED, d0
                and.b #15, d0
                move.b d0, _screen_pixel_offset

; Calculate the sliding offset in words depending on the pixel offset
; if the pixel offset is 0, the offset is the full offset
; if not, substract fourd words (a full 16 pixel 4 planes)
                move.b #_SCREEN_L_OFFSET_WORDS, d1
                tst.w d0
                beq .logical_rotation
.no_skew_fix_line_offset:
                subq.b #4, d1
.logical_rotation:
                move.b d1, _screen_absolute_offset

; Update the current screen mask depending on the number of buffers
                and.w #_BUFFER_NUMBERS-1,d0
                move.w d0, _current_screen_mask
                add.w d0,d0
                add.w d0,d0
                move.w d0,d1
                addq #4, d1
                and.w #(_BUFFER_NUMBERS*4)-1,d1
; d0 and d1 are the two screen buffer indexes (next and visible)

; Calculate the new screen buffer addresses and update the screen pointers
; for the infinite horizontal scrolling. Only increment the full four planes
; when the pixel offset is 0.
                lea screen_buffer_index, a0
                move.l (a0, d0.w), d0
                move.l (a0, d1.w), d1
                move.l _screen_sliding_buffer, d4
                tst.b _screen_pixel_offset
                bne.s .no_increment_rolling_buffer
                addq.l #8, d4
                move.l d4, _screen_sliding_buffer
.no_increment_rolling_buffer:
                move.l _screen_base_ptr, a0
                add.l a0, d0
                add.l a0, d1
                add.l d4, d0
                add.l d4, d1
                move.l d0, _screen_visible             ; IMPORTANT: _screen_visible is the _current_screen_mask value
                move.l d1, _screen_next             ; IMPORTANT: _screen_next is the next _current_screen_mask valu
                rts                                 

_asm_main_loop:
                movem.l d0-d7/a0-a6, -(a7)

                IIF _DEBUG jsr _asm_init_nativefeatures

; Initiliaze memory
                jsr _asm_get_memory_size
                sub.l #_SCREEN_SIZE * (_BUFFER_NUMBERS + 1), d0
                move.l d0, _screen_base_ptr

; Initialize the first two buffered screens
                clr.w _current_screen_mask                          ; set the current screen mask to 0s

                move.w #_SCROLL_BACKGROUND_START, _screen_pixel_offset

                move.l _screen_base_ptr, a0
                move.l  #_SCREEN_SIZE * (_BUFFER_NUMBERS + 1) / (4 * 8), d0 ; Clean all the screens
                move.l d0, d1
                mulu #(4 * 8), d1
                add.l d1, a0
                moveq #0, d1                     ; clear with 0
                moveq #0, d2                     ; clear with 0
                moveq #0, d3                     ; clear with 0
                moveq #0, d4                     ; clear with 0
                moveq #0, d5                     ; clear with 0
                moveq #0, d6                     ; clear with 0
                moveq #0, d7                     ; clear with 0
                move.l d1, a1                    ; clear with 0
clean_screen_loop:
                movem.l  d1-d7/a1, -(a0)             ; move one longword to screen
                dbf     d0, clean_screen_loop

                jsr _asm_cook_small_sprites     ; cook the small sprites

                jsr _asm_scroll_init            ; Init scroll variables

                bsr tuneinit    ; Init the music

                jsr _asm_init_tiles             ; Init tiles

                jsr _asm_textroll_init              ; Init text roll

                ; The setup_vblank only clear the initial raster and returns
                ; the addresses of the vblank and timer B (HBL) routines in a1 and a2
                ; respectively. The save_state routine saves the current state of the
                ; ST and the restore_state routine restores it. It expects the 
                ; addresses of the vblank and timer B routines in a1 and a2 respectively.
                bsr _asm_setup_vblank
                bsr _asm_save_state             ; save the current state of the interrupts and screen

main_loop:

change_screen_buffers:
;
; When entering here, _screen_next should be last hidden buffer. The VBL interrupt will change it to the visible buffer
;
            	tst.w	_asm_vbl_counter    ; Wait for the VBL
		        beq.s	main_loop           ; YOU SHALL NOT PASS!!! ...until the VBL changes the state
		        clr.w	_asm_vbl_counter    ; Clear the VBL counter

; WARNING: the screen_next is visible now. So we need to rotate the screen buffers before drawing anything
                bsr rotate_screens              ; rotate the screen buffers. YOU SHOULD SAFELY DRAW NOW AFTER THIS POINT

                tst.w exit_program
                bne exit

                bsr tuneinter               ; play the music

                IIF _DEBUG move.w  #$000, $ff8240
;
; All the drawing coding should START here
;

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                jsr _asm_restore_textroll_bar       ; restore the text roll bar

                jsr _asm_restore_all_sprites        ; restore all sprites

; The screen scroll should be done when all the sprites are restored
                jsr _asm_draw_uridium
; After the screen scroll, it's time to draw all the sprites

                jsr _asm_display_big_sprite         ; display the big sprite

                jsr _asm_show_all_sprites           ; show all sprites

                jsr _asm_show_textroll_bar
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;
; All the drawing coding should END here
;
                IIF _DEBUG move.w  #$500, $ff8240
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
                bne      main_loop    ; if not, repeat main
                move.w #1, exit_program
                bra main_loop                

exit:
                bsr tunedeinit  ; Deinit the music
                bsr _asm_restore_state

                movem.l (a7)+, d0-d7/a0-a6
                rts

                section data
_screen_base_ptr        dc.l   0
screen_buffer_index     
                        REPT   _BUFFER_NUMBERS
                        dc.l   REPTN * _SCREEN_SIZE
                        ENDR
_current_screen_mask    dc.w   0
_screen_dither_tiktok   dc.w   0
_screen_next            dc.l   0
_screen_visible         dc.l   0
_screen_pixel_offset    dc.b   0
                        dc.b   0                      ; padding
_screen_absolute_offset dc.b   0
                        dc.b   0                      ; padding
_screen_sliding_buffer  dc.l   0                      ; the sliding buffer for the horizontal scroll. Should be reinitailied on each restart
_sprite_x               dc.w   8
_sprite_y               dc.w   8
_sprite_text_x          dc.w   8
_sprite_text_y          dc.w   8
skew                    dc.w   15
exit_program            dc.w   0    

print_scroll_8_byte_str: dc.b   'BYTE COPY',0
print_scroll_8_movep_str: dc.b  'MOVEP    ',0
print_scroll_8_blitter_str: dc.b  'BLITTER  ',0
print_debug_text_str: dc.b   'THIS IS A DEBUG TEST',0

                section bss align 2

