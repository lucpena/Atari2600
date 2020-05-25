;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       This program creates a playfield in the screen     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       ROM START                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SEG 
    ORG $F000

Reset:
    CLEAN_START

    LDX #$80
    STX COLUBK             ; blue background

    LDA #$1C
    STA COLUPF              ; yellow playfield

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Start a new frame, configuring VBLANK and VSYNC     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:
    LDA #02
    STA VBLANK
    STA VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;             Generate the 3 lines of VSYNC                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 3                ; repeat all inside 3 times
        STA WSYNC           ; three scanlines for VSYNC
    REPEND                  ; end of the loop

    LDA #0
    STA VSYNC               ; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Generate the TIA output of 37 lines of VBLANK       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 37
        STA WSYNC           ; 37 lines of VBLANK
    REPEND

    LDA #0
    STA VBLANK              ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Set CTRLPF register to allow playfield reflection     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDX #%00000001
    STX CTRLPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              Draw the 192 visible scanlines              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Skip 7 scanlines with no playerfield set
    LDX #0
    STX PF0
    STX PF1
    STX PF2

    REPEAT 7
        STA WSYNC
    REPEND

    ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    LDX #%11100000
    STX PF0

    LDX #%11111111
    STX PF1
    STX PF2

    REPEAT 7
        STA WSYNC
    REPEND

    ; Set the next 164 lines only with PF0 third bit enabled
    LDX #%01100000
    STX PF0

    LDX #%0
    STX PF1

    LDX #%10000000
    STX PF2

    REPEAT 164
        STA WSYNC
    REPEND

    ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    LDX #%11100000
    STX PF0

    LDX #%11111111
    STX PF1
    STX PF2

    REPEAT 7
        STA WSYNC
    REPEND

    ; Skip 7 vertical lines with no PF set
    LDX #0
    STX PF0
    STX PF1
    STX PF2

    REPEAT 7
        STA WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Output 30 more VBLANK scanlines to complete the frame   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #2
    STA VBLANK

    REPEAT 30
        STA WSYNC
    REPEND 

    LDA #0
    STA VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Loop to next frame                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    JMP StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Complete ROM                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC
    .word Reset
    .word Reset