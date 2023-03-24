                    opt     CHKPC                           ;make sure PC relative code    (only required for SNDH or binary file)

                    XDEF   tuneinit
                    XDEF   tunedeinit
                    XDEF   tuneinter

                    section text
;..................................................................................
;header - for binary and sndh dont forget to trim away the $1C byte TOS header after compilation

tuneinit:
                    bra.s  replayroutine

tunedeinit:
                    bra.s  replayroutine+4

tuneinter:
                    bra.s  replayroutine+8

                    even

;..................................................................................
;Include files
;replayroutine:          incbin resources/TEST_STE.SND

;replayroutine:      incbin  resources/MYM_REPL.BIN         ;+$0    =init
                                                            ;+$4    =deinit
                                                            ;+$8    =interrupt
                                                            ;+$C    =adjust global volume with d0.w 0->127
                                                            ;+$10.b =zync code
                    even
replayroutine:          incbin  resources/HER1.SND
;replayroutine:          incbin  resources/TELEPHON.SND
;replayroutine:          incbin  resources/PWMWVJAM.SND
;replayroutine:          incbin  resources/DULCEDO.SND
;replayroutine:          incbin  resources/HYBRIS.SND
;replayroutine:          incbin  resources/OKS.SND
