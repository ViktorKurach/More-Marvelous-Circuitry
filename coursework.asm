macro mov reg1, reg2: { or reg1, z, reg2; }

\ Puprosements of BC1 registers:
\ R0 - PSW's address in RAM
\ R1 - PC's address in RAM
\ R2 - operation code
\ R3 - not used
\ R4 - number of REGy register
\ R5 - number of REGx register
\ R6 - PC's value
\ R7, R8 - buffers in subprograms
\ R9 - counter or buffer in subprograms
\ R10 - REGy's value
\ R11 - REGx's value
\ R12 - PSW's value
\ R13 - first argument for subprogram
\ R14 - second argument for subprogram
\ R15 - subprogram's result
\ RQ - not used

accept r0: 0bh      \ PSW's address in RAM
accept rdm_delay: 2 \ RAM's speed

link l1: ct
link l2: rdm        \ notRDM = 0 -> RAM is ready for next loop
link ewh: 16        \ dividing RgA by two parts
link m: 7, 6, 5, 4, 3, 2, 1, 0, z, z, z, z

dw 0h: 100h         \ PC := 100h
dw 1h: 0fffbh       \ first operand's value
dw 2h: 8            \ second operand's value
dw 0bh: 0105h       \ PSW
dw 100h: 0c111h     \ C1 = operation code, 1 = REGx, 1 = REGy
dw 101h: 0c122h     \ C1 = operation code, 2 = REGx, 2 = REGy
dw 102h: 02f12h     \ 2F = operation code, 1 = REGx, 2 = REGy
dw 103h: 0ff22h     \ FF = operation code, 2 = REGx, 2 = REGy

\ SUBROUT1

\ 1) reading PC from RAM
S1 { xor r1, r1; oey; ewh; } \ forming higher levels of RAM addr reg
{ or nil, r1, z; oey; ewl; } \ lower levels
{ xor r6, r6; }
P1 { cjp rdm, P1; r; or r6, bus_d, z; } \ R6 := PC's value

\ 2) reading instruction from RAM
{ or nil, r6, z; oey; ewl; } \ writing PC to RgA
{ xor r4, r4; }
P2 { cjp rdm, P2; r; or r4, bus_d, z; } \ R4 := Assembler instruction

\ 3) instruction unpacking
{ xor r2, r2; }
{ or r2, r4, z; }
{ push nz, 7; }
{ rfct; or sr.0, r2, r2, z; } \ R2 := operation code
{ xor r5, r5; }
{ or r5, r4; }
{ and r4, 0fh; }  \ R4 := 000 REGy
{ and r5, 0f0h; } \ R5 := 00 REGx 0
{ push nz, 3; }
{ rfct; or sr.0, r5, z; } \ R5 := 000 REGx

\ 4) reading operands from RAM
{ or nil, r4, z; oey; ewl; } \ RgA := 0000 REGy
{ xor r10, r10; }
P3 { cjp rdm, P3; r; or r10, bus_d, z; } \ R10 := REGy's value
{ or nil, r5, z; oey; ewl; } \ RgA := 0000 REGx
{ xor r11, r11; }
P4 { cjp rdm, P4; r; or r11, bus_d, z; } \ R11 := REGx's value

\ SUBROUT1 ends

\ 5) go to subprogram
\ operation code = subprogram's address in memory of microinstructions
\ (stored on local bus at this moment)
{ jmap; or nil, r2, z; oey; }

\ SUBROUT2

\ 6) reading PSW from RAM; PSW's address stored in R0
S2 { or nil, r0, z; oey; ewl; } \ RgA := R0 value (PSW's address)
{ xor r12, r12; }
P5 { cjp rdm, P5; r; or r12, bus_d, z; } \ R12 := PSW's value

\ 7) PSW's modification
{ cjp rn_v, D1; }
{ and r12, 0fbffh; } \ overflow flag := 0
{ cjp nz, J1; }
D1 { or r12, 0400h; } \ overflow flag := 1
J1 { cjp rn_c, D2; }
{ and r12, 0fffeh; } \ carry flag := 0
{ cjp nz, J2; }
D2 { or r12, 0001h; } \ carry flag := 1
J2 { cjp rn_n, D3; }
{ and r12, 0feffh; } \ sign flag := 0
{ cjp nz, J3; }
D3 { or r12, 0100h; } \ sign flag := 1
J3 { load rm, flags; and nil, r15, 00ffh; } \ get result's mantissa
{ cjp rm_z, D4; }
{ and r12, 0ffbfh; } \ zero flag := 0 (result != 0)
{ cjp nz, J4; }
D4 { or r12, 0040h; } \ zero flag := 1 (result = 0)

