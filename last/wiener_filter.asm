.data
input_file:.asciiz "Input_test/input19-44-21_11-Nov-25_10_10_1.txt"
desired_file:.asciiz "Input_test/desired19-44-21_11-Nov-25_10_10.txt"
output_file:.asciiz "Input_test/output1.txt"
buf_size:     .word 32768
buffer:       .space 32768
NUM_SAMPLES:  .word 10
input_count:  .word 0
desired_count: .word 0
desired_signal:      .float 0.0:10
input_signal:        .float 0.0:10
filtered:     .float 0.0:10
crosscorr:    .space 40
autocorr:     .space 40
R:            .space 400
Aug:          .space 440
optimize_coefficient:        .space 40
ouput:        .space 40
mmse:         .float 0.0
zero_f:       .float 0.0
one_f:        .float 1.0
one:          .float 1.0
ten:          .float 10.0
hundred:      .float 100.0
half:         .float 0.5
minus_half:   .float -0.5
zero:         .float 0.0
header_filtered: .asciiz "Filtered output: "
header_mmse:  .asciiz "\nMMSE: "
space_str:    .asciiz " "
str_buf:      .space 32
temp_str:     .space 32
file_buffer:  .space 1024
file_buffer2: .space 2048
buffer_ptr:   .word 0
error_open:   .asciiz "Error: Can not open file"
error_size:   .asciiz "Error: size not match"
eps_f: .float 1.0e-12

.text
.globl main

main:
    # --- Open and read input file for input[] ---
    # TODO
       addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    # --- Read "input.txt" ---
    li   $v0, 13
    la   $a0, input_file
    li   $a1, 0
    li   $a2, 0
    syscall
    bltz $v0, error_open
    move $s0, $v0

    li   $v0, 14
    move $a0, $s0
    la   $a1, file_buffer2
    li   $a2, 2048
    syscall
    
    la   $t0, file_buffer2       # Null terminate buffer
    add  $t0, $t0, $v0
    sb   $zero, 0($t0)

    li   $v0, 16                # Close file
    move $a0, $s0
    syscall

    # Parse into input_signal
    la   $t0, file_buffer2
    sw   $t0, buffer_ptr
    li   $s0, 0
    la   $s1, input_signal

    read_input_loop:
    jal  parse_float
    beq  $v1, $zero, input_done  # $v1=0 means no more data
    s.s  $f0, 0($s1)            
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    bge  $s0, 10, input_done     # Max 10 elements
    j    read_input_loop

    input_done:
    sw   $s0, input_count        # Save actual count

    # --- Read "desired.txt" ---
    read_desired:
    li   $v0, 13
    la   $a0, desired_file
    li   $a1, 0
    li   $a2, 0
    syscall
    bltz $v0, error_open
    move $s0, $v0

    li   $v0, 14
    move $a0, $s0
    la   $a1, file_buffer2
    li   $a2, 2048
    syscall

    la   $t0, file_buffer2
    add  $t0, $t0, $v0
    sb   $zero, 0($t0)

    li   $v0, 16
    move $a0, $s0
    syscall

    # Parse into desired_signal
    la   $t0, file_buffer2
    sw   $t0, buffer_ptr
    li   $s0, 0
    la   $s1, desired_signal

    read_desired_loop:
    jal  parse_float
    beq  $v1, $zero, desired_done  # $v1=0 means no more data
    s.s  $f0, 0($s1)           
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    bge  $s0, 10, desired_done     # Max 10 elements
    j    read_desired_loop

    desired_done:
    sw   $s0, desired_count      # Save actual count

read_done:
    # Check if sizes match
    lw   $t0, input_count
    lw   $t1, desired_count
    bne  $t0, $t1, size_error
    
    # Files loaded, continue to processing
    j    start_processing

