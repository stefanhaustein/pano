; scrchar.asm - Read character at 0-based (X, Y) from Agon VDP via VDU 23,0,&83

sysvar_scrchar EQU 09h

; function ScrChar(X, Y: Integer): Char; register; external '__scrchar';
; Entry: HL = X (0-based col), DE = Y (0-based row)
; Exit:  L  = ASCII character (H = 0)
__scrchar:
        push    ix
        ld      a, 8
        rst     08h                     ; IX(U) = MOS sysvars
        mklil
        res     1, (ix + sysvar_vpd_pflags) ; vdp_pflag_scrchar = bit 1
        ld      a, 23
        rst     10h
        xor     a
        rst     10h
        ld      a, 083h
        rst     10h
        ld      a, l
        rst     10h
        ld      a, h
        rst     10h
        ld      a, e
        rst     10h
        ld      a, d
        rst     10h
__scrchar_wait:
        mklil
        bit     1, (ix + sysvar_vpd_pflags)
        jr      z, __scrchar_wait
        mklil
        ld      l, (ix + sysvar_scrchar)
        ld      h, 0
        pop     ix
        ret
