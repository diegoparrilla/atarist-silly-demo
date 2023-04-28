
                    XDEF   tuneinit
                    XDEF   tunedeinit
                    XDEF   tuneinter
                    XDEF   tuneconfig

tuneconfig:
                    move.l #replayroutine1, tuneinit_index
                    move.l #replayroutine2, tuneinit_index+4
                    move.l #replayroutine1+4, tunedeinit_index
                    move.l #replayroutine2+4, tunedeinit_index+4
                    move.l #replayroutine1+8, tuneinter_index
                    move.l #replayroutine2+8, tuneinter_index+4
                    rts

;..................................................................................
;header - for binary and sndh dont forget to trim away the $1C byte TOS header after compilation

                    opt     CHKPC                           ;make sure PC relative code    (only required for SNDH or binary file)
; Pass the tune number in d0.w in any parameter register
tuneinit:
                    add.w d0,d0
                    add.w d0,d0
                    move.l tuneinit_index(pc, d0.w), a0
                    jmp (a0)

tunedeinit:
                    add.w d0,d0
                    add.w d0,d0
                    move.l tunedeinit_index(pc, d0.w), a0
                    jmp (a0)

tuneinter:
                    add.w d0,d0
                    add.w d0,d0
                    move.l tuneinter_index(pc, d0.w), a0
                    jmp (a0)

                    even
tuneinit_index:     ds.l 4
tunedeinit_index:   ds.l 4
tuneinter_index:    ds.l 4

;..................................................................................
;Include files

;replayroutine:      incbin  resources/MYM_REPL.BIN         ;+$0    =init
                                                            ;+$4    =deinit
                                                            ;+$8    =interrupt
                                                            ;+$C    =adjust global volume with d0.w 0->127
                                                            ;+$10.b =zync code
                    even
replayroutine1:          incbin  resources/HER1TA.SND
replayroutine2:          incbin  resources/TELEPHTA.SND
;replayroutine3:          incbin  resources/PWMWVJAM.SND
;replayroutine4:          incbin  resources/MODMATAD.SND
;replayroutine3:          incbin  resources/DULCEDO.SND
;replayroutine4:          incbin  resources/HYBRIS.SND
;replayroutine4:          incbin  resources/OKS.SND;
;replayroutine4:          incbin  resources/SERGANT.SND
;replayroutine3:          incbin  resources/ALLESNUR.SND
;replayroutine3:          incbin  resources/SEQUENCE.SND
