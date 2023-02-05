; Constants file
; all the global constants are defined here
; They must start with an underscore and a letter


_BUFFER_NUMBERS         equ     32          ; number of buffers to use. Only power of 2 allowed (2, 4, 8, 16...)
_SCREEN_SIZE            equ     32000       ; size of the screen in bytes
_SCREEN_WIDTH_BYTES     equ     160         ; width of a screen line in bytes
_SCREEN_HEIGHT_LINES    equ     192         ; height of the visible screen in lines

FONT_LARGE_SIZE_WORDS   equ     600         ; 25 lines x 6 bytes x 3 planes

; Blitter section
HALFTONE_RAM        equ $00
SRC_ADDR            equ $24
SRC_X_INCREMENT     equ $20
SRC_Y_INCREMENT     equ $22
ENDMASK1_REG        equ $28
ENDMASK2_REG        equ $2A
ENDMASK3_REG        equ $2C
DEST_ADDR           equ $32
DEST_X_INCREMENT    equ $2E
DEST_Y_INCREMENT    equ $30
BLOCK_X_COUNT       equ $36
BLOCK_Y_COUNT       equ $38
BLITTER_HOP         equ $3A
BLITTER_OPERATION   equ $3B
BLITTER_CONTROL_REG equ $3C
BLITTER_SKEW        equ $3D
M_LINE_BUSY         equ  %00000111        ; mask for the Blitter line busy bit
F_LINE_BUSY         equ  %10000000        ; flag to set the Blitter line busy bit in shared (BLIT) mode
HOG_MODE            equ  %11000000        ; flag to set the Blitter line busy bit in exclusive (HOG) mode 
