.data
# Result DATA1 0.9115744 0.07941656 2.2789361 2.7509499
https://www.overleaf.com/project/69106690fbbe31ba945b3e6d
.include "data1.asm"
 
# Result DATADATA2 1.1174561 -0.025610173 0.005156662 1.3409474 2.762908 3.2945309
https://www.overleaf.com/project/69106690fbbe31ba945b3e6d
# .include "data2.asm"

# --- helper floats ---
zero_f:      .float 0.0
one_f:       .float 1.0
# TODO

.text
.globl main

main:
    # print header
    li   $v0, 4          # print string
    la   $a0, header_msg
    syscall
    
    # --- compute crosscorrelation ---
    la   $a0, desired
    la   $a1, input
    la   $a2, crosscorr
    lw   $a3, NUM_SAMPLES
    jal  computeCrosscorrelation

    # --- compute autocorrelation ---
    # TODO

    # --- create Toeplitz matrix ---
    # TODO

    # --- solveLinearSystem ---
    # TODO

    # --- applyWienerFilter ---
    # TODO

    # --- print ---
    la   $t0, coeff   # base address của mảng đầu tiên (coeff)
    li   $t1, 0          # index
    lw   $t2, SIZE_PRINT
print_loop:
    beq  $t1, $t2, done
    lwc1 $f12, 0($t0)
    li   $v0, 2
    syscall
    li   $v0, 11
    la   $a0, 32     # hoặc newline
    syscall
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j    print_loop

done:
    li $v0, 10           # exit program
    syscall

# ---------------------------------------------------------
# computeAutocorrelation(input[], autocorr[], N)
# ---------------------------------------------------------
computeAutocorrelation:
    # TODO
    jr $ra

# ---------------------------------------------------------
# computeCrosscorrelation(desired[], input[], crosscorr[], N)
# ---------------------------------------------------------
computeCrosscorrelation:
    # TODO
    jr $ra

# ---------------------------------------------------------
# createToeplitzMatrix(autocorr[], R[][], N)
# ---------------------------------------------------------
createToeplitzMatrix:
    # TODO
    jr $ra

# ---------------------------------------------------------
# solveLinearSystem(A[][], b[], x[], N)
# ---------------------------------------------------------
solveLinearSystem:
    # TODO

# Integer:
#   $t0 = i
#   $t1 = j
#   $t2 = r (pivot scan / row index)
#   $t3 = c (inner column/index)
#   $t4 = row_stride / tmp
#   $t5 = col_stride / tmp
#   $t6 = addr1 (temporary address)
#   $t7 = addr2 (temporary address)
#   $t8 = pivotRow (tpiv)
#   $t9 = misc temp
# Saved:
#   $s0 = A base
#   $s1 = b base
#   $s2 = x base
#   $s3 = N
#   $s4 = Aug base
#   $s5 = spare
# Floating:
#   $f0 = pivot value
#   $f1 = abs pivot / temp abs
#   $f2 = current entry
#   $f3 = another entry
#   $f4 = factor
#   $f5 = tmp product
#   $f6 = accumulator / s
#   $f7 = x[j]
#   $f8 = diag
#   $f9 = eps
#   $f10= zero (0.0)

.data
# constants
zero_f: .float 0.0
eps_f:  .float 1.0e-12

# test size
N: .word 3

# Test matrix A (3x3)
A: .float 4.0, 2.0, 1.0,
           2.0, 5.0, 3.0,
           1.0, 3.0, 6.0

# RHS b
b: .float 9.0, 8.0, 7.0

# output x (space for N floats)
x:   .space 12

# augmented workspace Aug (reserve for N<=10; change if bigger)
# Aug is row-major with (N+1) columns (last column is b)
Aug: .space 440

.text
.globl main

# ------------------------------
# main: calls solver, prints x[]
# ------------------------------
main:
    # load args
    la   $a0, A       # A base
    la   $a1, b       # b base
    la   $a2, x       # x base (output)
    lw   $a3, N       # N
    jal  solveLinearSystem

    # print x[0..N-1]
    la   $t6, x       # addr pointer
    lw   $t0, N       # reuse $t0 as loop limit (N)
    li   $t1, 0       # index = 0

