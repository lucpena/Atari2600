;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    This program creates screen objects in the screen     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Start an unitialized segment at $80 for variables     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SEG.U Variables
    ORG $80

P0XPos    byte             ; defines one byte for player 0 position X

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       ROM START                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SEG Code
    ORG $F000

Reset:
    CLEAN_START

    LDX #$80
    STX COLUBK              ; blue background

    LDX #$D0
    STX COLUPF              ; green playfield

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Initialize variables                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #10
    STA P0XPos

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

    REPEAT 3
        STA WSYNC
    REPEND

    LDA #0
    STA VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Set horizontal position of the player while in VBLANK  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA P0XPos              ; load register A with the X position
    AND #$7F                ; same as AND 01111111, forces bit 7 to zero. Keep the result positive
    
    STA WSYNC               ; wait fot the next scanline
    STA HMCLR               ; clear old horizontal position values

    SEC                     ; setting the carry before subtraction

DivideLoop:
    SBC #15                 ; A -= 15
    BCS DivideLoop          ; loop while ( C[arry] != 0 )

    EOR #7                  ; adjust the remainder in A between -8 and 7

    REPEAT 4
        ASL                 ; shift left by 4, as HMP0 uses only 4 bits
    REPEND

    STA HMP0                ; set fine position
    STA RESP0               ; reset 15-step brute position
    STA WSYNC               ; wait for the next scanline
    STA HMOVE               ; apply the fine position offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Generate the TIA output of 37 lines of VBLANK       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 35               ; 35 because we already called 2 WSYNC above
        STA WSYNC
    REPEND

    LDA #0
    STA VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Rendering the scene                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 160
        STA WSYNC
    REPEND

    LDY #17                  ; counter to draw 8 rows of bitmap

DrawBitmap:
    LDA P0Bitmap,Y          ; load player bitmap slice of data
    STA GRP0                ; set graphics for player 0 slice
   
    LDA P0Color,Y           ; load player colo from lookup table
    STA COLUP0

    STA WSYNC               ; wait fot the next scanline

    DEY
    BNE DrawBitmap          ; repeat next scanline until finished

    LDA #0
    STA GRP0                ; disable P0 bitmap graphics

    LDA #$FF                ; enable grass playfield
    STA PF0
    STA PF1
    STA PF2

    REPEAT 15
        STA WSYNC           ; wait for remaining 124 empty scanlines
    REPEND

    LDA #0                  ; disable grass playfield
    STA PF0
    STA PF1
    STA PF2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Output 30 more VBLANK scanlines to complete the frame   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Overscan:
    LDA #2
    STA VBLANK

    REPEAT 30
        STA WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Check Joystick input                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckP0Up:
    LDA #%00010000
    BIT SWCHA
    BNE CheckP0Down
    INC P0XPos

CheckP0Down:
    LDA #%00100000
    BIT SWCHA
    BNE CheckP0Left
    DEC P0XPos

CheckP0Left:
    LDA #%01000000
    BIT SWCHA
    BNE CheckP0Right
    DEC P0XPos

CheckP0Right:
    LDA #%10000000
    BIT SWCHA
    BNE NoInput
    INC P0XPos

NoInput:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Loop to next frame                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    JMP StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                Look up tables for sprites                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Bitmap:
    byte #%00000000
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00011100
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01111111
    byte #%00111110
    byte #%00010000
    byte #%00011100
    byte #%00011100
    byte #%00011100   

P0Color:
    byte #$00
    byte #$F6
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$3E
    byte #$3E
    byte #$3E
    byte #$24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Complete ROM                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC
    .word Reset
    .word Reset
