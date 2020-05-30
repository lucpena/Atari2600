;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;               This program is a bomber game              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502              ; Atari 2600 processor

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       Declaring the variables starting from $80          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SEG.U Variables
    ORG $80

JetXPos         byte            ; player 0 x-postition
JetYPos         byte            ; player 0 y-position
BomberXPos      byte            ; plater 1 x-position
BomberYPos      byte            ; player 1 y-position
MissileXPos     byte            ; missile x-position
MissileYPos     byte            ; missile y-position
JetAnimOffset   byte            ; player 0 sprite frame offset for animation
Random          byte            ; receiver of the random number generated
Score           byte            ; 2-digit score stored as BCD
Timer           byte            ; 2-digit timer stored as BCD
Temp            byte            ; temporary variable
ScoreSprite     byte            ; store the sprite bit pattern for the Score
TimerSprite     byte            ; store the sprite bit pattenr for the Timer
TerrainColor    byte            ; store the color of the terrain
RiverColor      byte            ; srote the color of the river

OnesDigitOffset word            ; lookup table offset for the first digit
TensDigitOffset word            ; lookup table offset fot the second digit

; Pointers
JetSpritePtr    word            ; pointer to player 0 sprite 
JetColorPtr     word            ; pointer to player 0 color
BomberSpritePtr word            ; pointer to player 1 sprite
BomberColorPtr  word            ; pointer to player 1 color

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Define constants                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; These Heights are the number of rows of the sprite in the lookup table
JET_HEIGHT = 9
BOMBER_HEIGHT = 9
DIGITS_HEIGHT = 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Start the ROM at $F000                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    SEG Code
    ORG $F000

Reset:
    CLEAN_START                 ; "macro.h" function to clean memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;           RAM variables and TIA registers                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #68
    STA JetXPos                 ; JetXpos = 68

    LDA #10
    STA JetYPos                 ; JetYPos = 10

    LDA #62
    STA BomberXPos              ; BomberXPos = 62

    LDA #83
    STA BomberYPos              ; BomberYPos = 83

    LDA #%11010100
    STA Random                  ; Random = $D4

    LDA #0
    STA Score                   ; Score = 0
    STA Timer                   ; Timer = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   DRAW_MISSILE macro                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MAC DRAW_MISSILE
        LDA #%00000000
        CPX MissileYPos         ; compare X with missile y-pos
        BNE .SkipMissileDraw
.DrawMissile 
        LDA #%00000010          ; enable missile 0 display
        INC MissileYPos
        ;INC MissileYPos
.SkipMissileDraw
        STA ENAM0               ; store the value in the TIA register
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Initialize the pointers                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Remember: they are LITTLE ENDIANDS
    LDA #<JetSprite
    STA JetSpritePtr            ; store the lo-byte 
    LDA #>JetSprite
    STA JetSpritePtr+1          ; store the hi-byte

    LDA #<JetColor
    STA JetColorPtr             ; store the lo-byte
    LDA #>JetColor
    STA JetColorPtr+1           ; store the hi-byte

    LDA #<BomberSprite
    STA BomberSpritePtr         ; store lo-byte
    LDA #>BomberSprite
    STA BomberSpritePtr+1       ; store hi-byte

    LDA #<BomberColor
    STA BomberColorPtr          ; store lo-byte
    LDA #>BomberColor
    STA BomberColorPtr+1        ; store hi-byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;           Main display loop and frame rendering          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                Display VSYNC and VBLANK                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #2
    STA VBLANK                  ; VBLANK turned ON
    STA VSYNC                   ; VSYNC turned ON

    REPEAT 3
        STA WSYNC               ; 3 lines of VSYNC
    REPEND

    LDA #0
    STA VSYNC                   ; VSYNC turned OFF

    REPEAT 31
        STA WSYNC               ; 31 lines of VBLANK
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                    VBLANK calculations                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA JetXPos
    LDY #0
    JSR SetObjectXPos           ; set player 0 Horizontal Position

    LDA BomberXPos
    LDY #1
    JSR SetObjectXPos           ; set player 1 Horizontal Position

    LDA MissileXPos
    LDY #2
    JSR SetObjectXPos           ; set missile horizontal position

    JSR CalculateDigitOffset    ; calculate scoreboard digits lookup table

    JSR GenerateJetSound        ; configure and enable Jet Engine Sound

    JSR GenerateMissileSound    ; configure and enable missile sound

    STA WSYNC
    STA HMOVE                   ; apply the horizontal offsets previously set

    LDA #0
    STA VBLANK                  ; VBLANK turned OFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                  Display the scoreboard                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #0                      ; clear TIA registers before each frame
    STA PF0
    STA PF1
    STA PF2
    STA GRP0
    STA GRP1
    STA CTRLPF
    STA COLUBK                  ; all = 0

    LDA #$1E
    STA COLUPF                  ; set Scoreboard and Playfield to White

    LDX #DIGITS_HEIGHT          ; X = 5

