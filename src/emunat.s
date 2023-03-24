; The reference
;example:
;      jsr     _asm_init_nativefeatures
;start hatari with --fastwforward, then after PRG init do
;      jsr    _asm_nf_fastforward_off
;WARNING: NF_FRAMEINFO and NF_STDERR_NUM are only present in tin's Hatari build
;=======================================
;;@description
;;Initialize the emulators Native Features functionality - if present 
;;see also: http://wiki.aranym.org/natfeats/proposal
;;Hatari supports NF if activated via command line: "--natfeats true"
                XDEF   _asm_init_nativefeatures
                XDEF   _asm_nf_fastforward
                XDEF   _asm_nf_stderr
                XDEF   _asm_nf_debugger
                XDEF   _asm_nf_shutdown
                XDEF   NF_DEBUGGER
_asm_init_nativefeatures:
;=======================================
                move.l  SP,in_savessp+2
                move.l  $10.w,in_saveillegal+2
                move.l  #in_fail,$10.w 
                ;get all ids 
                moveq   #0,D0
                pea     nf_stderr_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_stderr_id
                or.l    D0,nf_has_flag
                moveq   #0,D0
                pea     nf_shutdown_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_shutdown_id
                or.l    D0,nf_has_flag
                moveq   #0,D0
                pea     nf_fastforward_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_fastforward_id
                or.l    D0,nf_has_flag
                moveq   #0,D0
                pea     nf_debugger_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_debugger_id
                moveq   #0,D0
                pea     nf_frameinfo_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_frameinfo_id
                or.l    D0,nf_has_flag
                moveq   #0,D0
                pea     nf_stderr_num_name
                pea     0
                DC.W    $7300
                lea     8(SP),SP
                move.l  D0,nf_stderr_num_id
in_end:         or.l    D0,nf_has_flag
in_savessp:     lea     0,SP
in_saveillegal: move.l  #0,$10.w
                rts
in_fail:        moveq   #0,D0                  
                bra.s   in_end
nf_has_flag:    DC.L    0
;;------------------------------------
;;@description
;;print to stderr on Host-system
;;A0=>Textadresse                
_asm_nf_stderr:      tst.l   nf_has_flag
                bne.s   nfs_ok
                rts
nfs_ok:         move.l  A0,-(SP)
                move.l  nf_stderr_id,-(SP)
                pea     0
                DC.W    $7301
                lea     12(SP),SP
                rts                
;;------------------------------------
;;@description
;;call hatari debugger

                MACRO NF_DEBUGGER
                move.l  nf_debugger_id,-(SP)
                pea     0
                DC.W    $7301
                lea     8(SP),SP
                ENDM
_asm_nf_debugger:    tst.l   nf_has_flag
                bne.s   nfs_ok2
                rts
nfs_ok2:        NF_DEBUGGER
                rts                
;;------------------------------------
;;@description
;;shutdown hatari                
_asm_nf_shutdown:    tst.l   nf_has_flag
                bne.s   nfs_ok3
                rts
nfs_ok3:        move.l  nf_shutdown_id,-(SP)
                pea     0
                DC.W    $7301
                lea     8(SP),SP
                rts                
;;------------------------------------
;;@description
;;toggle fastForward 
nf_fastforward_on: 
                moveq   #1,D0
                bra.s   _asm_nf_fastforward
nf_fastforward_off: 
                moveq   #0,D0
;D0=>0=disable FastForward, 1 >=enable
_asm_nf_fastforward:
                tst.l   nf_has_flag
                bne.s   nfs_ok4
                rts
nfs_ok4:        move.l  D0,-(SP)
                move.l  nf_fastforward_id,-(SP)
                pea     0
                DC.W    $7301
                lea     12(SP),SP
                rts                
;------------------------------------
;;@description
;;Get info Frame/Scanline/Cycle
;;A0=>Pointer to struct:
EMUNAT_FRAMEINFO_FRAMENO        EQU 0
EMUNAT_FRAMEINFO_SCANLINE       EQU 4
EMUNAT_FRAMEINFO_FRAMECYCLE     EQU 8
EMUNAT_FRAMEINFO_CYCLEPERFRAME  EQU 12
EMUNAT_FRAMEINFO_CYCLEPERLINE   EQU 16
EMUNAT_FRAMEINFO_LINESPERFRAME  EQU 20
;; * 		framenumber.l, 
;: * 		scanline.l, 
;: * 		current cycle in frame.l 
;: * 		cycles per frame.l, 
;: * 		cycles per line.l, 
;: * 		scanlines per frame.l 
nf_frameinfo:
                tst.l   nf_has_flag
                bne.s   nfs_ok5
                rts
nfs_ok5:        move.l  A0,-(SP)
                move.l  nf_frameinfo_id,-(SP)
                pea     0
                DC.W    $7301
                lea     12(SP),SP
                rts                
;;------------------------------------
;;@description
;;Print numeric value to stderr on Host-system
;;D0=>Value                
nf_stderr_num:  tst.l   nf_has_flag
                bne.s   nfs_ok6
                rts
nfs_ok6:        move.l  D0,-(SP)
                move.l  nf_stderr_num_id,-(SP)
                pea     0
                DC.W    $7301
                lea     12(SP),SP
                rts                
;------------------------------------
nf_stderr_name:     DC.B    "NF_STDERR",0
nf_debugger_name:   DC.B    "NF_DEBUGGER",0
nf_shutdown_name:   DC.B    "NF_SHUTDOWN",0
nf_fastforward_name: DC.B    "NF_FASTFORWARD",0
nf_frameinfo_name:  DC.B    "NF_FRAMEINFO",0
nf_stderr_num_name: DC.B    "NF_STDERR_NUM",0
                	EVEN
nf_stderr_id:   	DC.L    0
nf_debugger_id:   	DC.L    0
nf_shutdown_id:   	DC.L    0
nf_fastforward_id:  DC.L    0
nf_frameinfo_id:   	DC.L    0
nf_stderr_num_id:   DC.L    0