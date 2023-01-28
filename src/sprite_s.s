                        include src/constants.s     ; Global constants. Start with '_'

; Small sprites routine
; 16x16 pixels and 1 bit plane

    XDEF	_asm_cook_small_sprites
    XDEF    _asm_restore_all_sprites
    XDEF    _asm_show_all_sprites
    XREF    _font_small_ready
    XREF    _screen_next
    XREF    _current_screen_mask    ; Current we have to now the screen mask to know where to display and restore the sprite

MAX_SPRITES             equ 8     ; Maximum number of sprites on screen
NUMBER_OF_CHARS         equ 40     ; Number of characters in the font
BITPLANES               equ 1      ; Number of bitplanes
BACKGROUND_BITPLANES    equ 4      ; Number of bitplanes for the background stored in the buffer
MASKPLANES              equ 1      ; Number of maskplanes
SRC_WIDTH               equ 1      ; Original width of the sprite in WORDS
SRC_HEIGHT              equ 16     ; Original height of the sprite in lines
DST_WIDTH               equ 2      ; Original width of the sprite in WORDS
DST_HEIGHT              equ 16     ; Original height of the sprite in lines
TOTAL_SHIFTS            equ 16     ; Total number of shifts (The bits of a word)
SPRITE_SIZE_WITH_SHIFT  equ (DST_WIDTH * DST_HEIGHT * (BITPLANES + MASKPLANES) * 2) ; Size of the sprite with the shift
SPRITE_SIZE_ORIGINAL    equ (SRC_WIDTH * SRC_HEIGHT * BITPLANES * 2)              ; Size of the original sprite (1 bitplane 16 bits 16 lines) in bytes
SPRITE_SIZE_BACKGROUND  equ (DST_WIDTH * DST_HEIGHT * BACKGROUND_BITPLANES) * 2 ; Size of the background of the sprite (2 bitplanes 16 bits 16 lines)    
SPRITE_SIZE_BACKGROUND_SHIFTS equ 8 ; 2 ^ SPRITE_SIZE_BACKGROUND_SHIFTS should be the SPRITE_SIZE_BACKGROUND value

                section code

; d0.w <- Sprite X position
; d1.w <- Sprite Y position
_asm_show_all_sprites:
; Calculate the start value of the memory address of X position
                lea sprite_x_pos, a5            ; The travelling routine for the sprite X axis
                move.w sprite_x_pointer, d0
                cmp.w sprites_table_size, d0
                bne.s .increse_sprite_x_pointer
                moveq #0,d0                     ; reset the sprite X pointer
.increse_sprite_x_pointer:
                add.w d0,a5                     ; The address of the sprite X axis
                addq #2, d0
                move.w d0, sprite_x_pointer     ; Store the next value for the future

; Calculate the start value of the memory address of Y position
                lea sprite_y_pos, a6            ; The travelling routine for the sprite Y axis
                move.w sprite_y_pointer, d1
                cmp.w sprites_table_size, d1
                bne.s .increse_sprite_y_pointer
                moveq #0,d1                     ; reset the sprite Y pointer
.increse_sprite_y_pointer:
                add.w d1,a6                     ; The address of the sprite Y axis
                addq #2, d1
                move.w d1, sprite_y_pointer     ; Store the next value for the future

; Display the sprites
                move.w (8, a5), d0                 ; Get the X position
                move.w (8, a6), d1                 ; Get the Y position
;                add.w #16,d0
                moveq #2, d2                        ; sprite number for 'C' 
                moveq #0, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (16, a5), d0                 ; Get the X position
                move.w (16, a6), d1                 ; Get the Y position
                add.w #16,d0
                moveq #0, d2                        ; sprite number for 'A'
                moveq #1, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (24, a5), d0                 ; Get the X position
                move.w (24, a6), d1                 ; Get the Y position
                add.w #32,d0
                moveq #13, d2                        ; sprite number for 'N'
                moveq #2, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (32, a5), d0                 ; Get the X position
                move.w (32, a6), d1                 ; Get the Y position
                add.w #48,d0
                moveq #0, d2                        ; sprite number for 'A'
                moveq #3, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (40, a5), d0                 ; Get the X position
                move.w (40, a6), d1                 ; Get the Y position
                add.w #64,d0
                moveq #11, d2                        ; sprite number for 'L'
                moveq #4, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (56, a5), d0                 ; Get the X position
                move.w (56, a6), d1                 ; Get the Y position
                add.w #96,d0
                moveq #27, d2                        ; sprite number for '2'
                moveq #5, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites

                move.w (64, a5), d0                 ; Get the X position
                move.w (64, a6), d1                 ; Get the Y position
                add.w #112,d0
                moveq #28, d2                        ; sprite number for '3'
                moveq #6, d3                        ; sprite index number
                jsr display_sprite_xy      ; display the flying small sprites
                rts

