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

    LDX #$88
    STX COLUBK              ; black background

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Initialize variables                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #50
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

    REPEAT 35               ; 35 becouse we already called 2 WSYNC abovo
        STA WSYNC
    REPEND

    LDA #0
    STA VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Rendering the scene                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 60
        STA WSYNC
    REPEND

    LDY #8                  ; counter to draw 8 rows of bitmap

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

    REPEAT 124
        STA WSYNC           ; wait for remaining 124 empty scanlines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Output 30 more VBLANK scanlines to complete the frame   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Overscan:
    LDA #2
    STA VBLANK

    REPEAT 30
        STA WSYNC
    REPEND

    LDA #0
    STA VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Animating the Player                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA P0XPos
    CMP #80
    BPL ResetXPos           ; iF A > 80, ressets position to X = 80
    JMP IncrmXPos

ResetXPos:
    LDA #40
    STA P0XPos              ; reset player to position X = 40

IncrmXPos:
    INC P0XPos


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Loop to next frame                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    JMP StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                Look up tables for sprites                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Bitmap:
    byte #%00000000   
    byte #%00101000   
    byte #%01110100   
    byte #%11111010   
    byte #%11111010   
    byte #%11111010    
    byte #%11111110   
    byte #%01101100   
    byte #%00110000   

P0Color:
    byte #$00   
    byte #$40   
    byte #$40   
    byte #$40   
    byte #$40   
    byte #$42   
    byte #$42   
    byte #$44   
    byte #$D2    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Complete ROM                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC
    .word Reset
    .word Reset