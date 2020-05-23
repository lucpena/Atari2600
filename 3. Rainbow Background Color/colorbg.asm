    processor 6502
    include "vcs.h"
    include "macro.h"

    SEG code
    ORG $F000           ; defines the origin of the ROM at $F000

Start:
    ;CLEAN_START         ; macro do safely clear the memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           Set background luminosity color to Yellow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LDA #$1E            ; load color Yellow into A (NTSC)
    STA COLUBK          ; store A to BackGroundColor -> $09

    JMP Start           ; repeat from Start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Fill ROM to 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ORG $FFFC           ; defines origin to $FFFC
    .word Start         ; reset vector at $FFFC (program starts address)
    .word Start         ; interrup vector at $FFFE (not used by VCS)