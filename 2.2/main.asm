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
    jr $ra

# ---------------------------------------------------------
# applyWienerFilter(input[], coefficients[], output[], N)
# ---------------------------------------------------------
applyWienerFilter:
    # TODO
    jr $ra