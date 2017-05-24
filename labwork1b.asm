accept poh: 2b0h, 1fh, 0, 42ch, 2dh, 0, 0, 10ch, 6eah, 0, 7ach, 0, 0, 0, 1aah, 0
accept rq: 4d6h
equ d: 1aah

{ add r11, r10, rq, nz; }    \ r11 := r10 + rq + 1
{ add r6, r14, d; }          \  r6 := r14 + d
{ sub sla, r13, r7, d; }     \ r13 := 2 * (r7 - d - 1)
{ sub sra, r0, r4, nz; }     \  r0 := (r0 - r4) / 2
{ sub sla, r3, r1, r3, nz; } \  r3 := 2 * (r1 - r3)
{ sub sra, r9, r8, rq; }     \  r9 := (r8 - rq - 1) / 2
end {}