size_error:
    # Open output.txt to write error message
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1               # Write mode
    li   $a2, 0
    syscall
    move $s6, $v0             # Save file descriptor
    
    # Write error message to file
    li   $v0, 15
    move $a0, $s6
    la   $a1, error_size
    li   $a2, 21              # Length of "Error: size not match"
    syscall
    
    # Close file
    li   $v0, 16
    move $a0, $s6
    syscall
    
    # 1. Open output file (?? ch?a th?ng b?o l?i)
    li $v0, 13
    la $a0, output_file
    li $a1, 0    
    syscall
    move $s6, $v0 
    
    # 2. Read file
    li $v0, 14
    move $a0, $s6
    la $a1, file_buffer
    li $a2, 1024
    syscall
    
    # 3. Null-terminate the buffer 
    la $t0, file_buffer
    add $t0, $t0, $v0 
    sb $zero, 0($t0) 

    # 4. Print the buffer into console 
    li $v0, 4    
    la $a0, file_buffer
    syscall

    # 5. Close output file 
    li $v0, 16
    move $a0, $s6
    syscall

    # 6. Exit program
    li $v0, 10
    syscall
    
parse_float:
    lw   $t0, buffer_ptr
    l.s  $f0, zero
    l.s  $f1, ten
    li   $t2, 0

    skip_whitespace:
    lb   $t1, 0($t0)
    beq  $t1, $zero, parse_no_data  # Check for null terminator
    beq  $t1, 32, advance_ws
    beq  $t1, 10, advance_ws
    beq  $t1, 13, advance_ws
    beq  $t1, 9,  advance_ws
    j    check_sign

    advance_ws: 
    addi $t0, $t0, 1
    j    skip_whitespace

    check_sign:
    lb   $t1, 0($t0)
    bne  $t1, '-', parse_int_part
    li   $t2, 1
    addi $t0, $t0, 1

    parse_int_part:
    lb   $t1, 0($t0)
    blt  $t1, '0', check_dot
    bgt  $t1, '9', check_dot
    sub  $t1, $t1, '0'
    mtc1 $t1, $f2
    cvt.s.w $f2, $f2
    mul.s $f0, $f0, $f1
    add.s $f0, $f0, $f2
    addi $t0, $t0, 1
    j    parse_int_part

    check_dot:
    lb   $t1, 0($t0)
    bne  $t1, '.', apply_sign
    addi $t0, $t0, 1
    l.s  $f3, one

    parse_frac_part:
    lb   $t1, 0($t0)
    blt  $t1, '0', apply_sign
    bgt  $t1, '9', apply_sign
    sub  $t1, $t1, '0'
    mul.s $f3, $f3, $f1 
    mtc1 $t1, $f2
    cvt.s.w $f2, $f2
    div.s $f2, $f2, $f3
    add.s $f0, $f0, $f2
    addi $t0, $t0, 1
    j    parse_frac_part

    apply_sign:
    beq  $t2, 0, parse_finish
    neg.s $f0, $f0

    parse_finish:
    sw   $t0, buffer_ptr
    li   $v1, 1              # Success flag
    jr   $ra

    parse_no_data:
    li   $v1, 0              # No more data flag
    jr   $ra

