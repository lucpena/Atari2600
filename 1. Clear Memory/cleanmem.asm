;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This program clears the memory, setting all values to 0  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    processor 6502

    SEG CODE
    ORG $F000       ; define the code origin at $F000

Start:
    SEI             ; disable interrupts
    CLD             ; disable the BCD decimal math mode
    LDX #$FF        ; loads the X register with #$FF
    TXS             ; transfer X register to S(tack) register

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Clear the Zero Page region ($00 to $ FF)         ;
;     Meaning the entire TIA register space and RAM       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #0          ; A = 0
    LDX #$FF        ; X = #$FF
    STA $FF         ; Clear $FF before loop

MemLoop:
    DEX             ; x--
    STA $0,X        ; store zero register at address $0 + X
    BNE MemLoop     ; loop until X == 0 (z-flag set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;               Fill ROM size to exactly 4KB              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC       ; force a go to the position $FFFC (atari reads here what to do after a reset)
    .word Start     ; reset vector at $FFFC (where program starts)
    .word Start     ; interrupt vector at $FFFE (unused in VCS)
