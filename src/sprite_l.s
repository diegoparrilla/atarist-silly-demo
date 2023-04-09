                        include src/constants.s     ; Global constants. Start with '_'

; Big boss large sprite routine
; 320x59 pixels and 3 bit planes

    XDEF    _asm_display_big_sprite
    XDEF    _asm_init_big_sprite
    XDEF    _asm_clean_big_sprite
    XREF    _c23_logo_ready
    XREF    _asm_c23_logo_ready_f0
    XREF    _asm_c23_logo_ready_f1
    XREF    _screen_next
    XREF    _screen_pixel_offset
    XREF    _screen_dither_tiktok
    XREF    _current_screen_mask    ; Current we have to now the screen mask to know where to display and restore the sprite

BITPLANES               equ C23LOGO_PLANES              ; Number of bitplanes
SRC_WIDTH               equ C23LOGO_WIDTH_BYTES         ; Original width of the sprite in BYTES
SRC_HEIGHT              equ C23LOGO_HEIGHT_LINES        ; Original height of the sprite in lines
DST_WIDTH               equ (SRC_WIDTH/BITPLANES)*_SCREEN_BITPLANES                   ; Original width of the sprite in BYTES
DST_HEIGHT              equ SRC_HEIGHT                  ; Original height of the sprite in lines
BITS_PER_SKEW           equ 16                          ; Number of bits to shift per skew (16 bits per word)
SPRITE_SIZE_ORIGINAL    equ (SRC_WIDTH * SRC_HEIGHT)    ; Size of the original sprite in bytes
SPRITE_POSITION_Y       equ 0                           ; Y position of the sprite in the screen
SPRITE_POSITION         equ _SCREEN_WIDTH_BYTES * SPRITE_POSITION_Y + 8; Position of the sprite in the screen
CLEAN_BAR_HEIGHT        equ 6                           ; Height of the clean bar in lines  


                MACRO BLIT_MODE
                    or.b #F_LINE_BUSY,BLITTER_CONTROL_REG(a6)    ; << START THE BLITTER >>
.\@wait_blitter:
                    bset.b    #M_LINE_BUSY,BLITTER_CONTROL_REG(a6)       ; Restart BLiTTER and test the BUSY
                    nop                      ; flag state.  The "nop" is executed
                    bne.s  .\@wait_blitter     ; prior to the BLiTTER restarting.
                ENDM

                MACRO HOG_MODE
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                ENDM

_asm_clean_big_sprite:
                    moveq #2, d2 ; dest X increment. Jump 4 (2 + 2 + 2 + 2) planes.
                    move.w #(_SCREEN_WIDTH_BYTES - 6), d3 ; dest Y increment. Jump 4 (2 + 2 + 2 + 2) planes of empty places on the screen.
                    moveq #4, d4                ; We only delete the left and right columns of the sprite   
                    moveq #0, d5
                    move.w #200, d6 ; block Y count. This one must be reinitialized every bitplane

                    add.b _screen_pixel_offset, d5

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$0, BLITTER_HOP(a6) ; blitter HOP operation. Zeroing the destination.
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Zeroing the destination.
                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask2 register

                    move.l _screen_next, a1 ; a1 -> destination address
                    add.w #SPRITE_POSITION - 16, a1

                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    BLIT_MODE
                    rts


_asm_display_big_sprite:

; Calculate the start value of the memory address of X position for X=0
                    lea sprite_skew, a5            ; The travelling routine for the sprite X axis
                    move.w sprite_skew_pointer, d5
                    cmp.w sprite_table_size, d5
                    bne.s .increase_sprite_skew_pointer
                    moveq #0,d5                     ; reset the sprite X pointer
.increase_sprite_skew_pointer:
                    add.w d5,a5                     ; The address of the sprite skew
                    addq #2, d5
                    move.w d5, sprite_skew_pointer     ; Store the next value for the future