start_processing:
    # Load actual input count into $s7 for use throughout
    lw   $s7, input_count
    
    # --- compute crosscorrelation ---
    la   $a0, desired_signal
    la   $a1, input_signal
    la   $a2, crosscorr
    move $a3, $s7              # N = actual count
    jal  computeCrosscorrelation

    # --- compute autocorrelation ---
    # TODO
    
    la    $a0, input_signal           
    la    $a1, autocorr       
    move  $a2, $s7             
    jal   computeAutocorrelation

    # --- create Toeplitz matrix ---
    # TODO
    
    la    $a0, autocorr       
    la    $a1, R               
    move  $a2, $s7             
    jal   createToeplitzMatrix

    # --- solveLinearSystem ---
    # TODO

    la    $a0, R               # A = Toeplitz matrix R
    la    $a1, crosscorr       # b = crosscorr vector
    la    $a2, optimize_coefficient           # x = coeff (output)
    move  $a3, $s7             # N = actual count
    jal solveLinearSystem

    # --- applyWienerFilter ---
    # TODO
    
    la    $a0, input_signal           # input signal
    la    $a1, optimize_coefficient           # Wiener coefficients
    la    $a2, filtered        # filtered output
    move  $a3, $s7             # N = actual count
    jal applyWienerFilter

    # --- compute MMSE ---
    # TODO  
    jal  computeMMSE

    # --- Open output file ---
    # TODO
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1
    li   $a2, 0
    syscall
    move $s6, $v0          
    
    # --- Write "Filtered output: " ---
    # TODO
    li   $v0, 15
    move $a0, $s6
    la   $a1, header_filtered
    li   $a2, 17              
    syscall

    # Write filtered outputs with 1 decimal
    la   $s1, filtered 
    lw   $s2, input_count      # Use actual count
    li   $s0, 0              
    
    write_loop_start:
    beq  $s0, $s2, write_loop_end
    
    l.s  $f12, 0($s1)          # Load current sample
    jal  round_to_1dec
    mov.s $f12, $f0
    
    la   $a0, str_buf
    li   $a1, 1
    jal  float_to_str
    move $t0, $v0              # $t0 = string length
    
    # Write the formatted sample
    li   $v0, 15
    move $a0, $s6
    la   $a1, str_buf
    move $a2, $t0
    syscall

    addi $t1, $s0, 1
    slt  $t2, $t1, $s2
    beq  $t2, $zero, skip_space

    li   $v0, 15
    move $a0, $s6
    la   $a1, space_str
    li   $a2, 1
    syscall

    skip_space:
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    j    write_loop_start

    write_loop_end:
    # --- Write "\nMMSE: " ---
    # TODO
    li   $v0, 15
    move $a0, $s6
    la   $a1, header_mmse
    li   $a2, 7              
    syscall

    # Write the MMSE with 1 decimal
    l.s  $f12, mmse
    jal  round_to_1dec
    mov.s $f12, $f0

    la   $a0, str_buf
    li   $a1, 1
    jal  float_to_str
    move $t0, $v0

    li   $v0, 15
    move $a0, $s6
    la   $a1, str_buf
    move $a2, $t0
    syscall

    # Close output file
    li   $v0, 16
    move $a0, $s6
    syscall

    
    # --- Display the content of output.txt in the MARS terminal ---
    # Open output file
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 0              
    syscall
    move $s6, $v0              

    # Read file 
    li   $v0, 14              
    move $a0, $s6              # File descriptor
    la   $a1, file_buffer      # Buffer to store content
    li   $a2, 1024             # Max bytes to read
    syscall                   
    
    # Null-terminate the buffer 
    la   $t0, file_buffer
    add  $t0, $t0, $v0         # Address of end of content
    sb   $zero, 0($t0)         # Null-terminate the string

    # Print the buffer into console 
    li   $v0, 4               
    la   $a0, file_buffer
    syscall

    # Close output file 
    li   $v0, 16
    move $a0, $s6
    syscall

    li   $v0, 10
    syscall

# ---------------------------------------------------------
# computeAutocorrelation(input[], autocorr[], N)
# ---------------------------------------------------------
computeAutocorrelation:
    # TODO
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $a0, 4($sp)
    sw   $a1, 8($sp)
    sw   $a2, 12($sp)
    
    li   $t0, 0                  # lag = 0
    sw   $t0, 16($sp)            # Save lag

    lw   $t7, 4($sp)             # input array address
    lw   $t8, 8($sp)             # output array address
    lw   $t9, 12($sp)            # N
    
    mtc1 $t9, $f10
    cvt.s.w $f10, $f10           # N (float)

Loop_Lag_Auto:
    lw   $t0, 16($sp)            # Restore lag
    bge  $t0, $t9, End_Auto      # lag >= N

    li   $t6, 0
    mtc1 $t6, $f2                # sum = 0.0
    
    li   $t1, 0                  # n = 0 (sample index)
    sw   $t1, 20($sp)            # Save n
    sub  $t6, $t9, $t0           # limit = N - lag

Loop_n_Auto:
    lw   $t1, 20($sp)            # Restore n
    bge  $t1, $t6, End_n_Auto    # n >= N - lag
    
    # input[n]
    sll  $t2, $t1, 2
    add  $t3, $t7, $t2
    lwc1 $f0, 0($t3)
    
    # input[n + lag]
    add  $t4, $t1, $t0
    sll  $t4, $t4, 2
    add  $t5, $t7, $t4
    lwc1 $f1, 0($t5)
    
    mul.s $f4, $f0, $f1          # product = input[n] * input[n + lag]
    add.s $f2, $f2, $f4          # sum += product
    
    addi $t1, $t1, 1
    sw   $t1, 20($sp)            # Save n
    j    Loop_n_Auto