_asm_restore_all_sprites:
                move.w #6, d7
.loop_restore_all_sprites:
                move.w d7, d3
                jsr restore_sprite_background ; restore the flying small sprites
                dbf d7, .loop_restore_all_sprites
                rts


; Get the sprites background index where the pointer to the stored background 
; for the screen and the sprite index is stored, and the sprite background address buffer
; where the background is actually stored
; Parameters:
;   D3.W -> sprite index (0 to MAX_SPRITES)
; Returns:
;   a4 <- sprites background index buffer address
;   a2 <- sprites background buffer address
; Modifies:
;  d3, d4, d5
sprite_memory_bckground:

; The formula to calculate the sprite background index is:
; (_current_screen_mask * MAX_SPRITES * 4) + (sprite index * 4)
                lea sprites_bckgrnd_idx, a4     ; a4 <- points to init of the offset of the background buffer for the sprite
                moveq #0, d5                    ; d5 <- 0
                move.w _current_screen_mask, d4 ; d4 <- current screen mask
                lsl.w #3, d4                    ; d4 <- current screen mask * MAX_SPRITES
                move.w d4,d6
                add.w d4,d4                     ; d4 <- current screen mask * MAX_SPRITES * 2
                add.w d4,d4                     ; d4 <- current screen mask * MAX_SPRITES * 4
                move.w d3,d5                    ; d5 <- sprite index
                add.w d5,d5                     ; d5 <- sprite index * 2
                add.w d5,d5                     ; d5 <- sprite index * 4
                add.w d4,d5                     ; d5 <- sprite index * 4 + current screen mask * MAX_SPRITES * 4
                add.l d5,a4                     ; a4 <- pointer to the offset of the background buffer for the sprite index  in the current screen

; The formula to calculate the sprite background buffer address is:
; (_current_screen_mask * MAX_SPRITES * SPRITE_SIZE_BACKGROUND) + (sprite index * SPRITE_SIZE_BACKGROUND)
                lea sprites_bckgrnd, a2         ; a2 <- points to init of the background buffer for the sprite
                move.w d6,d4                    ; d4 <- current screen mask. current screen mask * MAX_SPRITES
                lsl.w #8, d4                    ; d4 <- current screen mask * SPRITE_SIZE_BACKGROUND
                lsl.w #8, d3                    ; d3 <- sprite index * SPRITE_SIZE_BACKGROUND
                add.w d4,d3                     ; d3 <- sprite index * SPRITE_SIZE_BACKGROUND + current screen mask * MAX_SPRITES * SPRITE_SIZE_BACKGROUND
                add.l d3,a2                     ; a2 <- pointer to the background buffer for the sprite index  in the current screen
                rts

; Convert the 16x16x1 fonts to 32x16x2 plus 16 rotations for old school games
; 1 bitplane for the sprite and 1 bitplane for the mask
_asm_cook_small_sprites:
                    move.l _font_small_ready,a0    ; a0 <- font_small_ready address
                    lea sprites_ready,a1        ; a1 <- sprites_ready address
                    move.w #NUMBER_OF_CHARS - 1,d0  ; d0 <- NUMBER_OF_CHARS -1. Count the number of chars in the font
next_sprite:
                    moveq #0,d1                 ; d1 <- 0. Track the number of TOTAL_SHIFTS
rotate_sprite:
                    moveq #0,d2                 ; d2 <- 0. Count the total lines of each sprite in DST_HEIGHT
