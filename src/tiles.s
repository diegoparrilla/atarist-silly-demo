                        include src/constants.s     ; Global constants. Start with '_'

    XDEF    _asm_init_tiles
    XDEF    _asm_draw_tiles
    XDEF    _asm_draw_uridium
    XREF    _screen_next


                ; Tiles section
TILE_WIDTH      EQU 4
DST_WIDTH       EQU TILE_WIDTH * _SCREEN_BITPLANES
TILE_HEIGHT     EQU 32
BITPLANES       EQU 1
BITPLANES_SKIP  EQU 3
BYTES_PER_PLANE EQU 2
TILES_HEIGHT_SCREEN EQU (_SCREEN_PHYSICAL_HEIGHT_LINES / TILE_HEIGHT)

URIDIUM_TILE_WIDTH      EQU 4
URIDIUM_DST_WIDTH       EQU URIDIUM_TILE_WIDTH * _SCREEN_BITPLANES
;URIDIUM_TILE_HEIGHT     EQU 127
URIDIUM_TILE_HEIGHT     EQU 136
URIDIUM_BITPLANES       EQU 1
URIDIUM_BITPLANES_SKIP  EQU 3
URIDIUM_BYTES_PER_PLANE EQU 2
;URIDIUM_FULL_TILE_WIDTH  EQU 344        ; bytes
URIDIUM_FULL_TILE_WIDTH  EQU  1672       ; bytes
URIDIUM_SCREEN_OFFSET_Y EQU 32 * _SCREEN_WIDTH_BYTES
                section code

;   Init the tiles routines
_asm_init_tiles:
                    move.w #_SCROLL_BACKGROUND_START,tiles_pixel_offset; We should start with minus one because the first time we call the routine we will add 1 to it.
                    move.w #URIDIUM_FULL_TILE_WIDTH -16 , tiles_offset
                    move.w #1, tiles_tiktok
                    rts

;   Draw the tiles in the last plane available
_asm_draw_tiles:
                    move.w tiles_pixel_offset, d0
                    addq #_SCROLL_BACKGROUND_SPEED, d0
                    and.w #31, d0
                    move.w d0, tiles_pixel_offset
                    lsr.w #1, d0
                    beq.s .repaint_tiles
                    rts

.repaint_tiles:
                    moveq #(2 * BITPLANES), d0 ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    moveq #(2 * BITPLANES), d1 ; source Y increment. Jump 3 (2 + 2 + 2) planes.
                    moveq #(2 * _SCREEN_BITPLANES), d2 ; dest X increment. Jump 4 (2 + 2 + 2 + 2) planes.
                    move.w #(_SCREEN_WIDTH_BYTES - DST_WIDTH + 2 * _SCREEN_BITPLANES), d3 ; dest Y increment. Jump 4 (2 + 2 + 2 + 2) planes of empty places on the screen.
                    moveq #DST_WIDTH / (2 * _SCREEN_BITPLANES), d4 ; block X count. It seems don't need to reinitialize every bitplane.
                    moveq #0, d5
                    moveq #TILE_HEIGHT, d6 ; block Y count. This one must be reinitialized every bitplane

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d0, SRC_X_INCREMENT(a6) 
                    move.w d1, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #%00000011, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask3 register

                    lea atari_tile, a0               ; 1st tile
                    move.l _screen_next, a1     ; a1 -> screen base address
                    add.w #_SCREEN_WIDTH_NO_L_OFFSET_BYTES + BITPLANES_SKIP * 2, a1  ; a1 -> now is in the non visible part of the screen

                    REPT TILES_HEIGHT_SCREEN

                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    add.w #(_SCREEN_WIDTH_BYTES * TILE_HEIGHT), a1
                    ENDR
                    rts

;   Draw the uridium tiles in the last plane available
_asm_draw_uridium:
                    move.w tiles_offset, d7
                    move.w tiles_pixel_offset, d0
                    addq #_SCROLL_BACKGROUND_SPEED, d0
                    and.w #31, d0
                    move.w d0, tiles_pixel_offset
                    tst.w d0
                    bne.s .ignore_next_tile_uridium
;                    add.w #4, d7             ; next tile
                    add.w #16, d7             ; next tile
                    cmp.w #URIDIUM_FULL_TILE_WIDTH, d7
                    blt.s .next_tile_uridium
                    moveq #0, d7
.next_tile_uridium:
                    move.w d7, tiles_offset
.ignore_next_tile_uridium:
                    lsr.w #1, d0
                    beq.s .repaint_uridium_tiles
                    rts

