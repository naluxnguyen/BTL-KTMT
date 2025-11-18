.data
input_file:   .asciiz "input.txt"
desired_file: .asciiz "desired.txt"
output_file:  .asciiz "output.txt"
buf_size:     .word 32768
buffer:       .space 32768
NUM_SAMPLES:  .word 10
desired:      .space 40
input:        .space 40
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
error_open:   .asciiz "Error: Can not open file"
error_size:   .asciiz "Error: size not match"

.text
.globl main

main:
    # --- Open and read input file for input[] ---
    # TODO

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

    # --- Write "Filtered output: " ---
    # TODO

    # --- Write "\nMMSE: " ---
    # TODO

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