.ScoreDigitLoop:
    LDY TensDigitOffset         ; get the tens digit offset for score
    LDA Digits,Y                ; load the bit pattern from lookup table
    AND #$F0                    ; mask to remove the graphics for the ones digit
    STA ScoreSprite             ; save the score tens digit pattern in a variable
    LDY OnesDigitOffset         ; get the ones digit offset for the score
    LDA Digits,Y                ; load the digit bit pattern from lookup table
    AND #$0F                    ; mask to remove the graphics for the tens digit
    ORA ScoreSprite             ; merge it with the saved tens digit sprite
    STA ScoreSprite             ; save it
    STA WSYNC                   ; wait fot the end of scanline
    STA PF1                     ; update the playfield to display the Score Sprite

    LDY TensDigitOffset+1       ; get the left digit offset for the Timer
    LDA Digits,Y                ; load the digit pattern from the lookup table
    AND #$F0                    ; mask to remove the graphics for the ones digits
    STA TimerSprite             ; save the timer tens digit pattern in a variable
    LDY OnesDigitOffset+1       ; get the digits offset for the timer
    LDA Digits,Y                ; load digit pattern from the lookup table
    AND #$0F                    ; mask to remove the graphics for the tens digits
    ORA TimerSprite             ; merge with the saved tens digits graphics
    STA TimerSprite             ; save it

    JSR Sleep12Cycles           ; sleep for 12 cycles, waiting for the bean

    STA PF1                     ; update the playfield for Timer display
    LDY ScoreSprite             ; preload fot the next scanline
    STA WSYNC                   ; wait for the next scanline
    
    STY PF1                     ; update playfield for the score display
    INC TensDigitOffset
    INC TensDigitOffset+1
    INC OnesDigitOffset
    INC OnesDigitOffset+1       ; increment all digits for the next line

    JSR Sleep12Cycles           ; sleep for 12 cycles, waiting for the bean

    DEX                         ; X--
    STA PF1                     ; update the playfield for the Timer display
    BNE .ScoreDigitLoop         ; if (DEX != 0), then branch

    STA WSYNC
    
    LDA #0
    STA PF0
    STA PF1
    STA PF2

    STA WSYNC
    STA WSYNC
    STA WSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Display the (192 - 20)/2(-line kernel) = 84  scanlines  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Scene:
    LDA TerrainColor            ; 
    STA COLUPF                  ; set the terrain color

    LDA RiverColor
    STA COLUBK                  ; set the river color

    LDA #%00000001
    STA CTRLPF                  ; set the reflection of the playfield to ON

    LDA #$F0
    STA PF0                     ; setting PF0 pattern

    LDA #$FC
    STA PF1                     ; setting PF1 pattern

    LDA #0
    STA PF2                     ; setting PF2 pattern

    LDX #89                     ; scanlines to render

.GameLineLoop:
    DRAW_MISSILE                ; macro to check if we should draw the missile

.AreWeInsideJetSprite:
    TXA                         ; X -> A
    SEC                         ; set carry for subtraction
    SBC JetYPos                 ; subtract sprite Y-coordination
    CMP #JET_HEIGHT             ; are we inside the sprite height bounds?
    BCC .DrawSpriteP0           ; if result < SpriteHeight, draw the sprite
    LDA #0                      ; else, set index to 0

.DrawSpriteP0:
    CLC                         ; clear carry flag before addition
    ADC JetAnimOffset           ; jump to correct sprite frame address in memory

    TAY                         ; A -> Y
                                ; Y is the only register that handles indirect addressing
    LDA (JetSpritePtr),Y        ; load the player0 Bitmap
    STA WSYNC                   ; wait for scanline
    STA GRP0                    ; set graphics to player0
    LDA (JetColorPtr),Y         ; load player color from lookup table
    STA COLUP0                  ; set the player0 color

; Same for the bomber!
.AreWeInsideBomberSprite:
    TXA
    SEC
    SBC BomberYPos
    CMP #BOMBER_HEIGHT
    BCC .DrawSpriteP1
    LDA #0