\ write PSW to RAM
J4 { or nil, r0, z; oey; ewl; } \ forming lower levels of RgA
RR1 { cjp rdm, RR1; w; or nil, r12, z; oey; }

\ write result to RAM; result is written to REGx which address is in R5
{ or nil, r5, z; oey; ewl; } \ forming lower levels of RgA
RR2 { cjp rdm, RR2; w; or nil, r15, z; oey; }

\ 8) PC modification (stored in R6; PC's address stored in R1)
{ add r6, 1; } \ PC := PC + 1
{ or nil, r1, z; oey; ewl; } \ RgA := 00000
RR3 { cjp rdm, RR3; w; or nil, r6, z; oey; } \ writing PC to RAM

{ cjp nz, S1; }

\ SUBROUT2 ends

org 0c10h
\ MCCONV

\ initial installations
{ mov r13, r11; }   \ r13 := argument
{ xor r14, r14; }   \ for result in direct code
{ xor r15, r15; }   \ for result in REAL format
{ xor r7, r7; }     \ for result's order
{ xor r8, r8; }     \ for buffer
{ xor r9, r9; }     \ for counter

{ or nil, r13, 0; load rn, flags; }
{ cjp rn_z, C5; }    \ if argument = 0, go to end

\ 1) transforming argument to direct code
{ or nil, r13, 0; load rn, flags; }
{ cjp not rn_n, C1; }
{ mov r14, 8000h; }  \ r14 := 1000 0000 0000 0000
{ mov r8, r13; }     \ r8 := argument
{ xor r8, 0ffffh; }  \ r8 := not r8
{ add r8, 1; }       \ r8 := r8 + 1
{ or r14, r8; }      \ r14 := - r8
{ cjp nz, C2; }
C1 { mov r14, r13; }

\ 2) writing down result's sign
C2 { mov r15, r14; }
{ and r15, 8000h; }  \ r15[15] := result's sign

\ 3) calculating result's order
{ mov r8, r14; }
{ and r8, 7fffh; }   \ r8 := (r14 < 0) ? -r14 : r14
{ mov r9, 10h; }
{ push; }            \ sla buffer, until 1 in senior level detected
{ sub r9, 0; }
{ loop no; or sla, r8, 0; }
{ add r7, r9, nz; }  \ r7 := result's order
{ mov r8, r7; }
{ push nz, 7; }
{ rfct; or sla, r8, 0; } \ buffer := sla order (8 times)
{ or r15, r8; }      \ r15[13-8] := buffer

\ 4) calculating result's mantissa
{ mov r8, r14; }
{ and r8, 7fffh; }   \ r8 := (r14 < 0) ? -r14 : r14
{ mov r9, r7; }
{ and nil, r9, 0fff8h; load rn, flags; }
{ cjp rn_z, C4; }
{ sub r9, 8, nz; load rn, flags; }
{ cjp rn_z, C3; }
{ push; }
{ or srl, r8, 0; }   \ if order > 8, srl buffer (order-8) times
{ loop nz; sub r9, 0; }
{ cjp nz, C5; }
C3 { and r8, 0ffh; } \ if order = 8, r8 := 0000 0000 [mantissa]
{ cjp nz, C5; }
C4 { sub r9, 8, r9, nz; }
{ push; }
{ or sll, r8, 0; }   \ if order < 8, sll buffer (8-order) times
{ loop zo; sub r9, 0; }
C5 { or r15, r8; load rn, flags; }

\ back to main program
{ cjp nz, S2; }

