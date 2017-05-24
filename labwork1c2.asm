accept rq: 0fff8h \ RQ := -8
accept r5: 0dh    \ R5 := 13
equ d: 0fffbh     \  D := -5
accept r6: 9      \ R6 := 9

{ sub sla, r2, d, nz; } \ r2 := 2 * (r2 - d)
{ add r2, r5; }         \ r2 := r2 + r5
{ sub sla, r2, d, nz; } \ r2 := 2 * (r2 - d)
{ add r2, rq; }         \ r2 := r2 + rq
{ add sla, r2, r6; }    \ r2 := 2 * (r2 + r6)
{ add r2, r5; }         \ r2 := r2 + r5
{ sub r2, d, nz; }      \ r2 := r2 - d
{ add sla, r2, r6; }    \ r2 := 2 * (r2 + r6)
end {}
