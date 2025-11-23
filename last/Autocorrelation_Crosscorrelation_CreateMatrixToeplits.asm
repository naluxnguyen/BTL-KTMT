.data
desired:     .float 1.5, 2.8, 3.2
input:       .float 1.2, 2.5, 3.0
NUM_SAMPLES: .word 3

# --- output arrays ---
crosscorr:   .space 12         # 3 floats
autocorr:    .space 12         # 3 floats
R:           .space 36         # 3x3 floats

header_msg:  .asciiz "Data 2: \n"
space:       .asciiz " "
newline:     .asciiz "\n" # Changed to actual newline character for better output formatting

.text
.globl main

main:
    # 1. Print Header
    li    $v0, 4
    la    $a0, header_msg
    syscall

    # Load N into $s7 throughout the program
    lw    $s7, NUM_SAMPLES     

    # ==========================================
    # PART 1: COMPUTATIONS (CALL ALL FUNCTIONS)
    # ==========================================
    # --- compute autocorrelation ---


    la    $a0, input           
    la    $a1, autocorr       
    move  $a2, $s7             
    jal   computeAutocorrelation

    # --- compute crosscorrelation ---

    la    $a0, desired         
    la    $a1, input           
    la    $a2, crosscorr       
    move  $a3, $s7             
    jal   computeCrosscorrelation

    # --- create Toeplitz matrix ---

    la    $a0, autocorr       
    la    $a1, R               
    move  $a2, $s7             
    jal   createToeplitzMatrix

    # ==========================================
    # PART 2: PRINT RESULTS
    # ==========================================

    # --- PRINT CROSS CORRELATION ---
    # Print Cross Correlation Results
    li    $s5, 0                 # Reset counter
Print_Cross_Loop:
    bge   $s5, $s7, End_Print_Cross
    
    sll   $t0, $s5, 2          # offset
    la    $t1, crosscorr       # Reload crosscorr address (IMPORTANT)
    add   $t1, $t1, $t0        
    lwc1  $f12, 0($t1)

    li    $v0, 2               # syscall print float
    syscall

    li    $v0, 4
    la    $a0, space
    syscall

    addi  $s5, $s5, 1
    j     Print_Cross_Loop
End_Print_Cross:
    li    $v0, 4
    la    $a0, newline
    syscall

    # --- PRINT MATRIX R ---
    # Print Matrix R
    li    $s3, 0                 # i = 0
Print_Matrix_i:
    bge   $s3, $s7, End_Print_Matrix

    li    $s4, 0                 # j = 0
Print_Matrix_j:
    bge   $s4, $s7, Next_Matrix_Row

    # Calculate address R[i][j]
    mul   $t3, $s3, $s7          # i * N
    add   $t4, $t3, $s4          # + j
    sll   $t5, $t4, 2            # * 4
    la    $t6, R                 # Reload R address (IMPORTANT)
    add   $t6, $t6, $t5
    
    lwc1  $f12, 0($t6)
    li    $v0, 2
    syscall

    li    $v0, 4
    la    $a0, space
    syscall

    addi  $s4, $s4, 1
    j     Print_Matrix_j

Next_Matrix_Row:
    li    $v0, 4
    la    $a0, newline
    syscall
    addi  $s3, $s3, 1
    j     Print_Matrix_i
End_Print_Matrix:

    # --- PRINT AUTOCORRELATION ---
    # Print Autocorrelation Results
    li    $s5, 0                 # Reset counter
Print_Autocorr_Loop:
    bge   $s5, $s7, End_Print_Autocorr
    
    sll   $t0, $s5, 2
    la    $t1, autocorr        # Reload autocorr address (FIXED ERROR HERE)
    add   $t1, $t1, $t0

    lwc1  $f12, 0($t1)
    li    $v0, 2
    syscall

    li    $v0, 4
    la    $a0, space
    syscall

    addi  $s5, $s5, 1
    j     Print_Autocorr_Loop
End_Print_Autocorr:
    li    $v0, 4
    la    $a0, newline
    syscall

    # EXIT PROGRAM
    li    $v0, 10
    syscall

# ---------------------------------------------------------
# computeAutocorrelation(input[], autocorr[], N)
# ---------------------------------------------------------
computeAutocorrelation:
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
# Fix: Used $t registers instead of $s to avoid Stack issues
# ---------------------------------------------------------
computeCrosscorrelation:
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
# createToeplitzMatrix(autocorr[], R[], N)
# ---------------------------------------------------------
createToeplitzMatrix:
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