;
;       "Inspired" by: https://files.dhs.nu/files_source/spiny.s
;
        XDEF    _asm_save_state
        XDEF    _asm_restore_state


        section code

;      Save the state of the system and sets the VBL and Timer B to our own
;      routines.
;      ; a1: Address of the VBL routine
;      ; a2: Address of the Timer B routine
_asm_save_state:
		lea	save_screenadr,a0		    ;Save old screen address
		move.b	$ffff8201.w,(a0)+
		move.b	$ffff8203.w,(a0)+
		move.b	$ffff820d.w,(a0)+

		movem.l	$ffff8240.w,d0-d7		;Save old palette
		movem.l	d0-d7,save_palette

		move.b	$ffff8260.w,save_resolution		;Save old resolution
		clr.b	$ffff8260.w			            ;Set low resolution

		move.w	#$2700,sr			    ;Stop all interrupts
		move.l	$70.w,save_vbl			;Save old VBL
		move.l	$68.w,save_hbl			;Save old HBL
		move.l	$134.w,save_ta			;Save old Timer A
		move.l	$120.w,save_tb			;Save old Timer B
		move.l	$114.w,save_tc			;Save old Timer C
		move.l	$110.w,save_td			;Save old Timer D
		move.l	$118.w,save_acia		;Save old ACIA
		move.l	a1,$70.w			    ;Install our own VBL
		move.l	a2,$120.w   			;Install our own Timer B
		move.l	#dummy,$68.w			;Install our own HBL (dummy)
		move.l	#dummy,$134.w			;Install our own Timer A (dummy)
		move.l	#dummy,$114.w			;Install our own Timer C (dummy)
		move.l	#dummy,$110.w			;Install our own Timer D (dummy)
		move.l	#dummy,$118.w			;Install our own ACIA (dummy)
		move.b	$fffffa09.w,save_intb		;Save MFP state for interrupt enable B
		move.b	$fffffa15.w,save_intb_mask	;Save MFP state for interrupt mask B
		clr.b	$fffffa07.w			;Interrupt enable A (Timer-A & B)
		clr.b	$fffffa13.w			;Interrupt mask A (Timer-A & B)
		clr.b	$fffffa09.w			;Interrupt enable B (Timer-C & D)
		clr.b	$fffffa15.w			;Interrupt mask B (Timer-C & D)
		move.w	#$2300,sr			;Interrupts back on

		move.b	#$12,$fffffc02.w		;Kill mouse
        rts


_asm_restore_state:
		move.w	#$2700,sr			;Stop all interrupts
		clr.b	$fffffa1b.w			;Timer B control (Stop)
		move.l	save_vbl,$70.w			;Restore old VBL
		move.l	save_hbl,$68.w			;Restore old HBL
		move.l	save_ta,$134.w			;Restore old Timer A
		move.l	save_tb,$120.w			;Restore old Timer B
		move.l	save_tc,$114.w			;Restore old Timer C
		move.l	save_td,$110.w			;Restore old Timer D
		move.l	save_acia,$118.w		;Restore old ACIA
		move.b	save_intb,$fffffa09.w		;Restore MFP state for interrupt enable B
		move.b	save_intb_mask,$fffffa15.w	;Restore MFP state for interrupt mask B
		move.w	#$2300,sr			;Interrupts back on

		move.b	save_resolution,$ffff8260.w		;Restore old resolution

		movem.l	save_palette,d0-d7			;Restore old palette
		movem.l	d0-d7,$ffff8240.w

		lea	save_screenadr,a0		;Restore old screen address
		move.b	(a0)+,$ffff8201.w
		move.b	(a0)+,$ffff8203.w
		move.b	(a0)+,$ffff820d.w

		move.b	#$8,$fffffc02.w			;Enable mouse

		rts

dummy:		rte

		section	bss
save_palette:      	ds.w	16
save_screenadr:	    ds.l	1
save_vbl:	        ds.l	1
save_hbl:	        ds.l	1
save_ta:	        ds.l	1
save_tb:	        ds.l	1
save_tc:	        ds.l	1
save_td:	        ds.l	1
save_acia:	        ds.l	1
save_intb:	        ds.b	1
save_intb_mask:	    ds.b	1
save_resolution:	ds.b	1
            		even

		section	data

		end