.DrawSpriteP1:
    TAY

    LDA #%00000101
    STA NUSIZ1                  ; strech player 1 sprite

    LDA (BomberSpritePtr),Y
    STA WSYNC
    STA GRP1
    LDA (BomberColorPtr),Y
    STA COLUP1

    DEX                         ; X--
    BNE .GameLineLoop           ; loop while (x != 0)

    ; keep the Jet in the IDLE animation when IDLE
    LDA #0
    STA JetAnimOffset           ; ressets the player 0 bitmap

    STA WSYNC               ; 30 lines of VBLANK Overscan


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                     Display Overscan                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #2
    STA VBLANK                  ; VBLANK turned ON

    REPEAT 30
        STA WSYNC               ; 30 lines of VBLANK Overscan
    REPEND

    LDA #0
    STA VBLANK                  ; VBLANK turned OFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Joystick Input                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckP0UP:
    LDA #%00010000              ; player0 Joystick UP
    BIT SWCHA
    BNE CheckP0Down             ; if the pattern does not match
    LDA JetYPos
    CMP #70
    BPL CheckP0Down             ; check player position to avoid getting out of the map
.P0UpPressed:  
    INC JetYPos
    LDA #0
    STA JetAnimOffset           ; ressets the player 0 bitmap

CheckP0Down:
    LDA #%00100000               ; player0 Joystick Down
    BIT SWCHA
    BNE CheckP0Left
    LDA JetYPos
    CMP #5
    BMI CheckP0Left             ; check player position to avoid getting out of the map

.P0DownPressed:   
    DEC JetYPos
    LDA #0
    STA JetAnimOffset           ; ressets the player 0 bitmap

CheckP0Left:
    LDA #%01000000              ; player0 Joystick Left
    BIT SWCHA
    BNE CheckP0Right
    LDA JetXPos
    CMP #35
    BMI CheckP0Right             ; check player position to avoid getting out of the map

.P0LeftPressed:
    DEC JetXPos
    LDA #JET_HEIGHT
    STA JetAnimOffset           ; set animation offset to the player 0

CheckP0Right:
    LDA #%10000000              ; player0 Joystick Right
    BIT SWCHA
    BNE CheckButtonPressed
    LDA JetXPos
    CMP #100
    BPL CheckButtonPressed      ; check player position to avoid getting out of the map

.P0RightPressed:    
    INC JetXPos
    LDA JET_HEIGHT
    STA JetAnimOffset           ; set animation offset to the player 0

CheckButtonPressed:
    LDA #%10000000
    BIT INPT4                   ; if the button is pressed
    BNE NoInput

.ButtonPressed: 
    LDA #1
    STA AUDV1
    LDA JetXPos
    CLC
    ADC #5                      ; set missile to the center of the player
    STA MissileXPos

    LDA JetYPos
    CLC
    ADC #7                      ; set missile to the center of the player
    STA MissileYPos             ; set missile to the player position

NoInput:                        ; fallback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;            Calculations to update position.              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateBomberPosition:
    LDA BomberYPos
    CLC
    CMP #0                      ; comparing BomberYPos with Zero
    BMI .ResetBomberPosition    ; if BomberYPos < Zero, reset Y-Position
    DEC BomberYPos              ; else, decrement BomberYPos
    JMP EndPositionUpdate

.ResetBomberPosition
    JSR GetRandomBomberPos      ; call subroutine for random BomberXPos

.SetScoreValues
    SED                         ; activate Decimal Mode

    LDA Timer
    CLC
    ADC #1
    STA Timer                   ; add 1 to Timer (BCD does not like INC)

    CLD                         ; deactivate Decimal Mode


EndPositionUpdate:              ; fallback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                   Check for collisions                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckCollisionP0P1:
    LDA #%10000000              ; CXPPMM bit 7 detects P0 and P1 collision
    BIT CXPPMM                  ; check CXPPMM bit 7 with the above pattern
    BNE .CollisionP0P1          ; collision between P0 and P1 detected
    JSR SetTerrainRiverColor    ; else, set playfield color to the standart
    JMP CheckCollisionM0P1       ; jump if no collision were detected
.CollisionP0P1:
    JSR GameOver                ; call Game Over subroutine

CheckCollisionM0P1:
    LDA #%10000000              ; CXM0P bit 7 detects Missile 0 and Player 1 collision
    BIT CXM0P                   ; check CXM0P bit 7 with the above pattern
    BNE .CollisionM0P1          ; collision detected
    JMP EndCollisionCheck
.CollisionM0P1
    SED                         ; activate Decimal Mode
    LDA Score                   ; loads Score to the Acumulator
    CLC                         ; clear Carry Flag for sum
    ADC #1                      ; adds 1 to the score
    STA Score                   ; save the new value
    CLD                         ; deactivate Decimal Mode
    LDA #0
    STA MissileYPos             ; ressets the missile position
    JSR GetRandomBomberPos      
    LDA #83
    STA BomberYPos              ; ressets bomber position


    LDA #4
    STA AUDV1
    LDA #5
    STA AUDF1
    LDA #8
    STA AUDC1                   ; explosion sound

    LDA #0
    STA AUDV1                   ; silence missle

