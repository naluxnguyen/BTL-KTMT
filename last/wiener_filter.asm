.data
input_file:   .asciiz "input.txt"
desired_file: .asciiz "desired.txt"
output_file:  .asciiz "output.txt"
buf_size:     .word 32768
buffer:       .space 32768
NUM_SAMPLES:  .word 10
desired:      .float 0.0:10
input:        .float 0.0:10
crosscorr:    .space 40
autocorr:     .space 40
R:            .space 400
coeff:        .space 40
ouput:        .space 40
mmse:         .float 0.0
zero_f:       .float 0.0
one_f:        .float 1.0
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
fiel_buffer2: .space 2048
error_open:   .asciiz "Error: Can not open file"
error_size:   .asciiz "Error: size not match"

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
    la   $s1, input

    read_input_loop:
    beq  $s0, 10, read_desired
    jal  parse_float
    s.s  $f0, 0($s1)            
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    j    read_input_loop

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
    la   $s1, desired

    read_desired_loop:
    beq  $s0, 10, read_done
    jal  parse_float
    s.s  $f0, 0($s1)           
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    j    read_desired_loop

    read_done:
    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra
    
    parse_float:
    lw   $t0, buffer_ptr
    l.s  $f0, zero
    l.s  $f1, ten
    li   $t2, 0

    skip_whitespace:
    lb   $t1, 0($t0)
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
    jr   $ra

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

    # --- compute MMSE ---
    # TODO

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
    la   $s1, filtered_samples 
    lw   $s2, NUM_SAMPLES      
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

# ---------------------------------------------------------
# computeCrosscorrelation(desired[], input[], crosscorr[], N)
# ---------------------------------------------------------
computeCrosscorrelation:
    # TODO

# ---------------------------------------------------------
# createToeplitzMatrix(autocorr[], R[][], N)
# ---------------------------------------------------------
createToeplitzMatrix:
    # TODO

# ---------------------------------------------------------
# solveLinearSystem(A[][], b[], x[], N)
# ---------------------------------------------------------
solveLinearSystem:
    # TODO

# ---------------------------------------------------------
# applyWienerFilter(input[], coefficients[], output[], N)
# ---------------------------------------------------------
applyWienerFilter:
    # TODO

# ---------------------------------------------------------
# computeMMSE(desired[], output[], N) -> $f0
# ---------------------------------------------------------
computeMMSE:
    # TODO

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