next_line:
                    moveq #0,d3                 ; d3 <- 0
                    move.w (a0, d2),d3          ; d3 <- read the next word from the font and inc a0
                    swap d3                     ; d3 <- swap the word
                    lsr.l d1,d3                 ; d3 <- shift the word to the right "d1" times
                    move.l d3,d4                ; d4 <- d3 (copy the word)
                    not.l d4                    ; d4 <- d4 (negate the word) to create the mask 

                    move.l d4,(a1)+             ; write the mask to the maskplane. It's always before the visible plane
                    move.l d3,(a1)+             ; write the sprite to the visible plane

                    addq #2,d2                  ; d2 <- d2 + 2 (1 word two bytes). Increment the line counter
                    and.w #(DST_HEIGHT*2)-1,d2  ; d2 <- d2 & (DST_HEIGHT * 2bytes)-1. Keep the line counter in the range 0..15
                    bne.s next_line             ; if d2 != 0 then next line of the sprite. If d2 == 0 then we are done with
                                                ; this sprite for this shift

                    addq #1,d1                  ; d1 <- d1 + 1. Increment the shift counter
                    and.w #TOTAL_SHIFTS - 1,d1  ; d1 <- d1 & TOTAL_SHIFTS. Keep the shift counter in the range 0..15
                    bne.s rotate_sprite         ; if d1 != 0 then rotate_sprite. If d1 == 0 then we are done with this shift

                    add.w #SPRITE_SIZE_ORIGINAL, a0 ; a0 <- a0 + SPRITE_SIZE_ORIGINAL
                                                ; Calculate address of next source sprite and loop again. We are done with this sprite
                    dbf d0,next_sprite          ; d0 <- d0 - 1. Decrement the sprite counter and loop again. We are done with this char
                    rts                         ; We are done

; Restore the background overwritten by the sprite in the current buffered screeen
; Parameters:
;   D3.W <- sprite index to restore
; Returns:
;   D3.W <- sprite index to restore
;   A2.L <- screen background buffer address. The address of memory to save the background of the screen
;   A3.L <- screen address where the background was restored
;   A4.L <- pointer to the offset of the background buffer for the sprite index  in the current screen
; Modifies:
;   a2, a3, a4
;   d0, d1, d2, d3, d4, d5, d6
restore_sprite_background:
                    bsr sprite_memory_bckground

; a3 <- screen background buffer address. The address of memory to save the background of the screen
                    move.l (a4), a3                 ; Retrieve the screen address to restore the background buffer
                    cmp.l #0,a3                     ; Test if the sprite was displayed in the previus pass
                    beq skip_restore                ; If the sprite was not displayed in the previus pass, skip the restore sprite routine

; a2 <- screen background buffer address. The address of memory to save the background of the screen for the future
                    REPT DST_HEIGHT                                    ; Repeat DST_HEIGHT number of lines

                    movem.l ((REPTN * 4 * BACKGROUND_BITPLANES), a2), d0-d3  ; d0 <- read the background 4 planes * 32 bits

                    move.w d0, (8 + (REPTN * _SCREEN_WIDTH_BYTES), a3)    ; restore the background first 16 bits
                    swap d0                                               ; swap the 32 bits
                    move.w d0, ((REPTN * _SCREEN_WIDTH_BYTES), a3)        ; restore the background second 16 bits

                    move.w d1, (10 + (REPTN * _SCREEN_WIDTH_BYTES), a3)   ; restore the background first 16 bits
                    swap d1                                               ; swap the 32 bits
                    move.w d1, (2 +(REPTN * _SCREEN_WIDTH_BYTES), a3)     ; restore the background second 16 bits

                    move.w d2, (12 + (REPTN * _SCREEN_WIDTH_BYTES), a3)   ; restore the background first 16 bits
                    swap d2                                               ; swap the 32 bits
                    move.w d2, (4 + (REPTN * _SCREEN_WIDTH_BYTES), a3)    ; restore the background second 16 bits

;                    move.w d3, (14 + (REPTN * _SCREEN_WIDTH_BYTES), a3)   ; restore the background first 16 bits
;                    swap d3                                               ; swap the 32 bits
;                    move.w d3, (6 + (REPTN * _SCREEN_WIDTH_BYTES), a3)    ; restore the background second 16 bits

                    ENDR
skip_restore:
                    rts

