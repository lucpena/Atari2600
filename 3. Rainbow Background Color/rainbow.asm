;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This program prints colors in the screen, like a raingow ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    include "vcs.h"
    include "macro.h"

    SEG code
    ORG $F000
    
Start:
    CLEAN_START             ; macro to safely clear memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;   Start a new frame by turning on VBLANK and VSYNc   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

NextFrame:
    LDA #2                  ; same as binary value %00000010
    STA VBLANK              ; turn on VBLANK
    STA VSYNC               ; turn on VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;          Generate the 3 lines of VSYNC               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    STA WSYNC               ; first scan line
    STA WSYNC               ; second scan line
    STA WSYNC               ; third scan line

    LDA #0
    STA VSYNC               ; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;          Output the 37 scanlines of VBLANK           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    LDX #37                 ; X = 37, counter for WSYNC

LoopVBlank:
    STA WSYNC               ; hit WSYNC and wait for the next scanline
    DEX                     ; X--
    BNE LoopVBlank          ; loop while (X != 0)

    LDA #0
    STA VBLANK              ; turn of VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;   Draw 192 visible scanlines (kernel of the render)  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    LDX #192                ; X = 192, counter for the visivle scanlines

LoopScanLines:
    STX COLUBK              ; set the background color
    STA WSYNC               ; wait for the nect line
    DEX                     ; X--
    BNE LoopScanLines       ; loop while X != 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;     Output the 30 overscan VBLANK in the bottom      ;;
;;               to complete frame                      ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    LDA #2                  ; hit and turn on VBLANK
    STA VBLANK

    LDX #30                 ; counter for 30 scanlines

LoopOverscan:
    STA WSYNC               ; wait fot the nexr scanline
    DEX                     ; X--
    BNE LoopOverscan        ; loop while (x != 0)

    JMP NextFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;             Complete ROM size to 4KB                 ;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

    ORG $FFFC               ; defines origin to $FFFC
    .word Start
    .word Start 