; save the background planes

                    moveq #(2 * BITPLANES), d0 ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    moveq #(2 * BITPLANES), d1 ; source Y increment. Jump 3 (2 + 2 + 2) planes.
                    moveq #(2 * _SCREEN_BITPLANES), d2 ; dest X increment. Jump 4 (2 + 2 + 2 + 2) planes.
                    moveq #(_SCREEN_WIDTH_BYTES - DST_WIDTH + 2 * _SCREEN_BITPLANES), d3 ; dest Y increment. Jump 4 (2 + 2 + 2 + 2) planes of empty places on the screen.
                    moveq #DST_WIDTH / (2 * _SCREEN_BITPLANES), d4 ; block X count. It seems don't need to reinitialize every bitplane.
;                    moveq #0, d5
;                    moveq #DST_HEIGHT, d6 ; block Y count. This one must be reinitialized every bitplane
;                    moveq #1, d6

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d0, SRC_X_INCREMENT(a6) 
                    move.w d1, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
;                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
;                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask3 register

;                    move.l _c23_logo_ready, a0 ; a0 -> source address
                    tst.w _screen_dither_tiktok
                    bne.s .dither_f1
                    lea _asm_c23_logo_ready_f0, a0
                    bra.s .dither_end
.dither_f1:         lea _asm_c23_logo_ready_f1, a0
.dither_end:
                    move.l _screen_next, a1 ; a1 -> destination address
;                    add.w #SPRITE_POSITION, a1

; Calculate the start value of the memory address of Y position
                    lea sprite_boing, a2            ; The travelling routine for the sprite X axis
                    move.w sprite_boing_pointer, d7
                    cmp.w sprite_boing_table_size, d7
                    bne.s .increase_sprite_boing_pointer
                    moveq #0,d7                     ; reset the sprite Y boing pointer
.increase_sprite_boing_pointer:
                    add.w d7,a2                     ; The address of the sprite boing
                    addq #2, d7
                    move.w d7, sprite_boing_pointer     ; Store the next value for the future
                    move.w (a2), d7
                    mulu #_SCREEN_WIDTH_BYTES, d7
                    addq #8, d7
                    add.l d7, a1

                    move.l a1, a2

                    subq #8, a1

                    move.w #(_SCREEN_WIDTH_BYTES - _SCREEN_WIDTH_NO_L_OFFSET_BYTES + 2 * _SCREEN_BITPLANES), DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w #20, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$0, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE


                    add.l #_SCREEN_WIDTH_BYTES * (CLEAN_BAR_HEIGHT) - (2 * 2), a1 ; Next line dest          

                    REPT DST_HEIGHT -1 ;
                    move.w (REPTN * 2 , a5), d5

                    and.b #%10001111,d5
                    add.b _screen_pixel_offset, d5
                    move.w d5, d6
                    and.w #%0000000000010000,d6
                    lsr.w #1, d6
                    add.w d6, a1

                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$3, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #1, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE

                    addq.w #2, a1               ; Next bitplane dest
                    addq.w #2, a0               ; Next bitplane src
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #1, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE

                    addq.w #2, a1               ; Next bitplane dest
                    addq.w #2, a0               ; Next bitplane src
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #1, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE

                    sub.w d6, a1

                    add.w #(SRC_WIDTH - (BITPLANES * 2) + 2), a0
                    add.w #(_SCREEN_WIDTH_BYTES - (BITPLANES * 2) + 2), a1
                    ENDR

                    move.w #(_SCREEN_WIDTH_BYTES - _SCREEN_WIDTH_NO_L_OFFSET_BYTES + 2 * _SCREEN_BITPLANES), DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w #20, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$0, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE
                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w #CLEAN_BAR_HEIGHT, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    HOG_MODE

                    rts


                section data
test_loop: dc.w 0
                include src/sprite_l.inc    ; The scroller trigonometric tables
                include src/sprite_b.inc    ; The scroller trigonometric tables

sprite_skew_pointer: dc.w 0  ; Current pointer to the sprite_skew_pointer table. Even words
sprite_boing_pointer: dc.w 0  ; Current pointer to the sprite_boing_pointer table. Even words