; Display the sprite passing the X and Y coordinates
; Parameters:
;   D0.W <- X coordinate (0 to 304)
;   D1.W <- Y coordinate (0 to 184)
;   D2.W <- sprite number (0 to 255)
;   D3.W -> Char index (0 to MAX_SPRITES)
; Returns:
;   Nothing
; Modifies:
;   a0, a1, a2, a3, a4
;   d0, d1, d2, d3, d4, d5, d6
display_sprite_xy:
                    move.l _screen_next, a1         ; a1 <- screen_next. A1 now contains the address of the screen where the sprite will be displayed
                    lea sprites_ready,a0            ; a0 <- Memory address where the cooked sprites are stored
                    move.w d0, d4                   ; d4 <- d0. Copy the X coordinate
                    and.w #TOTAL_SHIFTS - 1, d4     ; d4 <- d4 & (TOTAL_SHIFTS - 1). Keep the X coordinate in the range 0..15
; Optimization for X axis
;                    mulu #SPRITE_SIZE_WITH_SHIFT,d4 ; d4 <- d4 * SPRITE_SIZE_WITH_SHIFT. d4 now contains the offset of the sprite shifted
; Rotate left
                    lsl.w #7, d4                    ; d4 <- d4 << 7. d4 now contains the offset of the sprite shifted in bytes
                    add.w d4,a0                     ; a0 <- a0 + d4. a0 now contains the memory address of the sprite shifted

                    move.w d2, d4
;                    mulu #(SPRITE_SIZE_WITH_SHIFT * TOTAL_SHIFTS), d4 ; d4 <- d4 * SPRITE_SIZE_WITH_SHIFT. d4 now contains the sprite number multiplied by the number of buffers and the sprite size
                    lsl.l #8, d4                    ; d4 <- d4 * SPRITE_SIZE_WITH_SHIFT. d4 now contains the sprite number multiplied by the number of buffers and the sprite size  
                    lsl.l #3, d4                    ; d4 <- d4 * SPRITE_SIZE_WITH_SHIFT. d4 now contains the sprite number multiplied by the number of buffers and the sprite size  
                    add.l d4, a0                    ; a0 <- a0 + d4. a0 now contains the memory address of the sprite with the index
; a0 <- sprite address. The address of the sprite shifted

                    ; Calculate X and Y addrees
                    and.w #(65536 - TOTAL_SHIFTS), d0 ; d0 <- d0 & (65535 - TOTAL_SHIFTS). Keep the X coordinate in the range 0..304
                    lsr.w #1, d0                      ; d0 <- d0 >> 1. d0 now contains the the byte offset of the sprite in X
                    add.w d0, a1                    ; a1 <- a1 + d0. a1 now contains the memory address of the screen
                                                    ; where the sprite will be displayed in X
; Optimization for Y axis
;                    mulu #_SCREEN_WIDTH_BYTES,d1     ; d1 <- d1 * _SCREEN_WIDTH_BYTES. d1 now contains the offset of the screen in Y
; 
                    lsl.w	#4,d1                   ;
                    move.w	d1,d0
                    add.w	d1,d1
                    add.w	d1,d1
                    add.w	d0,d1
                    add.w	d1,d1                    ; Till here   

                    add.w d1,a1                     ; a1 <- a1 + d1. a1 now contains the memory address of the screen
                                                    ; where the sprite will be displayed in X and Y

; a1 <- screen address. The address of the screen where the sprite will be displayed
; store in the sprites_bckgrnd_idx to restore the background in the next frame
; a2 <- screen background buffer address. The address of memory to save the background of the screen for the future
; store the background overwritten by the sprite in the sprites_buffer to restore it in the next frame
                    bsr sprite_memory_bckground

                    move.l a1, (a4)                 ; Store the screen address in the background buffer