EndCollisionCheck:              ; fallback
    STA CXCLR                   ; clear all collisions flag
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  End of game loop frame. Returns to create a new frame   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    JMP StartFrame              ; go to StartFrame, rendering a new frame
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                Missle Sounds subroutine                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GenerateMissileSound subroutine

    LDA MissileYPos
    LSR
    LSR
    LSR
    STA Temp
    ADC #2                      ; start offset for the frequency
    INC Temp
    STA AUDF1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      TONE TYPE TABLE                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0, 11 -> Silence                                          ;;
;; 1, 7, 9, 15 -> Buzz                                       ;;
;; 2, 3 -> Rumble                                            ;;
;; 4, 5, 12, 13 ->Pure Tone                                  ;;
;; 6, 10, 14 -> Square Wave                                  ;;
;; 8 -> White Noise                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #8
    STA AUDC1

    LDA MissileYPos
    CMP #80
    BPL MissileNoSound
    RTS

MissileNoSound subroutine
    LDA #0
    STA AUDV1                 
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                    Jet Sounds subroutine                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GenerateJetSound subroutine
    LDA #1
    STA AUDV0                   ; sets the audio volume

    LDA JetYPos
    LSR                         ; divide the Y pos by 8
    LSR                         ; so we can use the position
    LSR                         ; to generate the Engine sound
    STA Temp
    LDA #29
    SEC
    SBC Temp                    ; subtract
    CLC
    STA AUDF0                   ; sets the frequency

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      TONE TYPE TABLE                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 0, 11 -> Silence                                          ;;
;; 1, 7, 9, 15 -> Buzz                                       ;;
;; 2, 3 -> Rumble                                            ;;
;; 4, 5, 12, 13 ->Pure Tone                                  ;;
;; 6, 10, 14 -> Square Wave                                  ;;
;; 8 -> White Noise                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #8
    STA AUDC0                   ; sets the Tone Type

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 Set colors subroutine                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetTerrainRiverColor subroutine
    LDA #$C2
    STA TerrainColor            ; set terrain color
    LDA #$84
    STA RiverColor              ; set river color
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle horizontal position with fine offset ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target X-coordinate position in pixels of object ;;
;; Y is the Object type, it can be:                          ;;
;; 0 -> Player 0                                             ;;
;; 1 -> Player 1                                             ;;
;; 2 -> Missile 0                                            ;;
;; 3 -> Missile 1                                            ;;
;; 4 -> Ball                                                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetObjectXPos   subroutine
    STA WSYNC                   ; start scanline
    SEC                         ; set carry for subtraction

.Div15Loop
    SBC #15                     ; subtract 15 from acumulator
    BCS .Div15Loop              ; loop until carry-flag is clear
    EOR #7                      ; handle offset range from -8 to 7
    ASL
    ASL
    ASL
    ASL                         ; 4 left shifts to get only the top 4 bits
    STA HMP0,Y                  ; store the fine offset to the correct HMxx
    STA RESP0,Y                 ; fix object position in 15-step increment
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                    Game Over subroutine                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameOver    subroutine
    LDA #$30
    STA TerrainColor            ; set terrain color to red
    STA RiverColor              ; set terrain color to red
    LDA #0
    STA Score                   ; reset score 

    ; Buzz sound while P0 and P1 are colliding
    LDA #5
    STA AUDF0                   ; sets audio frequency
    LDA #3
    STA AUDV0                   ; sets the audio volume
    LDA #15
    STA AUDC0                   ; sets the Tone Type

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate a Linear-Feedback Shift Register   ;;
;;                    random number                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; - Generate a LFSR random number                           ;;
;; - Divide the random value by 4 to fit the river size      ;;
;; - Add 30 to generate an offset to keep on the river       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRandomBomberPos subroutine
    ; These operations generate a random number
    LDA Random
    ASL
    EOR Random
    ASL
    EOR Random
    ASL
    ASL
    EOR Random
    ASL
    ROL Random

    ; Here we do 2 right shifts to perform the Division by 4
    LSR
    LSR
    STA BomberXPos                  ; save the random number to the BomberXPos

    LDA #30
    ADC BomberXPos                  ; offset 
    STA BomberXPos                  ; finally setting the value desired to BomberXPos

    LDA #96
    STA BomberYPos                  ; set the BomberYPos to the top of the screen

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   Subroutine to handle scoreboard digits to be displayed  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Convert the High and Low nibbles of the variable Score    ;;
;; and Timer into the offsets of digits lookup table so the  ;;
;; values can be displayed. Each digit has a height of 5     ;;
;; bytes in the lookup table                                 ;;
;;                                                           ;;
;;  For the low nibble we need tro multiply by 5             ;;
;;  - We can use left shifts to perform multiplication by 2  ;;
;;  - For any number N, the value of N*5 = (N*2*2) + N       ;;
;;                                                           ;;
;;  For the upper nibble, since it is already times 16, we   ;;
;;  need to divide it and then  multiply by 5:               ;;
;;  - We can use right shifts to perform division by 2       ;;
;;  - For any number N: (N/16) * 5 = (N/2/2)+(N/2/2/2/2)     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalculateDigitOffset subroutine
    LDX #1                          ; loop counter

