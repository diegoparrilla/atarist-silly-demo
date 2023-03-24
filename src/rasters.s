
                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_setup_vblank
    XDEF    _asm_vbl_counter
    XDEF    _raster_y_pos_start
    XREF    _asm_palette
    XREF    _asm_palette_red_devil
    XREF    _asm_palette_dithered
    XREF    _screen_next
    XREF    _screen_absolute_offset
    XREF    _screen_pixel_offset

                ; Rasters section
TIMERB_COUNT_EVERY_SCAN_LINE    EQU 2
TIMERB_EVENT_COUNT              EQU 8
TILE_COLOR_PALETTE              EQU 64             ; 32 word colors per tile
COLOR_ITEM_PALETTE_SIZE         EQU 2              ; 2 bytes (1 word) per color
SCREEN_RASTER_LINES             EQU 192            ; 192 scan lines per screen

                section code

_asm_setup_vblank:
                moveq #0, d0
                move.w d0,  _asm_vbl_counter         ; clear the vbl counter before starting vblank   
                move.w d0, rotate_raster             ; init the rotate raster
                move.l d0, _raster_y_pos_start       ; init the raster y position for the scroller
                move.w d0, _raster_y_pos_start + 4   ; init the raster y position for the scroller
                lea vblank_routine, a1          ; get the address of the vblank routine
                lea timer_b_routine, a2         ; get the address of the timer b routine
                rts

vblank_routine:
                movem.l d0-d2, -(a7)                ; save the registers
; IMPORTANT: _screen_next is visible AFTER the vblank interrupt
; To understand why this is important, please read the articule here:
; http://alive.atari.org/alive12/ste_hwsc.php
; TL;DR: The STE hardware needs to set the VIDEO ADDRESS COUNTERS
; after setting the new screen address and the base line and pixel offsets.
                move.l  _screen_next, d0
                move.w  d0, d2              
                lsr.l   #8, d0
                move.b d0, d1    
                lsr.w   #8, d0
                move.b  d0, VIDEO_BASE_ADDR_HIGH.w           ; put in high screen address byte   
                move.b  d1, VIDEO_BASE_ADDR_MID.w           ; put in mid screen address byte
                move.b  d2, VIDEO_BASE_ADDR_LOW.w           ; put in low screen address byte (STe only)  

                move.b _screen_absolute_offset,VIDEO_BASE_LINE_OFFSET.w
                move.b _screen_pixel_offset, VIDEO_BASE_PIXEL_OFFSET.w

                move.b  d0,$FFFF8205.w  ;High Byte
                move.b  d1,$FFFF8207.w  ;Mid Byte
                move.b  d2,$FFFF8209.w  ;Low Byte
; The screen registers to do hardware scrolling ends here!
; Immediately after returning from the vblank interrupt, the code
; should rotate the _screen_visible and _screen_next pointers to 
; use _screen_next as the new pointer to the hidden screen buffer.

                addq #1, _asm_vbl_counter                           ; set the vbl counter when the vblank starts   
                move.w #2, line_counter                                 ; clear the line counter before starting vblank

                move.w rotate_raster, d0
                and.w #(TILE_COLOR_PALETTE * 2) - 1, d0               ; get the next color word
                move.w gradient(pc, d0), d1
                move.w d1, $ffff824E.w            ; extract the color from indexed table
                move.w d1, $ffff825E.w            ; extract the color from indexed table

                addq #2, d0                              ; increment the raster
                move.w d0, rotate_raster

                movem.l (a7)+, d0-d2                ; restore the registers
                rte

                ;Start up Timer B each VBL
;                move.w	#$2700,sr			                        ;Stop all interrupts
;                clr.b	$fffffa1b.w			                        ;Timer B control (stop)
;                bset	#0,$fffffa07.w			                    ;turn on timer b in enable a
;                bset	#0,$fffffa13.w			                    ;turn on timer b in mask a
;                move.b	#TIMERB_COUNT_EVERY_SCAN_LINE,$fffffa21.w   ;Timer B data (number of scanlines to next interrupt)
;                bclr	#3,$fffffa17.w			                    ;Automatic end of interrupt
;                move.b	#TIMERB_EVENT_COUNT,$fffffa1b.w			    ;Timer B control (event mode (HBL))
;                move.w	#$2300,sr			                        ;Interrupts back on
;                rte

