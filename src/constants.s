; Constants file
; all the global constants are defined here
; They must start with an underscore and a letter

_BUFFER_NUMBERS                     equ     2           ; number of buffers to use. Only power of 2 allowed (2, 4, 8, 16...)
_SCROLL_BACKGROUND_SPEED            equ     4           ; 1 = 1 pixel per frame, 2 = 2 pixels per frame, etc. Use 2^n values
_SCROLL_BACKGROUND_START            equ     0           ; Start at odd address to avoid the 'jump' when the pixel offset is 0
_SCREEN_SIZE                        equ     _SCREEN_WIDTH_BYTES * _SCREEN_VISIBLE_HEIGHT_LINES       ; size of the visible screen in bytes
_SCREEN_L_OFFSET_BYTES              equ     24           ; value how many BYTES the Shifter is supposed to skip after each Rasterline
_SCREEN_L_OFFSET_WORDS              equ     _SCREEN_L_OFFSET_BYTES / 2    ; Same value in WORDS, needed by the register
_SCREEN_WIDTH_NO_L_OFFSET_BYTES     equ     160  ; width of a screen line in bytes
_SCREEN_WIDTH_BYTES                 equ     _SCREEN_WIDTH_NO_L_OFFSET_BYTES + _SCREEN_L_OFFSET_BYTES         ; width of a screen line in bytes
_SCREEN_HEIGHT_LINES                equ     192         ; height of the visible screen in lines
_SCREEN_VISIBLE_HEIGHT_LINES       equ      200         ; height of the visible screen in lines
_SCREEN_BITPLANES                   equ     4           ; number of bitplanes
_SCREEN_PHYS_HEIGHT_LINES           equ     236         ; height of the physical screen in lines
_SCREEN_PHYS_SIZE                   equ     _SCREEN_WIDTH_BYTES * _SCREEN_PHYS_HEIGHT_LINES * _SCREEN_BITPLANES       ; size of the physical screen in bytes

; Font large 
FONT_LARGE_SIZE_WORDS   equ     600 / 2         ; 25 lines x 6 bytes x 4 planes (last empty)

; C23 logo
C23LOGO_WIDTH_BYTES     equ     (40 - ((1) * 2)) * C23LOGO_PLANES
C23LOGO_HEIGHT_LINES    equ     57                              ; 59 lines height
C23LOGO_PLANES          equ     3                               ; 3 planes

; Video hardware section
VIDEO_BASE_ADDR_LOW     equ $ffff820d
VIDEO_BASE_ADDR_MID     equ $ffff8203
VIDEO_BASE_ADDR_HIGH    equ $ffff8201
VIDEO_BASE_PIXEL_OFFSET equ $ffff8265
VIDEO_BASE_LINE_OFFSET  equ $ffff820f

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
