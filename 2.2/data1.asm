.data
desired: .float 2.0, 3.0
input:   .float 2.5, 2.8
NUM_SAMPLES: .word 2

# --- output arrays ---
crosscorr:   .space 8        # 2 floats
autocorr:    .space 8        # 2 floats
R:           .space 16       # 2x2 floats
coeff:       .space 8        # 2 floats
ouput:       .space 8        # 2 floats
SIZE_PRINT:  .word 4
header_msg:  .asciiz "Data 1: \n"