.repaint_uridium_tiles:
                    moveq #(2 * 4), d0 ; source X increment. Jump 3 (2 + 2 + 2) planes.
                    move.w #(URIDIUM_FULL_TILE_WIDTH - 16 + 2 * _SCREEN_BITPLANES), d1 ; source Y increment. Jump 3 (2 + 2 + 2) planes.
                    moveq #(2 * _SCREEN_BITPLANES), d2 ; dest X increment. Jump 4 (2 + 2 + 2 + 2) planes.
                    move.w #(_SCREEN_WIDTH_BYTES - URIDIUM_DST_WIDTH + 2 * _SCREEN_BITPLANES), d3 ; dest Y increment. Jump 4 (2 + 2 + 2 + 2) planes of empty places on the screen.
                    moveq #URIDIUM_DST_WIDTH / (2 * _SCREEN_BITPLANES), d4 ; block X count. It seems don't need to reinitialize every bitplane.
                    moveq #0, d5
                    move.w #URIDIUM_TILE_HEIGHT, d6 ; block Y count. This one must be reinitialized every bitplane

; Init blitter registers
                    lea  $FF8A00,a6                 ; a6-> BLiTTER register block
                    move.w d0, SRC_X_INCREMENT(a6) 
                    move.w d1, SRC_Y_INCREMENT(a6) ; source Y increment. Increase the 4 planes.
                    move.w d2, DEST_X_INCREMENT(a6) ; dest X increment. Jump 3 (2 + 2 +2) planes.
                    move.w d3, DEST_Y_INCREMENT(a6) ; dest Y increment. Increase the 4 planes.
                    move.w d4, BLOCK_X_COUNT(a6) ; block X count. It seems don't need to reinitialize every bitplane.
                    move.b #$2, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #%00000011, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.w #$FFFF, ENDMASK1_REG(a6) ; endmask1 register
                    move.w #$FFFF, ENDMASK2_REG(a6) ; endmask2 register
                    move.w #$FFFF, ENDMASK3_REG(a6) ; endmask3 register

                    tst.w tiles_tiktok
                    bne.s .uridium_tiles_tok
                    lea uridium_tile_tik, a0
                    bra.s .uridium_tile_go
.uridium_tiles_tok:
                    lea uridium_tile_tok, a0    

.uridium_tile_go:
;                    add.l #58, a0                     ; BMP format padding
                    add.l #38, a0                     ; RBM format padding

                    add.w d7, a0                     ; tile offset
                    move.l _screen_next, a1     ; a1 -> screen base address
                    add.w #URIDIUM_SCREEN_OFFSET_Y + (_SCREEN_WIDTH_NO_L_OFFSET_BYTES + BITPLANES_SKIP * 2), a1  ; a1 -> now is in the non visible part of the screen
                    moveq #0, d0
                    move.w d0, (-_SCREEN_WIDTH_BYTES, a1)
                    move.w d0, (-_SCREEN_WIDTH_BYTES + 8, a1)

                    move.b d5, BLITTER_SKEW(a6) ; blitter skew:
                    move.l a0, SRC_ADDR(a6)  ; source address
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode

                    rts

                    subq #BITPLANES_SKIP * 2, a1
                    REPT 3
                    move.b #$0, BLITTER_HOP(a6) ; blitter HOP operation. Copy src to dest, 1:1 operation.
                    move.b #$0, BLITTER_OPERATION(a6) ; blitter operation. Copy src to dest, replace copy.
                    move.l a1, DEST_ADDR(a6) ; destination address
                    move.w d6, BLOCK_Y_COUNT(a6) ; block Y count. This one must be reinitialized every bitplane
                    move.b #HOG_MODE, BLITTER_CONTROL_REG(a6) ; Hog mode
                    addq #2, a1
                    ENDR

                    rts




                section bss
tiles_pixel_offset:
                ds.w 1
tiles_offset:
                ds.w 1
tiles_tiktok:
                ds.w 1

                section data
atari_tile:     dc.l %00000000000000000000000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000000110111011000000000000
                dc.l %00000000001110111011100000000000
                dc.l %00000000001100111001100000000000
                dc.l %00000000001100111001100000000000
                dc.l %00000000011100111001110000000000
                dc.l %00000000011000111000110000000000
                dc.l %00000000111000111000111000000000
                dc.l %00000001110000111000011100000000
                dc.l %00000011110000111000011110000000
                dc.l %00011111100000111000001111110000
                dc.l %00011111000000111000000111110000
                dc.l %00011100000000111000000001110000
                dc.l %00000000000000000000000000000000
                dc.l %00000010011111001000011110010000
                dc.l %00000101000100010100010001010000
                dc.l %00000101000100010100010001010000
                dc.l %00000101000100010100010001010000
                dc.l %00001000100100100010011110010000
                dc.l %00001111100100111110010010010000
                dc.l %00001000100100100010010010010000
                dc.l %00010000010101000001010001010000
                dc.l %00010000010101000001010001010000
                dc.l %00000000000000000000000000000000
                dc.l %00000000000000000000000000000000
;uridium_tile:
;                incbin "resources/URIDIUM.PBM"
uridium_tile_tik:
                incbin "resources/uridium_f0_p2.rbp"
uridium_tile_tok:
                incbin "resources/uridium_f1_p2.rbp"
                end




