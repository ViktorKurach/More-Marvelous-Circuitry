macro mov reg1, reg2: {or reg1, z, reg2; }
accept poh: 1ah, 5dh, 50h, 2bh, 6fh, 60h, 0abh, 0ffh, 0d4h, 0cdh, 40h, 70h, 8fh, 90h, 7ch, 2ah

link l1: z
link l3: z

{ mov r10, r9; }           \ r10 := r9 nxor r8
{ nxor r10, r8; }
{ mov r11, r9; }           \ r11 := 2*(r9 - r10 - 1)
{ sub sla, r11, r10; }
{ push nz, 3; }            \ loop begin
{ sub sra, r12, r13, 0; }  \ r12 := (r13 - 1)/2
{ cjs not l1, 100h; }      \ submicroprogram call
{ rfct; }                  \ loop end
{ mov r7, r6; }            \ r7 := r6 nand r5
{ nand r7, r5; }
{ cjp nz, end; }

org 100h                  \ submicroprogram begin
{ mov r7, r5; }           \ r7 := 2*(r5 - r1 - 1)
{ sub sla, r7, r1; }
{ cjp l3, label; }
{ add r8, r7, 0, nz; }    \ r8 := r7 + 1
label {}
{ sub sra, r6, r9, 0; }   \ r6 := (r9 - 1)/2
{ mov r5, r8; }           \ r5 := r8 + r6
{ add r5, r6; }
{ crtn nz; }              \ submicroprogram end

end {}
