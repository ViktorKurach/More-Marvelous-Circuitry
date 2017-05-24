accept rq: 0fh    \ RQ := 15
accept r5: 0fffdh \ R5 := -3
equ d: 0ah        \  D := 10
accept r6: 0ch    \ R6 := 12

{ sub sla, r2, d, nz; } \ r2 := 2 * (r2 - d)
{ add r2, r5; }         \ r2 := r2 + r5
{ sub sla, r2, d, nz; } \ r2 := 2 * (r2 - d)
{ add r2, rq; }         \ r2 := r2 + rq
{ add sla, r2, r6; }    \ r2 := 2 * (r2 + r6)
{ add r2, r5; }         \ r2 := r2 + r5
{ sub r2, d, nz; }      \ r2 := r2 - d
{ add sla, r2, r6; }    \ r2 := 2 * (r2 + r6)
end {}