End_n_Auto:
    div.s $f2, $f2, $f10         # Rxx[lag] = sum / N (Normalization)
    
    sll  $t6, $t0, 2
    add  $t5, $t8, $t6           # Address &autocorr[lag]
    swc1 $f2, 0($t5)
    
    addi $t0, $t0, 1
    sw   $t0, 16($sp)            # Save lag
    j    Loop_Lag_Auto

End_Auto:
    lw   $ra, 0($sp)
    addi $sp, $sp, 24
    jr   $ra
# ---------------------------------------------------------
# computeCrosscorrelation(desired[], input[], crosscorr[], N)
# ---------------------------------------------------------
computeCrosscorrelation:
    # TODO
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    move $t0, $a0                # desired array address
    move $t1, $a1                # input array address
    move $t2, $a2                # crosscorr output address
    move $t3, $a3                # N
    
    mtc1 $t3, $f10
    cvt.s.w $f10, $f10           # N.0 (float)

    li   $t4, 0                  # lag = 0
Loop_Lag_Cross:
    bge  $t4, $t3, End_Cross     # lag >= N
    
    li   $t9, 0
    mtc1 $t9, $f2                # sum = 0.0
    
    li   $t5, 0                  # n = 0 (sample index)
    sub  $t6, $t3, $t4           # limit = N - lag

Loop_n_Cross:
    bge  $t5, $t6, End_n_Cross   # n >= N - lag

    # desired[n + lag]
    add  $t7, $t5, $t4
    sll  $t7, $t7, 2
    add  $t7, $t0, $t7
    lwc1 $f0, 0($t7)
    
    # input[n]
    sll  $t8, $t5, 2
    add  $t8, $t1, $t8
    lwc1 $f1, 0($t8)
    
    mul.s $f4, $f0, $f1          # product = desired[n + lag] * input[n]
    add.s $f2, $f2, $f4          # sum += product
    
    addi $t5, $t5, 1
    j    Loop_n_Cross

End_n_Cross:
    div.s $f2, $f2, $f10         # Rdx[lag] = sum / N (Normalization)
    
    sll  $t7, $t4, 2
    add  $t7, $t2, $t7           # Address &crosscorr[lag]
    swc1 $f2, 0($t7)
    
    addi $t4, $t4, 1
    j    Loop_Lag_Cross

End_Cross:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ---------------------------------------------------------
# createToeplitzMatrix(autocorr[], R[][], N)
# ---------------------------------------------------------
createToeplitzMatrix:
    # TODO
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $a0, 4($sp)
    sw   $a1, 8($sp)
    sw   $a2, 12($sp)

    li   $t0, 0                  # i = 0 (row index)
    sw   $t0, 16($sp)            # Save i
    
    lw   $t7, 4($sp)             # autocorr array address
    lw   $t8, 8($sp)             # R matrix address
    lw   $t9, 12($sp)            # N (matrix size)

Loop_i_M:
    lw   $t0, 16($sp)            # Restore i
    bge  $t0, $t9, End_M         # i >= N
    
    li   $t1, 0                  # j = 0 (column index)
    sw   $t1, 20($sp)            # Save j

Loop_j_M:
    lw   $t1, 20($sp)            # Restore j
    bge  $t1, $t9, End_j_M       # j >= N
    
    # lag = abs(i - j)
    sub  $t2, $t0, $t1           # i - j
    bge  $t2, $zero, Skip_Neg
    sub  $t2, $zero, $t2         # Absolute value: neg to pos
Skip_Neg:
    
    # load autocorr[lag]
    sll  $t3, $t2, 2
    add  $t3, $t7, $t3
    lwc1 $f0, 0($t3)             # $f0 = autocorr[lag]
    
    # store R[i][j]
    mul  $t3, $t0, $t9           # i*N
    add  $t3, $t3, $t1           # + j
    sll  $t3, $t3, 2             # * 4 (byte offset)
    add  $t3, $t8, $t3           # Address &R[i][j]
    swc1 $f0, 0($t3)             # R[i][j] = autocorr[lag]
    
    addi $t1, $t1, 1
    sw   $t1, 20($sp)            # Save j
    j    Loop_j_M