.PrepareScoreLoop                   ; 2 Loops with X = 1 and X = 0
    LDA Score,X                     ; load A with Timer (X=1) or Score (X=0)
    AND #$0F                        ; mask to get only the 4 first digits (00001111)
    STA Temp                        ; save A to Temp
    ASL                             ; N * 2 (Left Shift)
    ASL                             ; N * 4
    ADC Temp                        ; N + Temp -> N * 5
    STA OnesDigitOffset,X           ; save A in OnesDigitOffset+1 or OnesDigitOffset

    LDA Score,X                     ; load A with Timer (X=1) or Score (X=0)
    AND #$F0                        ; mask to get only the 4 last digits (11110000)
    LSR                             ; N / 2 (Right Shift)
    LSR                             ; N / 4
    STA Temp                        ; save A to Temp
    LSR                             ; N / 8
    LSR                             ; N / 16 
    ADC Temp                        ; N + Temp -> (N / 16) + (n / 4)
    STA TensDigitOffset,X           ; save A in OnesDigitOffset+1 or OnesDigitOffset

    DEX                             ; X--
    BPL .PrepareScoreLoop

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              Subroutine to waste 12 cycles                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  JSR takes 6 Cycles                                       ;;
;;  RTS takes 6 Cycles                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sleep12Cycles subroutine

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 Declare ROM lookup tables                 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Digits:
    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###

    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #

    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %00110011                 ;  ##  ##
    .byte %00010001                 ;   #   #
    .byte %01110111                 ; ### ###

    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #

    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #
    .byte %00010001                 ;   #   #

    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###
    .byte %00010001                 ;   #   #
    .byte %01110111                 ; ### ###

    .byte %00100010                 ;  #   #
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #

    .byte %01110111                 ; ### ###
    .byte %01010101                 ; # # # #
    .byte %01100110                 ; ##  ##
    .byte %01010101                 ; # # # #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01000100                 ; #   #
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###

    .byte %01100110                 ; ##  ##
    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #
    .byte %01010101                 ; # # # #
    .byte %01100110                 ; ##  ##

    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01110111                 ; ### ###

    .byte %01110111                 ; ### ###
    .byte %01000100                 ; #   #
    .byte %01100110                 ; ##  ##
    .byte %01000100                 ; #   #
    .byte %01000100                 ; #   #

JetSprite:  
    .byte #%00000000                ;
    .byte #%00010100                ;   # #
    .byte #%01111111                ; #######
    .byte #%00111110                ;  #####
    .byte #%00011100                ;   ###
    .byte #%00011100                ;   ###
    .byte #%00001000                ;    #
    .byte #%00001000                ;    #
    .byte #%00001000                ;    #

; You can declare the JET_HEIGHT here too, with the following instruction:
;   
;               JET_HEIGHT = . - JetSprite
;   
; (The . means the current location in the memory)

JetSpriteTurn:  
    .byte #%00000000                ;
    .byte #%00001000                ;    #
    .byte #%00111110                ;  #####
    .byte #%00011100                ;   ###
    .byte #%00011100                ;   ###
    .byte #%00011100                ;   ###
    .byte #%00001000                ;    #
    .byte #%00001000                ;    #
    .byte #%00001000                ;    #

BomberSprite:       
    .byte #%00000000                ;
    .byte #%00001000                ;    #
    .byte #%00001000                ;    #
    .byte #%00101010                ;  # # #
    .byte #%00111110                ;  #####
    .byte #%01111111                ; #######
    .byte #%00101010                ;  # # #
    .byte #%00001000                ;    #
    .byte #%00011100                ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;           Complete ROM size with exactly 4KB             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC
    .word Reset                 ; write 2 bytes with the reset address
    .word Reset                 ; write 2 bytes with the interruption vector
