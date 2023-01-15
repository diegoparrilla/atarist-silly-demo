    XDEF    _asm_setup_vblank
    XDEF    _asm_vbl_counter

                ; Rasters section
TIMERB_COUNT_EVERY_SCAN_LINE    EQU 1
TIMERB_EVENT_COUNT              EQU 8
TILE_COLOR_PALETTE              EQU 32             ; 32 word colors per tile
COLOR_ITEM_PALETTE_SIZE         EQU 2              ; 2 bytes (1 word) per color

                section code

_asm_setup_vblank:
                clr.w  _asm_vbl_counter         ; clear the vbl counter before starting vblank   
                clr.w rotate_raster             ; init the rotate raster
                lea vblank_routine, a1          ; get the address of the vblank routine
                lea timer_b_routine, a2         ; get the address of the timer b routine
                rts

vblank_routine:
                addq.w #1,  _asm_vbl_counter                        ; set the vbl counter when the vblank starts   
                clr.w  line_counter                                 ; clear the line counter before starting vblank
                addq #2, rotate_raster                              ; increment the raster
                and.w #(TILE_COLOR_PALETTE * 2) - 1, rotate_raster

                ;Start up Timer B each VBL
                move.w	#$2700,sr			                        ;Stop all interrupts
                clr.b	$fffffa1b.w			                        ;Timer B control (stop)
                bset	#0,$fffffa07.w			                    ;turn on timer b in enable a
                bset	#0,$fffffa13.w			                    ;turn on timer b in mask a
                move.b	#TIMERB_COUNT_EVERY_SCAN_LINE,$fffffa21.w   ;Timer B data (number of scanlines to next interrupt)
                bclr	#3,$fffffa17.w			                    ;Automatic end of interrupt
                move.b	#TIMERB_EVENT_COUNT,$fffffa1b.w			    ;Timer B control (event mode (HBL))
                move.w	#$2300,sr			                        ;Interrupts back on
                rte

timer_b_routine:
                movem.l d0-d1/a0, -(a7)
                move.w line_counter, d0          ; get the current scan line
                and.w #(TILE_COLOR_PALETTE * 2) - 1, d0                     ; get the current color
                lea rainbow_colors,a0
                move.w rotate_raster, d1
                sub.w d0, d1
                and.w #(TILE_COLOR_PALETTE * 2) - 1, d1
                add.w d1, a0                     ; get the next color word
                move.w (a0), $ff8250             ; set the color
                addq.w #COLOR_ITEM_PALETTE_SIZE, d0                    ; increment the line counter by a word
                move d0, line_counter
                movem.l (a7)+, d0-d1/a0
                rte

                section bss
line_counter:       ds.w 1
rotate_raster:      ds.w 1
_asm_vbl_counter    ds.w 1

                section data align 2
rainbow_colors: 
                dc.w $0700     ; red
                dc.w $0600     ; 
                dc.w $0500     ;
                dc.w $0400     ; 
                dc.w $0750     ; orange
                dc.w $0640     ;
                dc.w $0530     ;
                dc.w $0420     ;
                dc.w $0770     ; yellow
                dc.w $0660     ;
                dc.w $0550     ;
                dc.w $0440     ;
                dc.w $0070     ; green
                dc.w $0060     ;
                dc.w $0050     ;
                dc.w $0040     ;
                dc.w $0007     ; blue
                dc.w $0006     ;
                dc.w $0005     ;
                dc.w $0004     ;
                dc.w $0305     ; indigo
                dc.w $0204     ;
                dc.w $0103     ;
                dc.w $0002     ;
                dc.w $0406     ; violet
                dc.w $0305     ;
                dc.w $0204     ;
                dc.w $0103     ;
atari_letters: 
                dc.w $0777     ; white
                dc.w $0666     ; white
                dc.w $0555     ; white
                dc.w $0444     ; white

                end