End_j_M:
    addi $t0, $t0, 1
    sw   $t0, 16($sp)            # Save i
    j    Loop_i_M

End_M:
    lw   $ra, 0($sp)
    addi $sp, $sp, 24
    jr   $ra
# ---------------------------------------------------------
# solveLinearSystem(A[][], b[], x[], N)
# ---------------------------------------------------------
solveLinearSystem:
    # TODO
    # --- Save caller registers ---
    addi $sp, $sp, -32
    sw   $ra, 28($sp)
    sw   $s0, 24($sp)
    sw   $s1, 20($sp)
    sw   $s2, 16($sp)
    sw   $s3, 12($sp)

    # Save arguments in saved registers
    move $s0, $a0        # A
    move $s1, $a1        # b
    move $s2, $a2        # x
    move $s3, $a3        # N

    la   $t9, Aug        # base of Aug

#############################################################
# 1. BUILD AUGMENTED MATRIX [ A | b ]
#############################################################

    li  $t0, 0           # i = 0
build_rows:
    bge $t0, $s3, done_build

    li  $t1, 0           # j = 0
build_cols:
    bge $t1, $s3, insert_b

    # Compute &A[i][j]
    mul $t2, $t0, $s3
    add $t2, $t2, $t1
    sll $t2, $t2, 2
    add $t3, $s0, $t2
    lwc1 $f0, 0($t3)

    # Compute &Aug[i][j]
    addi $t4, $s3, 1      # cols = N+1
    mul  $t5, $t0, $t4    # i*(N+1)
    add  $t5, $t5, $t1    # +j
    sll  $t5, $t5, 2
    add  $t6, $t9, $t5
    swc1 $f0, 0($t6)

    addi $t1, $t1, 1
    j    build_cols

insert_b:
    # b[i] ??? Aug[i][N]
    sll  $t2, $t0, 2
    add  $t3, $s1, $t2
    lwc1 $f0, 0($t3)

    addi $t4, $s3, 1
    mul  $t5, $t0, $t4
    add  $t5, $t5, $s3     # column N
    sll  $t5, $t5, 2
    add  $t6, $t9, $t5
    swc1 $f0, 0($t6)

    addi $t0, $t0, 1
    j    build_rows

done_build:

#############################################################
# 2. FORWARD ELIMINATION (make matrix upper triangular)
#############################################################

    li $t0, 0                 # pivot col = 0
elim_loop:
    bge $t0, $s3, start_back

    # Pivot index = t0 by default (no full search to simplify)
    move $t7, $t0

    # Load pivot Aug[t0][t0]
    addi $t4, $s3, 1
    mul  $t5, $t0, $t4
    add  $t5, $t5, $t0
    sll  $t5, $t5, 2
    add  $t6, $t9, $t5
    lwc1 $f0, 0($t6)

    # If pivot is 0.0 ??? replace with small epsilon
    lwc1 $f1, eps_f
    c.eq.s $f0, $f1
    bc1t skip_piv
skip_piv:

    # Eliminate rows below pivot row
    addi $t1, $t0, 1
elim_rows:
    bge $t1, $s3, next_pivot

    # Load factor = Aug[r][col] / pivot
    mul $t5, $t1, $t4
    add $t5, $t5, $t0
    sll $t5, $t5, 2
    add $t6, $t9, $t5
    lwc1 $f2, 0($t6)
    div.s $f3, $f2, $f0

    # For each column c = col ??? N
    move $t2, $t0