gradient:
                dc.w $444
                dc.w $ccc
                dc.w $555
                dc.w $ddd
                dc.w $666
                dc.w $eee
                dc.w $777
                dc.w $fff
                dc.w $fff
                dc.w $777
                dc.w $eee
                dc.w $666
                dc.w $ddd
                dc.w $555
                dc.w $ccc
                dc.w $444

                dc.w $404
                dc.w $c0c
                dc.w $505
                dc.w $d0d
                dc.w $606
                dc.w $e0e
                dc.w $707
                dc.w $f0f
                dc.w $f0f
                dc.w $707
                dc.w $e0e
                dc.w $606
                dc.w $d0d
                dc.w $505
                dc.w $c0c
                dc.w $404

                dc.w $440
                dc.w $cc0
                dc.w $550
                dc.w $dd0
                dc.w $660
                dc.w $ee0
                dc.w $770
                dc.w $ff0
                dc.w $ff0
                dc.w $770
                dc.w $ee0
                dc.w $660
                dc.w $dd0
                dc.w $550
                dc.w $cc0
                dc.w $440

                dc.w $044
                dc.w $0cc
                dc.w $055
                dc.w $0dd
                dc.w $066
                dc.w $0ee
                dc.w $077
                dc.w $0ff
                dc.w $0ff
                dc.w $077
                dc.w $0ee
                dc.w $066
                dc.w $0dd
                dc.w $055
                dc.w $0cc
                dc.w $044

            


; Using short reference to the palette with PC relative addressing
timer_b_routine:
                rte
                move.w d0, -(a7)
                move.w line_counter, d0                               ; get the current scan line
                cmp.w _raster_y_pos_start + 4, d0                         ; compare the current scan line with the raster y position
                bge.s .change_palette
.skip_change_palette:
                move.w _asm_palette_dithered + 0, $ffff8240.w	; Set the palette every vblank
                move.w _asm_palette_dithered + 16, $ffff8250.w

                addq.w #COLOR_ITEM_PALETTE_SIZE, line_counter         ; increment the line counter by a word
                move.w (a7)+, d0
                rte
.change_palette:
                cmp.w _raster_y_pos_end + 4, d0
                bgt.s .skip_change_palette
                add.w rotate_raster, d0
                and.w #(TILE_COLOR_PALETTE * 2) - 1, d0               ; get the next color word
                move.w rainbow_colors(pc, d0), d0
;                moveq #0, d0
                move.w d0, $ffff8240.w            ; extract the color from indexed table
                move.w d0, $ffff8250.w            ; extract the color from indexed table

                addq.w #COLOR_ITEM_PALETTE_SIZE, line_counter         ; increment the line counter by a word
                move.w (a7)+, d0
                rte

;                section data align 2
rainbow_colors: 
                dc.w $0700     ; red
                dc.w $0600     ; 
                dc.w $0500     ;
                dc.w $0400     ;
                dc.w $0300     ; 
                dc.w $0750     ; orange
                dc.w $0640     ;
                dc.w $0530     ;
                dc.w $0420     ;
                dc.w $0310     ;
                dc.w $0770     ; yellow
                dc.w $0660     ;
                dc.w $0550     ;
                dc.w $0440     ;
                dc.w $0330     ;
                dc.w $0070     ; green
                dc.w $0060     ;
                dc.w $0050     ;
                dc.w $0040     ;
                dc.w $0030     ;
                dc.w $0007     ; blue
                dc.w $0006     ;
                dc.w $0005     ;
                dc.w $0004     ;
                dc.w $0003     ;
                dc.w $0305     ; indigo
                dc.w $0204     ;
                dc.w $0103     ;
                dc.w $0002     ;
                dc.w $0001     ;
                dc.w $0406     ; violet
                dc.w $0305     ;
                dc.w $0204     ;
                dc.w $0103     ;
; Does not fit...
                dc.w $0002     ;
atari_letters: 
                dc.w $0777     ; white
                dc.w $0666     ; white
                dc.w $0555     ; white
                dc.w $0444     ; white



                section bss
line_counter:       ds.w 1
rotate_raster:      ds.w 1
_asm_vbl_counter    ds.w 1
_raster_y_pos_start ds.w 1
_raster_y_pos_end   ds.w 1
                    ds.l 1
