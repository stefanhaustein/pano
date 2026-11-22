; agonkey.asm - Read Agon VDP sysvar_vkeycode and sysvar_keyascii as one 16-bit word

sysvar_vkeycode EQU 17h

; function AgonReadKey: Integer; register; external '__agon_readkey';
; Waits for a key-down event, clears sysvar_vkeydown, and returns:
;   H = sysvar_vkeycode, L = sysvar_keyascii
__agon_readkey:
        push    ix
        ld      a, 8
        rst     08h                     ; IX(U) = MOS sysvars
__agon_rk_wait:
        mklil
        ld      a, (ix + sysvar_vkeydown)
        or      a
        jr      z, __agon_rk_wait
        mklil
        ld      h, (ix + sysvar_vkeycode)
        mklil
        ld      l, (ix + sysvar_keyascii)
        xor     a
        mklil
        ld      (ix + sysvar_vkeydown), a
        pop     ix
        ret