elim_cols:
    bgt $t2, $s3, finish_row

    # M[r][c] -= factor*M[col][c]
    # load M[r][c]
    mul $t5, $t1, $t4
    add $t5, $t5, $t2
    sll $t5, $t5, 2
    add $t6, $t9, $t5
    lwc1 $f4, 0($t6)

    # load M[col][c]
    mul $t5, $t0, $t4
    add $t5, $t5, $t2
    sll $t5, $t5, 2
    add $t7, $t9, $t5
    lwc1 $f5, 0($t7)

    # M[r][c] = M[r][c] - factor*M[col][c]
    mul.s $f6, $f3, $f5
    sub.s $f4, $f4, $f6
    swc1 $f4, 0($t6)

    addi $t2, $t2, 1
    j    elim_cols

finish_row:
    addi $t1, $t1, 1
    j    elim_rows

next_pivot:
    addi $t0, $t0, 1
    j    elim_loop

#############################################################
# 3. BACK SUBSTITUTION (solve x[] from bottom to top)
#############################################################

start_back:
    addi $t0, $s3, -1      # i = N-1

back_loop:
    bltz $t0, done_solver

    # Load RHS value s = Aug[i][N]
    addi $t4, $s3, 1
    mul  $t5, $t0, $t4
    add  $t5, $t5, $s3
    sll  $t5, $t5, 2
    add  $t6, $t9, $t5
    lwc1 $f10, 0($t6)

    # Subtract A[i][j] * x[j] for j = i+1..N-1
    addi $t1, $t0, 1
sub_loop:
    bge  $t1, $s3, divide_diag

    # load x[j]
    sll $t6, $t1, 2
    add $t7, $s2, $t6
    lwc1 $f11, 0($t7)

    # load A[i][j]
    mul $t5, $t0, $t4
    add $t5, $t5, $t1
    sll $t5, $t5, 2
    add $t7, $t9, $t5
    lwc1 $f12, 0($t7)

    mul.s $f13, $f11, $f12
    sub.s $f10, $f10, $f13

    addi $t1, $t1, 1
    j    sub_loop

divide_diag:
    # Compute x[i] = s / Aug[i][i]
    mul $t5, $t0, $t4
    add $t5, $t5, $t0
    sll $t5, $t5, 2
    add $t6, $t9, $t5
    lwc1 $f0, 0($t6)

    div.s $f1, $f10, $f0

    # Store x[i]
    sll $t5, $t0, 2
    add $t6, $s2, $t5
    swc1 $f1, 0($t6)

    addi $t0, $t0, -1
    j    back_loop

#############################################################
# Restore saved regs + return
#############################################################

done_solver:
    lw   $ra, 28($sp)
    lw   $s0, 24($sp)
    lw   $s1, 20($sp)
    lw   $s2, 16($sp)
    lw   $s3, 12($sp)
    addi $sp, $sp, 32
    jr   $ra

# ---------------------------------------------------------
# applyWienerFilter(input[], coefficients[], output[], N)
# ---------------------------------------------------------
applyWienerFilter:
    # TODO
# Save registers
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s0, 8($sp)        # M is stored here

    # n = 0
    li   $t0, 0

loop_n:
    beq  $t0, $a3, done_filter   # if n == N ??? finished

    # accumulator = 0.0
    li   $t1, 0
    mtc1 $t1, $f4                # f4 = 0.0

    # k = 0
    li   $t1, 0

loop_k:
    beq  $t1, $s0, store_output  # if k == M ??? end inner loop

    # index = n - k
    sub  $t2, $t0, $t1
    bltz $t2, skip_term          # if negative ??? skip

    # load input[n-k]
    sll  $t3, $t2, 2
    add  $t3, $t3, $a0
    lwc1 $f6, 0($t3)

    # load coeff[k]
    sll  $t4, $t1, 2
    add  $t4, $t4, $a1
    lwc1 $f8, 0($t4)

    # acc += input * coeff
    mul.s $f10, $f6, $f8
    add.s $f4, $f4, $f10

skip_term:
    addi $t1, $t1, 1
    j    loop_k

store_output:
    # store y[n] = accumulator
    sll  $t5, $t0, 2
    add  $t5, $t5, $a2
    swc1 $f4, 0($t5)

    addi $t0, $t0, 1
    j    loop_n

done_filter:
    # restore saved regs
    lw   $s0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# ---------------------------------------------------------