; Display the small sprite at the given memory address
; a0 <- sprite address. Where the mask and bitplane of the sprite are stored
; a1 <- screen address. The address of the screen where the sprite will be displayed
; a2 <- screen background buffer address. The address of memory to save the background of the screen for the future

                    REPT DST_HEIGHT                         ; Repeat DST_HEIGHT number of lines
                    movem.l (a0)+, d0-d1                    ; d0 <- read masks and bitplane of the line

                    move.w ((REPTN * _SCREEN_WIDTH_BYTES), a1), d2     ; d2 <- read the screen first 16 bits
                    swap d2
                    move.w (8 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2 ; d2 <- read the screen second 16 bits
                    move.l d2, (REPTN * 4 * BACKGROUND_BITPLANES, a2)                           ; save the screen background
                    and.l d0, d2                            ; d2 <- d2 & d0. Mask the screen with the mask
                    or.l d1, d2                             ; d2 <- d2 | d1. Or the bitplane with the screen
                    move.w d2, (8 + (REPTN * _SCREEN_WIDTH_BYTES), a1)        ; or the bitplane with the screen
                    swap d2
                    move.w d2, ((REPTN * _SCREEN_WIDTH_BYTES), a1)            ; or the bitplane with the screen

                    move.w (2 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2     ; d2 <- read the screen first 16 bits
                    swap d2
                    move.w (10 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2 ; d2 <- read the screen second 16 bits
                    move.l d2, (4 + (REPTN * 4 * BACKGROUND_BITPLANES), a2)                           ; save the screen background
                    and.l d0, d2                            ; d2 <- d2 & d0. Mask the screen with the mask
                    or.l d1, d2                             ; d2 <- d2 | d1. Or the bitplane with the screen
                    move.w d2, (10 + (REPTN * _SCREEN_WIDTH_BYTES), a1)        ; or the bitplane with the screen
                    swap d2
                    move.w d2, (2 + (REPTN * _SCREEN_WIDTH_BYTES), a1)            ; or the bitplane with the screen

                    move.w (4 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2     ; d2 <- read the screen first 16 bits
                    swap d2
                    move.w (12 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2 ; d2 <- read the screen second 16 bits
                    move.l d2, (8 + (REPTN * 4 * BACKGROUND_BITPLANES), a2)                           ; save the screen background
                    and.l d0, d2                            ; d2 <- d2 & d0. Mask the screen with the mask
                    or.l d1, d2                             ; d2 <- d2 | d1. Or the bitplane with the screen
                    move.w d2, (12 + (REPTN * _SCREEN_WIDTH_BYTES), a1)            ; or the bitplane with the screen
                    swap d2
                    move.w d2, (4 + (REPTN * _SCREEN_WIDTH_BYTES), a1)        ; or the bitplane with the screen

;                    move.w (6 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2     ; d2 <- read the screen first 16 bits
;                    swap d2
;                    move.w (14 + (REPTN * _SCREEN_WIDTH_BYTES), a1), d2 ; d2 <- read the screen second 16 bits
;                    move.l d2, (12 + (REPTN * 4 * BACKGROUND_BITPLANES), a2)                           ; save the screen background
;                    and.l d0, d2                            ; d2 <- d2 & d0. Mask the screen with the mask
;                    or.l d1, d2                             ; d2 <- d2 | d1. Or the bitplane with the screen
;                    move.w d2, (14 + (REPTN * _SCREEN_WIDTH_BYTES), a1)            ; or the bitplane with the screen
;                    swap d2
;                    move.w d2, (6 + (REPTN * _SCREEN_WIDTH_BYTES), a1)        ; or the bitplane with the screen

                    ENDR

                    rts



                section bss align 2
; The "sprite_ready" stores the 16x16x1 sprites in 32x16x2 format shifted and with a mask
sprites_ready:  ds.l  NUMBER_OF_CHARS * DST_WIDTH * DST_HEIGHT * (BITPLANES + MASKPLANES) * TOTAL_SHIFTS

; The "sprites_bckgrnd_idx" stores the memory address of the buffer of the screen for the sprite of the index
sprites_bckgrnd_idx:
                ds.l _BUFFER_NUMBERS * MAX_SPRITES

; The "sprites_bckgrnd" stores the background of the buffer of the screen for the sprite of the index
sprites_bckgrnd:
                ds.w (_BUFFER_NUMBERS * MAX_SPRITES * SPRITE_SIZE_BACKGROUND / 2)

                section data
                include src/sprite_s.inc    ; The sprite trigonometric tables

sprite_x_pointer: dc.w 0  ; Current pointer to the sprite_x_pos table. Even words
sprite_y_pointer: dc.w 0  ; Current pointer to the sprite_y_pos table. Even words