print_loop:
    beq  $t1, $t0, done_main
    lwc1 $f12, 0($t6)
    li   $v0, 2
    syscall
    # newline
    li   $v0, 11
    li   $a0, 10
    syscall

    addi $t6, $t6, 4
    addi $t1, $t1, 1
    j    print_loop

done_main:
    li $v0, 10
    syscall

# =================================================
# solveLinearSystem - partial pivoting on Aug matrix
# Inputs:
#   $a0 = A base (row-major MxM floats)
#   $a1 = b base (M floats)
#   $a2 = x base (M floats)  <- solution written here
#   $a3 = N
# Uses Aug label as workspace: Aug[row*(N+1)+col]
# =================================================
solveLinearSystem:
    
    addi $sp, $sp, -56
    sw   $ra, 52($sp)
    sw   $s0, 48($sp)
    sw   $s1, 44($sp)
    sw   $s2, 40($sp)
    sw   $s3, 36($sp)
    sw   $s4, 32($sp)
    sw   $s5, 28($sp)

    # move args into saved regs
    move $s0, $a0      # A base
    move $s1, $a1      # b base
    move $s2, $a2      # x base
    move $s3, $a3      # N
    la   $s4, Aug      # Aug base

    # load float constants
    lwc1 $f10, zero_f  # f10 = 0.0
    lwc1 $f9,  eps_f   # f9  = eps

    # ------------------------------------------------
    # 1) Build augmented matrix: Aug[i][0..N-1] = A[i][0..N-1], Aug[i][N]=b[i]
    # ------------------------------------------------
    li   $t0, 0        # i = 0
build_i_loop:
    beq  $t0, $s3, build_done

    li   $t1, 0        # j = 0
build_j_loop:
    beq  $t1, $s3, store_b_col

    # Load A[i][j] into $f2
    mul  $t4, $t0, $s3    # t4 = i * N
    add  $t4, $t4, $t1    # t4 = i*N + j
    sll  $t4, $t4, 2
    add  $t5, $s0, $t4
    lwc1 $f2, 0($t5)

    # Store into Aug[i][j]
    addi $t5, $s3, 1      # t5 = N+1 (reuse t5)
    mul  $t6, $t0, $t5    # t6 = i*(N+1)
    add  $t6, $t6, $t1    # + j
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    swc1 $f2, 0($t7)

    addi $t1, $t1, 1
    j    build_j_loop

store_b_col:
    # Load b[i] into f2
    sll  $t4, $t0, 2
    add  $t5, $s1, $t4
    lwc1 $f2, 0($t5)

    # Store into Aug[i][N]
    addi $t6, $s3, 1     # t6 = N+1
    mul  $t7, $t0, $t6
    add  $t7, $t7, $s3   # index = i*(N+1) + N
    sll  $t7, $t7, 2
    add  $t8, $s4, $t7
    swc1 $f2, 0($t8)

    addi $t0, $t0, 1
    j    build_i_loop

build_done:

    # ------------------------------------------------
    # 2) Forward elimination with partial pivoting
    # ------------------------------------------------
    li   $t0, 0          # t0 = col (reuse)
for_col_loop:
    beq  $t0, $s3, forward_done

    # pivot search: find pivotRow ($t8) with max |Aug[r][col]| for r in [col..N-1]
    move $t8, $t0        # pivotRow = col

    addi $t5, $s3, 1     # t5 = N+1 (num cols in Aug)
    mul  $t6, $t0, $t5
    add  $t6, $t6, $t0   # index = col*(N+1) + col
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f0, 0($t7)     # f0 = Aug[col][col]

    # f1 = abs(f0)
    add.s $f1, $f0, $f10
    c.lt.s $f1, $f10
    bc1f no_abs_first
    neg.s $f1, $f1
no_abs_first:

    addi $t2, $t0, 1     # r = col+1