# computeMMSE(desired[], output[], N) -> $f0
# ---------------------------------------------------------
computeMMSE:
    # TODO
    la   $t0, desired_signal
    la   $t1, filtered      
    lw   $t2, input_count      # Use actual count
    
    mtc1 $zero, $f12            
    cvt.s.w $f12, $f12          

    mmse_loop:
    beq  $t2, $zero, mmse_done
    l.s  $f0, 0($t0)            # d(n)
    l.s  $f1, 0($t1)            # y(n)
    #(d - y)^2
    sub.s $f2, $f0, $f1         # Error
    mul.s $f2, $f2, $f2         # Square
    add.s $f12, $f12, $f2       # Sum += Square
    
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, -1
    j    mmse_loop

    mmse_done:
    lw    $t2, input_count      # Get actual count
    mtc1  $t2, $f5              # Convert to float
    cvt.s.w $f5, $f5
    div.s $f12, $f12, $f5       # Divide by actual count
    
    # Store Result in Memory
    swc1  $f12, mmse

    jr    $ra

# ---------------------------------------------------------
# round_to_1dec($f12) -> $f0
# ---------------------------------------------------------
round_to_1dec:
    # f3 = f12 * 10
    # if f3 < 0:
    #     f3 = f3 - 0.5
    # else:
    #     f3 = f3 + 0.5
    # f4 = int(f3)
    # f0 = float(f4) / 10
    ## TODO
    l.s $f1, ten
    mul.s $f3, $f12, $f1
    # if f3 < 0:
    l.s $f2, zero_f
    c.lt.s $f3, $f2
    bc1t f3_is_neg              # Branch if true
    # else: f3 = f3 + 0.5
    l.s $f1, half
    add.s $f3, $f3, $f1
    j f3_rounded
    
f3_is_neg:
    # f3 = f3 - 0.5
    l.s $f1, minus_half
    add.s $f3, $f3, $f1

f3_rounded:
    # f4 = int(f3)
    trunc.w.s $f4, $f3          # Truncate to integer (word)

    # f0 = float(f4) / 10
    cvt.s.w $f4, $f4            # Convert integer back to float
    l.s $f1, ten
    div.s $f0, $f4, $f1         # Divide by 10

    jr $ra
# ---------------------------------------------------------
# float_to_str(buffer $a0, value $f12, decimals $a1) -> length $v0
# ---------------------------------------------------------
float_to_str:
    ## TODO
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    s.s $f20, 24($sp)  # $f12 (value)
    s.s $f21, 20($sp)  # temp
    sw $s0, 16($sp)    # $a0 (buffer)
    sw $s1, 12($sp)    # $a1 (decimals)
    sw $s2, 8($sp)     # length
    sw $s3, 4($sp)     # scaled integer
    sw $s4, 0($sp)     # pow10 factor

    move $s0, $a0      # Save buffer pointer
    mov.s $f20, $f12   # Save value
    move $s1, $a1      # Save decimals
    li $s2, 0          # length = 0

    # Handle Sign
    l.s $f1, zero_f
    c.lt.s $f20, $f1
    bc1f fts_sign_done
    nop

fts_is_neg:
    li $t0, '-'
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    neg.s $f20, $f20

fts_sign_done:
    # Scale by 10^decimals
    move $t0, $s1
    l.s $f1, ten
    li $s4, 1

fts_scale_loop:
    beq $t0, $zero, fts_scale_done
    mul.s $f20, $f20, $f1
    mul $s4, $s4, 10
    addi $t0, $t0, -1
    j fts_scale_loop

fts_scale_done:
    round.w.s $f21, $f20
    mfc1 $s3, $f21          # scaled integer (non-negative)

    # Convert scaled integer to string digits in temp_str
    la $a0, temp_str
    move $a1, $s3
    jal int_to_str
    move $t5, $v0           # digit count

    # If no decimals, copy digits directly
    beq $s1, $zero, fts_copy_whole

    # Determine if there are integer digits beyond decimal places
    sub $t6, $t5, $s1       # t6 = digit_count - decimals
    blez $t6, fts_small_value

    # Copy integer digits (t6 > 0)
    la $t2, temp_str
    move $t3, $t6

