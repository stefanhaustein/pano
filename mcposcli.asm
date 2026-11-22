; mcposcli.asm - Call mos_oscli from a MOSlet safely for both ADL=0 and ADL=1 children:
; 1. Sets MB=0 in ADL=1 so ADL=1 children (e.g. ez80asm.bin) do not inherit MB=$0B
;    into mos_fopen's _SET_AHL24 address promotion.
; 2. Sets SPS=0000h during mos_oscli (matching MOS boot state) so MOS exec16's
;    CALL.SIS $0000 pushes its 2-byte return address at $04:FFFE (top of segment)
;    instead of clobbering 2 bytes of the child binary at $04:<moslet_SPS>.

__mcp_oscli:
        ex      de, hl
        ld      hl, 0
        add     hl, sp
        ex      de, hl                  ; DE = caller SPS, HL = CmdAddr
        ldamb
        ld      (__oscli_hi), a
        ld      c, a
        mklil
        push    hl
        mklil
        ld      hl, 2
        db      0
        mklil
        add     hl, sp
        mklil
        ld      (hl), a
        mklil
        pop     hl
        db      5Bh, 0CDh               ; CALL.LIL __oscli_adl1
        dw      __oscli_adl1
__oscli_hi:
        db      0Bh
        ret

__oscli_adl1:
        push    bc
        push    de
        db      40h, 31h, 00h, 00h      ; LD.SIS SP, 0000h
        xor     a
        ldmba
        ld      a, 10h
        mklil
        rst     08h
        pop     hl
        db      40h, 0F9h               ; LD.SIS SP, HL
        pop     bc
        push    af
        ld      a, c
        ldmba
        pop     af
        ld      l, a
        ld      h, 0
        mklis
        ret
