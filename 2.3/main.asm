.data
output_file:  .asciiz "output.txt"
NUM_SAMPLES:  .word 10
ouput:        .float 0.449, 0.551, -0.449, -0.551, 0.01, -0.01, 1.025, -10.22, -0.05, 0.05
mmse:         .float 0.2510

## 
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

# TODO

.text
.globl main

main:
   # --- Open output file ---
    ## TODO

    # --- Write "Filtered output: " ---
    ## TODO

    # --- Write filtered outputs with 1 decimal ---
    ## TODO
    # --- Write "\nMMSE: " ---
    ## TODO

    # --- Write MMSE with 2 decimals ---
    ## TODO

    # --- Close output file ---
    li   $v0, 16
    move $a0, $s0
    syscall

    li   $v0, 10
    syscall


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

# ---------------------------------------------------------
# float_to_str(buffer $a0, value $f12, decimals $a1) -> length $v0
# ---------------------------------------------------------
float_to_str:
    ## TODO