\ MCCONV ends

org 02f0h
\ MCSUBF

\ initial installations
{ mov r13, r11; }  \ first operand
{ mov r14, r10; }  \ second operand
{ xor r15, r15; }  \ result
{ xor r7, r7; }    \ buffer
{ xor r8, r8; }    \ buffer
{ xor r9, r9; }    \ buffer

\ 1) orders' alignment
{ and r7, r13, 3f00h; }    \ r7 := 1st op order
{ and r8, r14, 3f00h; }    \ r8 := 2nd op order
{ sub nil, r7, r8, nz; load rn, flags; }
{ cjp not rn_n, M1; }      \ if r7 >= r8, goto M1
{ and r9, r13, 0ffh; }     \ r9 := 1st op mantissa
{ push; }
{ add r7, 100h; }
{ and r13, 0c0ffh; }
{ or r13, r7; }            \ +1 to 1st op order
{ or sra, r9, 0; }
{ and r13, 0ff00h; }
{ or r13, r9; }            \ sra 1st op mantissa
{ loop nz; sub nil, r7, r8, nz; }
{ cjp nz, M2; }
M1 { sub nil, r7, r8, nz; load rn, flags; }
{ cjp rn_z, M2; }          \ if r7 = r8, goto M2
{ and r9, r14, 0ffh; }     \ r9 := 2nd op mantissa
{ push; }
{ add r8, 100h; }
{ and r14, 0c0ffh; }
{ or r14, r8; }            \ +1 to 2nd op order
{ or sra, r9, 0; }
{ and r14, 0ff00h; }
{ or r14, r9; }            \ sra 2nd op mantissa
{ loop nz; sub nil, r7, r8, nz; }
M2 { and r7, r13, 80ffh; } \ r7 := 1st op mantissa
{ and r8, r14, 80ffh; }    \ r8 := 2nd op mantissa

\ 2) 1st operand's mantissa -> complement code
{ and nil, r7, 8000h; load rn, flags; }
{ cjp rn_z, M3; }
{ xor r7, 0ffffh; }        \ r7 := not r7
{ or r7, 8000h; }          \ r7 := - r7
{ add r7, 1; }             \ r7 := r7 + 1

\ 3) 2nd operand's mantissa -> complement code
M3 { and nil, r8, 8000h; load rn, flags; }
{ cjp rn_z, M4; }
{ xor r8, 0ffffh; }        \ r8 := not r8
{ or r8, 8000h; }          \ r8 := - r8
{ add r8, 1; }             \ r8 := r8 + 1

\ 4) substitution
M4 { mov r9, r7; }
{ sub r9, r8, nz; }        \ r9 := r7 - r8

\ 5) result's mantissa -> direct code
{ and nil, r9, 8000h; load rn, flags; }
{ cjp rn_z, M5; }
{ xor r9, 0ffffh; }        \ r9 := not r9
{ or r9, 8000h; }          \ r9 := - r9
{ add r9, 1; }             \ r9 := r9 + 1

\ 6) result's normalization
M5 { and nil, r9, 100h; load rn, flags; }
{ cjp rn_z, M6; }
{ and r8, 3f00h; }
{ add r8, 100h; }          \ 1+ to result's order
{ and r7, r9, 0ffh; }
{ or sra, r7, 0; }         \ sra result's mantissa
{ and r9, 0ff00h;}
{ or r9, r7; }
M6 { and r7, r9, 0ffh; }
{ and r8, r13, 3f00h; }
{ and nil, r9, 80h; load rn, flags; }
{ cjp not rn_z, M7; }
{ push; }
{ sub r8, 100h, nz; }      \ 1- to result's order
{ or sla, r7, 0; }         \ sla result's mantissa
{ loop not zo; and nil, r7, 80h; }

\ 7) writing result down
M7 { and r15, r9, 8000h; }      \ result's sign
{ or r15, r8; }                 \ result's order
{ or r15, r7; load rn, flags; } \ result's mantissa

\ back to main program
{ cjp nz, S2; }

\ MCSUBF ends

org 0ff0h
FINISH { cjp nz, END; }

END {}