fts_copy_int_loop:
    beq $t3, $zero, fts_write_decimal_point
    lb $t4, 0($t2)
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t2, $t2, 1
    addi $t3, $t3, -1
    j fts_copy_int_loop

fts_write_decimal_point:
    li $t4, '.'
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1

    # Copy fractional digits (exactly decimals count)
    move $t3, $s1

fts_copy_frac_loop:
    beq $t3, $zero, fts_done_number
    lb $t4, 0($t2)
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t2, $t2, 1
    addi $t3, $t3, -1
    j fts_copy_frac_loop

fts_done_number:
    j fts_finish

fts_small_value:
    # Integer part is 0 when digit count <= decimals
    li $t4, '0'
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1

    li $t4, '.'
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1

    sub $t3, $s1, $t5        # number of leading zeros needed

fts_leading_zero_loop:
    ble $t3, $zero, fts_small_copy
    li $t4, '0'
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t3, $t3, -1
    j fts_leading_zero_loop

fts_small_copy:
    la $t2, temp_str
    move $t3, $t5

fts_small_copy_loop:
    beq $t3, $zero, fts_finish
    lb $t4, 0($t2)
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t2, $t2, 1
    addi $t3, $t3, -1
    j fts_small_copy_loop

fts_copy_whole:
    la $t2, temp_str

fts_copy_whole_loop:
    lb $t4, 0($t2)
    beq $t4, $zero, fts_finish
    sb $t4, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t2, $t2, 1
    j fts_copy_whole_loop

fts_finish:
    li $t0, 0
    sb $t0, 0($s0)
    move $v0, $s2

    lw $ra, 28($sp)
    l.s $f20, 24($sp)
    l.s $f21, 20($sp)
    lw $s0, 16($sp)
    lw $s1, 12($sp)
    lw $s2, 8($sp)
    lw $s3, 4($sp)
    lw $s4, 0($sp)
    addi $sp, $sp, 32
    jr $ra

# ---------------------------------------------------------
# int_to_str(buffer $a0, value $a1) -> length $v0
# Helper function, converts integer to ASCII string.
# ---------------------------------------------------------
int_to_str:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)         # $a1 (value)
    sw $s1, 8($sp)          # buffer pointer
    sw $s2, 4($sp)          # length
    sw $s3, 0($sp)          # is_neg

    move $s0, $a1           # value
    la $s1, temp_str        # Use temp_str to build backwards
    addi $s1, $s1, 31       # Go to end of temp_str
    li $t0, 0
    sb $t0, 0($s1)          # Null terminator
    addi $s1, $s1, -1       # Point to last char position
    li $s2, 0               # length = 0
    li $s3, 0               # is_neg = 0

    # Handle 0
    bne $s0, $zero, its_check_neg
    li $t0, '0'
    sb $t0, 0($s1)
    li $s2, 1
    j its_copy_setup

its_check_neg:
    bge $s0, $zero, its_loop
    li $s3, 1               # is_neg = 1
    neg $s0, $s0            # value = -value

its_loop:
    rem $t0, $s0, 10
    addi $t0, $t0, '0'      # Convert to ASCII
    sb $t0, 0($s1)          # Store digit
    addi $s1, $s1, -1       # Move buffer pointer
    addi $s2, $s2, 1        # length++
    div $s0, $s0, 10
    bgtz $s0, its_loop      # Loop if value > 0

    # Add sign if needed
    beq $s3, $zero, its_copy
    li $t0, '-'
    sb $t0, 0($s1)
    addi $s1, $s1, -1
    addi $s2, $s2, 1

its_copy:
    # Copy from temp_str to $a0
    addi $s1, $s1, 1        # Point to start of string in temp_str
    
its_copy_setup: 
    move $s3, $a0           # $s3 = dest buffer
    move $t0, $s2           # $t0 = counter
its_copy_loop:
    beq $t0, $zero, its_copy_done
    lb $t1, 0($s1)
    sb $t1, 0($s3)
    addi $s1, $s1, 1
    addi $s3, $s3, 1
    addi $t0, $t0, -1
    j its_copy_loop

its_copy_done:
    li $t0, 0
    sb $t0, 0($s3)          # Null terminate dest buffer
    move $v0, $s2           # Return length

    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra
