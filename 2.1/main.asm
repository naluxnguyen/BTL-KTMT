.data
# Result DATA1 6.7 3.75 7.045 3.5 7.045 3.5 3.5 7.045
https://www.overleaf.com/project/691062f244a125d24c484bfc
.include "data1.asm"
 
# Result DATADATA2 6.1333337 3.7866669 1.2800001 5.5633335 3.5 1.2 5.5633335 3.5 1.2 3.5 5.5633335 3.5 1.2 3.5 5.5633335
https://www.overleaf.com/project/691064285c229c7376c617ca
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
    ## TODO computeAutocorrelation

    # --- create Toeplitz matrix ---
    ## TODO createToeplitzMatrix

    # --- print ---
    la   $t0, crosscorr   # base address của mảng đầu tiên (crosscorr)
    li   $t1, 0          # index
    lw   $t2, SIZE_PRINT
print_loop:
    beq  $t1, $t2, done
    lwc1 $f12, 0($t0)
    li   $v0, 2
    syscall
    li   $v0, 11
    la   $a0, 32     # space
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
    ## TODO

# ---------------------------------------------------------
# computeCrosscorrelation(desired[], input[], crosscorr[], N)
# ---------------------------------------------------------
computeCrosscorrelation:
    ## TODO

# ---------------------------------------------------------
# createToeplitzMatrix(autocorr[], R[][], N)
# ---------------------------------------------------------
createToeplitzMatrix:
    ## TODO
