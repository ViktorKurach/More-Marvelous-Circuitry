macro mov reg1, reg2: { or reg1, z, reg2; }

accept r13: 0c8h   \ argument
accept r15: 0      \ result
accept r14: 0      \ argument in direct code
accept r7: 0       \ order
accept r8: 0       \ buffer
accept r9: 0       \ count

link l1: ct

{ or nil, r13, 0; load rn, flags; }
{ cjp rn_z, final; } \ if argument = 0, go to end

\ transforming argument to direct code 
{ or nil, r13, 0; load rn, flags; }
{ cjp not rn_n, positive; }
{ mov r14, 8000h; }  \ r14 := 1000 0000 0000 0000
{ mov r8, r13; }     \ r8 := argument
{ xor r8, 0ffffh; }  \ r8 := not r8
{ add r8, 1; }       \ r8 := r8 + 1
{ or r14, r8; }      \ r14 := - r8
{ cjp nz, negative; }
positive {}
{ mov r14, r13; }
negative {}

\ writing down result's sign
{ mov r15, r14; }
{ and r15, 8000h; }  \ r15[15] := result's sign

\ calculating result's order
{ mov r8, r14; }
{ and r8, 7fffh; }   \ r8 := (r14 < 0) ? -r14 : r14
{ mov r9, 10h; }
{ push; }            \ sla buffer, until 1 in senior level detected
{ sub r9, 0; }
{ loop no; or sla, r8, 0; }
{ add r7, r9, nz; }  \ r7 := result's order
{ mov r8, r7; }
{ push nz, 7; }
{ or sla, r8, 0; }   \ buffer := sla order (8 times)
{ rfct; }
{ or r15, r8; }      \ r15[13-8] := buffer

\ calculating result's mantissa
{ mov r8, r14; }
{ and r8, 7fffh; }   \ r8 := (r14 < 0) ? -r14 : r14
{ mov r9, r7; }
{ and nil, r9, 0fff8h; load rn, flags; }
{ cjp rn_z, onebyte; }
{ sub r9, 8, nz; load rn, flags; }
{ cjp rn_z, eightlev; }
{ push; }
{ or srl, r8, 0; }   \ if order > 8, srl buffer (order-8) times
{ loop nz; sub r9, 0; }
{ cjp nz, final; }
eightlev {}
{ and r8, 0ffh; }    \ if order = 8, r8 := 0000 0000 [mantissa]
{ cjp nz, final; }
onebyte {}
{ sub r9, 8, r9, nz; }
{ push; }
{ or sll, r8, 0; }   \ if order < 8, sll buffer (8-order) times
{ loop zo; sub r9, 0; }
final {}
{ or r15, r8; }       \ r15[7-0] := buffer

{ load rn, flags; }
end {}
{ or nil, r5, z; oey; ewl; } \ RgA := 0000 REGx
