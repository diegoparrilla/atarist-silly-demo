    XDEF    _asm_draw_tiles
    XREF    _screen_base
    XREF    _BUFFER_NUMBERS


                ; Tiles section
BYTES_PER_LINE  EQU 160
TILE_WIDTH      EQU 4
TILE_HEIGHT     EQU 32
BITPLANES       EQU 4
BITPLANES_SKIP  EQU 3
BYTES_PER_PLANE EQU 2
SCREEN_SIZE     EQU 32000
TILES_HEIGHT_SCREEEN EQU (200 / TILE_HEIGHT)

                section code

;   Draw the tiles in the last plane available
_asm_draw_tiles:
;                lea tile_1, a0               ; 1st tile
                lea atari_tile, a0               ; 1st tile
                bsr tile_rotate
                move.l #_screen_base, d2
                clr.b d2                     ; round to 32K boundary
                move.w #_BUFFER_NUMBERS - 1, d1                ; number of screen buffers minus 1
buffer_loop:
                move.l d2, a3
                move.w #TILES_HEIGHT_SCREEEN - 1, d0                ; Tiles vertical per screen minus 1
                addq #BITPLANES_SKIP * BYTES_PER_PLANE, a3      ; Plane to skip
tile_loop_vertical_axis:
                movea.l a3, a5                                  ; Use a5 as a copy of a3 for the tile copy

                move.w #((BYTES_PER_LINE / BYTES_PER_PLANE) / TILE_WIDTH) - 1, d5 ; Number of tiles per line minus 1
                clr.l d6
tile_loop_horizontal_axis:
                movea.l a0, a4                                  ; Use a4 as a copy of a0 for the tile copy
                movea.l a3, a5
                add.l d6, a5
                move.w #TILE_HEIGHT - 1, d4                   ; Lines per tile minus 1
vertical_axis_loop:
                movea.l a5,a6
                move.w #(TILE_WIDTH  / 2) - 1, d3            ; Words per tile line minus 1
horizontal_axis_loop:
                move.w (a4), (a6)                  ; Copy horizontal tile line to screen 
                add.l #(BITPLANES * BYTES_PER_PLANE), a6
                addq #2, a4
                dbf d3, horizontal_axis_loop

                add.l #BYTES_PER_LINE, a5 
                dbf d4, vertical_axis_loop

                add.l #(TILE_WIDTH * BITPLANES), d6
                dbf d5, tile_loop_horizontal_axis

                lea (BYTES_PER_LINE * (TILE_HEIGHT), a3), a3
                dbf d0, tile_loop_vertical_axis

                lea (TILE_HEIGHT * TILE_WIDTH ,a0), a0               ; Next tile
                add.l #SCREEN_SIZE,d2               ; Next buffer screen

                dbf d1, buffer_loop

                rts

;  Rotate the tiles 32xY depending on the buffers available
; A0 = Address of the master tile
tile_rotate:
                movea.l a0, a2
                move.w #(8 * TILE_WIDTH),d2                   ; 8 bits per byte of the tile width
                DIVU #_BUFFER_NUMBERS, d2
                move.w #TILE_WIDTH, d3                        ; tile size x axis
                move.w #_BUFFER_NUMBERS -1, d1                ; number of screen buffers minus 1
rotate_loop:
                lea (TILE_WIDTH * TILE_HEIGHT, a2), a1
                move.w #TILE_HEIGHT - 1, d4                   ; Lines per tile minus 1
rotate_lines:
                cmp.w #4, d3
                bne.s rotate_loop_16
                move.l (a2)+, d0
                rol.l d2, d0
                move.l d0, (a1)+
                bra.s rotate_loop_end
rotate_loop_16:
                move.w (a2)+, d0
                rol.w d2, d0
                move.w d0, (a1)+
rotate_loop_end:
                dbf d4, rotate_lines
                dbf d1, rotate_loop
                rts

                section bss

                section data
tile_1:         dc.w %0000000100000001
                dc.w %0000001000000010
                dc.w %0000010000000100
                dc.w %0000100000001000
                dc.w %0000010000000100
                dc.w %0000001000000010
                dc.w %0000000100000001
                dc.w %0000000000000000

                ds.l (TILE_WIDTH * TILE_HEIGHT) * 16 ; 16 tiles rotated max


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

                ds.l (TILE_WIDTH * TILE_HEIGHT) * 16 ; 16 tiles rotated max

                end

