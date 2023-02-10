; Copied from https://nguillaumin.github.io/perihelion-m68k-tutorials/_of_using_the_gramophone.html
;
; ym6.s
;
; Playback of YM5 and YM6 files created by various YM-recorders.
; Uses no interupt and not so much CPU.
; About 42k register data per minute music.

		section	text

		XDEF _asm_music_ym_init
		XDEF _asm_music_ym_play
		XDEF _asm_music_ym_exit

_asm_music_ym_init:
                move.l  #ym_file, a0              ; start of ym file
                move.l  12(a0), ym_frames         ; store number of frames
                add.l   #34, a0                   ; beginning of text
.song_name
                cmp.b   #0, (a0)+                 ; search for 0
                bne     .song_name
.comment
                cmp.b   #0, (a0)+                 ; search for 0
                bne     .comment
.song_data
                cmp.b   #0, (a0)+                 ; search for 0
                bne     .song_data
                move.l  a0, ym_music              ; skipped 3 zero, store address
		rts		


_asm_music_ym_play:

		move.l  ym_music, a0              ; pointer to current music data
		moveq.l #0, d0                    ; first yammy register
.play
		move.b  d0, $ff8800               ; write to register
		move.b  (a0), $ff8802             ; write music data
		add.l   ym_frames, a0             ; jump to next register in data
		addq.b  #1, d0                    ; next register
		cmp.b   #16, d0                   ; see if last register
		bne     .play                      ; if not, write next one

		addq.l  #1, ym_music                 ; next set of registers
		addq.l  #1, ym_play_time             ; 1/50th second play time

		move.l  ym_frames, d0
		move.l  ym_play_time, d1
		cmp.l   d0, d1                    ; see if at end of music file
		bne     .no_loop
		sub.l   d0, ym_music                 ; beginning of music data
		move.l  #0, ym_play_time             ; reset play time
.no_loop
		rts						;


_asm_music_ym_exit:	
		lea.l	$ffff8800.w,a0				;exit player
		lea.l	$ffff8802.w,a1
		move.b	#8,(a0)
		clr.b	(a1)
		move.b	#9,(a0)
		clr.b	(a1)
		move.b	#10,(a0)
		clr.b	(a1)
		rts


		section	data

ym_music:           dc.l    0                         ; address of music data
ym_frames:          dc.l    0                         ; how many frames of music data
ym_play_time:    	dc.l    0                         ; how many VBL's has elapsed

ym_file:			incbin	'resources/music.ym'

		section	text