pivot_scan_loop:
    beq  $t2, $s3, pivot_scan_done

    # load Aug[r][col] into f2
    mul  $t6, $t2, $t5   # t6 = r*(N+1)
    add  $t6, $t6, $t0   # + col
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f2, 0($t7)

    # f3 = abs(f2)
    add.s $f3, $f2, $f10
    c.lt.s $f3, $f10
    bc1f no_abs_cur
    neg.s $f3, $f3
no_abs_cur:

    # if f3 > f1 then update f1 and pivotRow
    c.lt.s $f1, $f3
    bc1f no_update_piv
    add.s $f1, $f3, $f10
    move $t8, $t2
no_update_piv:

    addi $t2, $t2, 1
    j    pivot_scan_loop

pivot_scan_done:

    # swap rows if pivotRow != col (swap all N+1 cols)
    beq  $t8, $t0, no_swap_rows
    li   $t1, 0
swap_cols_loop:
    beq  $t1, $t5, swap_done_rows   # iterate j from 0..N

    # addr1 = &Aug[col][j]
    mul  $t4, $t0, $t5
    add  $t4, $t4, $t1
    sll  $t4, $t4, 2
    add  $t6, $s4, $t4
    lwc1 $f2, 0($t6)

    # addr2 = &Aug[pivotRow][j]
    mul  $t4, $t8, $t5
    add  $t4, $t4, $t1
    sll  $t4, $t4, 2
    add  $t7, $s4, $t4
    lwc1 $f3, 0($t7)

    swc1 $f3, 0($t6)
    swc1 $f2, 0($t7)

    addi $t1, $t1, 1
    j    swap_cols_loop
swap_done_rows:
no_swap_rows:

    # reload pivot value f0 = Aug[col][col]
    mul  $t6, $t0, $t5
    add  $t6, $t6, $t0
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f0, 0($t7)

    # if |pivot| < eps -> set pivot = eps
    add.s $f6, $f0, $f10
    c.lt.s $f6, $f10
    bc1f no_neg_pivot
    neg.s $f6, $f6
no_neg_pivot:
    c.lt.s $f6, $f9
    bc1f pivot_ok
    swc1 $f9, 0($t7)
    add.s $f0, $f9, $f10    # f0 = eps
pivot_ok:

    # elimination: for r = col+1 .. N-1
    addi $t2, $t0, 1
elim_rows_loop:
    beq  $t2, $s3, after_elim_rows

    # load Aug[r][col] into f2
    mul  $t6, $t2, $t5
    add  $t6, $t6, $t0
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f2, 0($t7)

    # factor = f2 / f0  -> f4
    div.s $f4, $f2, $f0

    # for c = col .. N (inclusive)
    move $t3, $t0
elim_cols_loop:
    beq  $t3, $t5, end_elim_cols

    # addr RC = Aug[r][c]
    mul  $t6, $t2, $t5
    add  $t6, $t6, $t3
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f6, 0($t7)     # f6 = Aug[r][c]

    # addr CC = Aug[col][c]
    mul  $t6, $t0, $t5
    add  $t6, $t6, $t3
    sll  $t6, $t6, 2
    add  $t9, $s4, $t6
    lwc1 $f8, 0($t9)     # f8 = Aug[col][c]

    # M[r][c] -= factor * M[col][c]
    mul.s $f5, $f4, $f8
    sub.s $f6, $f6, $f5
    swc1 $f6, 0($t7)

    addi $t3, $t3, 1
    j    elim_cols_loop
end_elim_cols:

    addi $t2, $t2, 1
    j    elim_rows_loop
after_elim_rows:

    addi $t0, $t0, 1
    j    for_col_loop

forward_done:

    # ------------------------------------------------
    # 3) Back substitution
    # ------------------------------------------------
    addi $t0, $s3, -1   # i = N-1
back_i_loop:
    bltz $t0, back_done

    # s = Aug[i][N] -> f6
    mul  $t6, $t0, $t5
    add  $t6, $t6, $s3   # index = i*(N+1) + N
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f6, 0($t7)

    addi $t1, $t0, 1     # j = i+1
