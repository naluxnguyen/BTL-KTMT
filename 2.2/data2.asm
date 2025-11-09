.data
desired: .float 1.5, 2.8, 3.2
input:   .float 1.2, 2.5, 3.0
NUM_SAMPLES: .word 3

# --- output arrays ---
crosscorr:   .space 12        # 3 floats
autocorr:    .space 12        # 3 floats
R:           .space 36        # 3x3 floats
coeff:       .space 12        # 3 floats
ouput:       .space 12        # 3 floats
SIZE_PRINT:  .word 6
header_msg:  .asciiz "Data 2: \n"