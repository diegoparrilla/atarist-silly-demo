                        include src/constants.s     ; Global constants. Start with '_'

; Big boss large sprite routine
; 320x59 pixels and 3 bit planes

    XDEF    _asm_display_big_sprite
    XDEF    _asm_init_big_sprite
    XDEF    _asm_clean_big_sprite
    XREF    _c23_logo_ready
    XREF    _screen_next
    XREF    _current_screen_mask    ; Current we have to now the screen mask to know where to display and restore the sprite

BITPLANES               equ C23LOGO_PLANES              ; Number of bitplanes
SRC_WIDTH               equ C23LOGO_WIDTH_BYTES         ; Original width of the sprite in BYTES
SRC_HEIGHT              equ C23LOGO_HEIGHT_LINES        ; Original height of the sprite in lines
DST_WIDTH               equ (SRC_WIDTH/BITPLANES)*_SCREEN_BITPLANES                   ; Original width of the sprite in BYTES
DST_HEIGHT              equ SRC_HEIGHT                  ; Original height of the sprite in lines
BITS_PER_SKEW           equ 16                          ; Number of bits to shift per skew (16 bits per word)
SPRITE_SIZE_ORIGINAL    equ (SRC_WIDTH * SRC_HEIGHT)    ; Size of the original sprite in bytes
SPRITE_POSITION         equ _SCREEN_WIDTH_BYTES * 132 + 8 ; Position of the sprite in the screen

_asm_clean_big_sprite:
                    moveq #(2 * _SCREEN_BITPLANES), d2 ; dest X increment. Jump 4 (2 + 2 + 2 + 2) planes.
                    move.w #(_SCREEN_WIDTH_BYTES - _SCREEN_BITPLANES * 2), d3 ; dest Y increment. Jump 4 (2 + 2 + 2 + 2) planes of empty places on the screen.
                    moveq #2, d4                ; We only delete the left and right columns of the sprite   
                    moveq #0, d5
                    moveq #DST_HEIGHT, d6 ; block Y count. This one must be reinitialized every bitplane

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Zeroing the destination.
                    move.b d5, BLITTER_OPERATION(a6) ; blitter operation. Zeroing the destination.
                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask2 register

                    move.l _screen_next, a1 ; a1 -> destination address
                    add.w #SPRITE_POSITION, a1

                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    add.w #124, a1

                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                    rts

_asm_display_big_sprite:

; Calculate the start value of the memory address of X position for X=0
                    lea sprite_skew, a5            ; The travelling routine for the sprite X axis
                    move.w sprite_skew_pointer, d5
                    cmp.w sprite_table_size, d5
                    bne.s .increase_sprite_skew_pointer
                    moveq #0,d5                     ; reset the sprite X pointer
.increase_sprite_skew_pointer:
                    add.w d5,a5                     ; The address of the sprite Y skew
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
                    moveq #1, d6

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d0, SRC_X_INCREMENT(a6) 
                    move.w d1, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$3, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFE, ENDMASK3_REG(a6) ; endmask3 register

                    move.l _c23_logo_ready, a0 ; a0 -> source address
                    move.l _screen_next, a1 ; a1 -> destination address
                    add.w #SPRITE_POSITION, a1

                    REPT DST_HEIGHT
                    move.w (REPTN * 2 , a5), d5

                    and.b #%10001111,d5
                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    addq.w #2, a0               ; Next bitplane src
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    addq.w #2, a1               ; Next bitplane dest
                    addq.w #2, a0               ; Next bitplane src
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    add.w #(SRC_WIDTH - (BITPLANES * 2) + 2), a0
                    add.w #(_SCREEN_WIDTH_BYTES - (BITPLANES * 2) + 2), a1
                    ENDR
                    rts

                section data
                include src/sprite_l.inc    ; The scroller trigonometric tables

sprite_skew_pointer: dc.w 0  ; Current pointer to the sprite_skew_pointer table. Even words