back_j_loop:
    beq  $t1, $s3, compute_xi

    # load x[j] -> f7
    sll  $t6, $t1, 2
    add  $t7, $s2, $t6
    lwc1 $f7, 0($t7)

    # load Aug[i][j] -> f8
    mul  $t6, $t0, $t5
    add  $t6, $t6, $t1
    sll  $t6, $t6, 2
    add  $t9, $s4, $t6
    lwc1 $f8, 0($t9)

    mul.s $f5, $f8, $f7
    sub.s $f6, $f6, $f5

    addi $t1, $t1, 1
    j    back_j_loop

compute_xi:
    # diag = Aug[i][i] -> f8
    mul  $t6, $t0, $t5
    add  $t6, $t6, $t0
    sll  $t6, $t6, 2
    add  $t7, $s4, $t6
    lwc1 $f8, 0($t7)

    div.s $f0, $f6, $f8    # x[i] in f0

    # store x[i]
    sll  $t6, $t0, 2
    add  $t7, $s2, $t6
    swc1 $f0, 0($t7)

    addi $t0, $t0, -1
    j    back_i_loop

back_done:
    # epilogue - restore registers and return
    lw   $ra, 52($sp)
    lw   $s0, 48($sp)
    lw   $s1, 44($sp)
    lw   $s2, 40($sp)
    lw   $s3, 36($sp)
    lw   $s4, 32($sp)
    lw   $s5, 28($sp)
    addi $sp, $sp, 56
    jr   $ra

  

# ---------------------------------------------------------
# applyWienerFilter(input[], coefficients[], output[], N)
# ---------------------------------------------------------
applyWienerFilter:
    # TODO
  # applyWienerFilter(input[], coeff[], output[], N)
# M must be placed in $s0 by caller before jal
#
# y[n] = sum_{k=0..M-1} coeff[k] * input[n - k]
# if (n-k) < 0 → treat input as 0.0
#
# Arguments:
#   $a0 = address input[]    (float)
#   $a1 = address coeff[]    (float)
#   $a2 = address output[]   (float)
#   $a3 = N                  (# samples)
#   $s0 = M                  (# taps)  <-- caller must set this
#
# Clobbers: $t0-$t8, $f0-$f12
# Preserves: $s0
#
# Note: function saves/restores $ra and $s0
#
.globl applyWienerFilter
applyWienerFilter:
    # allocate stack frame: save $ra and $s0
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s0, 8($sp)

    # load M from $s0 into a temp reg $t9? We'll use $s0 directly.
    # n = 0 --> $t0
    li   $t0, 0

wf_n_loop:
    beq  $t0, $a3, wf_done        # if n == N -> done

    # acc = 0.0  (use $f4 as accumulator)
    mtc1 $zero, $f0
    cvt.s.w $f0, $f0
    add.s $f4, $f0, $f0           # f4 = 0.0

    # k = 0 in $t1
    li   $t1, 0

wf_k_loop:
    beq  $t1, $s0, wf_k_done      # if k == M exit inner loop

    # index = n - k  -> $t2
    sub  $t2, $t0, $t1
    bltz $t2, wf_k_next           # if index < 0 skip

    # load input[index] -> $f6
    sll  $t3, $t2, 2
    add  $t4, $a0, $t3
    lwc1 $f6, 0($t4)

    # load coeff[k] -> $f8
    sll  $t5, $t1, 2
    add  $t6, $a1, $t5
    lwc1 $f8, 0($t6)

    # f10 = f6 * f8
    mul.s $f10, $f6, $f8
    # acc += f10
    add.s $f4, $f4, $f10

wf_k_next:
    addi $t1, $t1, 1
    j    wf_k_loop

wf_k_done:
    # store output[n] = acc (f4)
    sll  $t7, $t0, 2
    add  $t8, $a2, $t7
    swc1 $f4, 0($t8)

    addi $t0, $t0, 1            # n++
    j    wf_n_loop

wf_done:
    # restore $s0 and $ra, pop stack
    lw   $s0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

   
