macro mov reg1, reg2: { or reg1, z, reg2; }

accept r13: 280h   \ first operand
accept r14: 07c8h   \ second operand
accept r15: 0      \ result
accept r7: 0       \ buffer
accept r8: 0       \ buffer
accept r9: 0       \ buffer

link l1: ct

\ forming result's sign
{ and r7, r13, 8000h; } \ r7[15] := 1st argument's sign
{ and r8, r14, 8000h; } \ r8[15] := 2nd argument's sign
{ xor r7, r8; }
{ mov r15, r7; }        \ r15[15] := result's sign

\ orders' addition
{ and r7, r13, 7f00h; } \ r7[14-8] := 1st argument's order
{ and r8, r14, 7f00h; } \ r8[14-8] := 2nd argument's order
{ add r7, r8; }
{ or r15, r7; }         \ r15[14-8] := result's order

\ mantissas' multiplication
{ and r7, r13, 0ffh; }  \ r7[7-0] := 1st argument's mantissa
{ and r8, r14, 0ffh; }  \ r8[7-0] := 2nd argument's mantissa
{ push nz, 7; }
{ or sla, r8, 0; }
{ rfct; }               \ r8[15-8] := 2nd argument's mantissa
{ xor r9, r9; }
{ push nz, 6; }
{ or nil, r8, 7fffh; load rn, flags; }
{ cjp not rn_n, multip; }
{ add r9, r7; }         \ if Y[15] = 1, Z := Z+X
multip {}
{ or sll, r9, 0; }      \ Z := 2Z
{ or sll, r8, 0; }      \ Y := 2Y
{ rfct; }
{ push nz, 7; }
{ or srl, r9, 0; }
{ rfct; }               \ r9[7-0] := result's mantissa

\ mantissa's normalization
{ xor r7, r7; }
{ xor r8, r8; }
normaliz {}
{ and nil, r9, 80h; load rn, flags; }
{ cjp not rn_z, finally; }
{ add r8, 1; }          \ +1 order's error, if r9[7] = 0
{ or sll, r9, 0; }      \ r9 := r9 * 2
{ cjp nz, normaliz; }
finally {}
{ push nz, 7; }
{ or sll, r8, 0; }
{ rfct; }               \ r8[15-8] := mantissa's error
{ sub r15, r8, nz; }    \ r15[14-8] := corrected result's order
{ or r15, r9; }
 
{ load rn, flags; }
end {}
