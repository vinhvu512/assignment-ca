.data
    # File paths
    file_name_in: .asciiz "input_matrix.txt"    
    file_name_out: .asciiz "output_matrix.txt"  
    
    # Debug messages
    msg_opening: .asciiz "\nAttempting to open file...\n"
    msg_open_success: .asciiz "File opened successfully!\n"
    msg_read_success: .asciiz "\nFile read successfully. Bytes read: "
    msg_buffer_contents: .asciiz "\nBuffer contents:\n"
    msg_file_error: .asciiz "\nError: Could not open file!\n"
    msg_read_error: .asciiz "\nError: Could not read file!\n"
    msg_write_error: .asciiz "\nError: Could not write to output file!\n"
    msg_parse_start:        .asciiz "Starting to parse input numbers...\n"
    msg_error_N_range:      .asciiz "Error: N (Image Size) must be between 3 and 7.\n"
    msg_error_M_range:      .asciiz "Error: M (Kernel Size) must be between 2 and 4.\n"
    msg_error_p_range:      .asciiz "Error: p (Padding) must be between 0 and 4.\n"
    msg_error_s_range:      .asciiz "Error: s (Stride) must be between 1 and 3.\n"
    msg_error_relation_1:   .asciiz "Error: N + 2p must be greater than or equal to M.\n"
    msg_error_relation_2:   .asciiz "Error: (N + 2p - M) must be divisible by s.\n"
    msg_error_official_1: .asciiz "Error: size not match"
    msg_error_official_2: .asciiz "Error: stride not match"
    msg_result_dim: .asciiz "\nResult dimension: "
    msg_start_pos: .asciiz "Starting parse at position: "
    msg_parsing: .asciiz "\nParsing numbers...\n"
    msg_padding: .asciiz "\nApplying padding...\n"
    msg_convolving: .asciiz "\nPerforming convolution...\n"
    msg_writing: .asciiz "\nWriting results to file...\n"
    msg_comma: .asciiz ", "
    msg_pad_start: .asciiz "\nStarting padding process...\n"
    msg_pad_init: .asciiz "\nPadding initialized. Copying image...\n"
    msg_pad_complete: .asciiz "\nPadding complete!\n"
    msg_copy_debug: .asciiz "Copying from position ("
    msg_arrow: .asciiz ") -> "
    msg_float_parsed: .asciiz "Parsed float value: "
    msg_final_pad: .asciiz "\nFinal padded matrix:\n"
    msg_N: .asciiz "N = "
    msg_parse_image: .asciiz "\nParsing image matrix:\n"
    msg_parse_kernel: .asciiz "\nParsing kernel matrix:\n"
    msg_parsing_pos: .asciiz "Parsing position "
    msg_parsed_val: .asciiz "Parsed value: "
    msg_kernel_val: .asciiz "Kernel value: "
    msg_image_matrix: .asciiz "\nParsed image matrix:\n"
    msg_kernel_matrix: .asciiz "\nParsed kernel matrix:\n"
    msg_row: .asciiz " row\n"
    msg_equals: .asciiz " = "
    newline: .asciiz "\n"
    space: .asciiz " "
    
    # Data structures
    .align 2
    buffer_read: .space 102400                 # Buffer for file reading
    buffer_write: .space 102400                  # Buffer for writing output
    
    .align 2
    image: .float 0:49                        # Image matrix (7x7 max)
    
    .align 2
    kernel: .float 0:16                      # Kernel matrix (4x4 max)
    
    .align 2
    paddedImage: .float 0:1000                 # Padded image (supports up to 11x11)
    
    .align 2
    out: .float 0:196                         # Result matrix (supports up to 14x14)
    
    # Parameters
    .align 2
    N: .word 0                                # Image size
    M: .word 0                                # Kernel size
    p: .word 0                                # Padding
    s: .word 0                                # Stride
    resultDim: .word 0                        # Result dimension
    padded_size: .word 0
    total_elements: .word 0                      # Padded image size
    negative_flag: .byte 0
    
    # Constants for float operations
    zero_float: .float 0.0
    ten_float: .float 10.0
    point_one: .float 0.1
    epsilon_float: .float 0.5

    # Add to .data section
    msg_dimension_error: .asciiz "\nError: Invalid matrix dimensions!\n"
    msg_padding_error: .asciiz "\nError: Padding size too large for matrix!\n"

    # When number is positive
    # Check if very close to next decimal
    point_nine_nine: .float 0.9999999999999999999999
    one_float: .float 1.0

.text
.globl main

main:
    # Print opening message
    li $v0, 4
    la $a0, msg_opening
    syscall

    # Open input file
    li $v0, 13                # sys_open
    la $a0, file_name_in      # filename
    li $a1, 0                 # O_RDONLY
    li $a2, 0                 # mode (ignored for read)
    syscall

    # Check for file open errors
    bltz $v0, file_error
    move $s6, $v0             # Save file descriptor

    # Print success message
    li $v0, 4
    la $a0, msg_open_success
    syscall

    # Read file content
    li $v0, 14                # sys_read
    move $a0, $s6             # file descriptor
    la $a1, buffer_read       # buffer
    li $a2, 1024              # number of bytes
    syscall

    # Check for read errors
    bltz $v0, read_error
    move $s7, $v0             # Save bytes read

    # Print read success message
    li $v0, 4
    la $a0, msg_read_success
    syscall

    # Print bytes read
    li $v0, 1                 # print integer
    move $a0, $s7
    syscall

    # Print newline
    li $v0, 4
    la $a0, newline
    syscall

    # Print buffer contents
    li $v0, 4
    la $a0, msg_buffer_contents
    syscall

    li $v0, 4
    la $a0, buffer_read
    syscall

    # Close the input file
    li $v0, 16                # sys_close
    move $a0, $s6
    syscall

    # Debug message before parsing
    li $v0, 4
    la $a0, msg_parsing
    syscall

    # Parse numbers from buffer
    la $s0, buffer_read       # Pointer to buffer
    jal parse_numbers

    # Debug message before padding
    li $v0, 4
    la $a0, msg_padding
    syscall

    # Apply padding
    jal padded

    # Debug message before convolution
    li $v0, 4
    la $a0, msg_convolving
    syscall

    # Perform convolution
    jal convolution

    # Debug message before writing
    li $v0, 4
    la $a0, msg_writing
    syscall

    # Write results to file
    jal write_result

    # Exit program
    j exit_program

file_error:
    li $v0, 4
    la $a0, msg_file_error
    syscall
    j exit_program

read_error:
    li $v0, 4
    la $a0, msg_read_error
    syscall
    j exit_program

write_error:
    li $v0, 4
    la $a0, msg_write_error
    syscall
    j exit_program

parse_numbers:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # Debug - start parsing
    li $v0, 4
    la $a0, msg_parse_start
    syscall

    # Parse N (image size)
    jal get_next_float
    cvt.w.s $f0, $f0     # Convert float to integer (truncate)
    mfc1 $t0, $f0
    sw $t0, N            # Store N

    # Parse M (kernel size)
    jal get_next_float
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0
    sw $t0, M            # Store M

    # Parse p (padding)
    jal get_next_float
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0
    sw $t0, p            # Store p

    # Parse s (stride)
    jal get_next_float
    cvt.w.s $f0, $f0
    mfc1 $t0, $f0
    sw $t0, s            # Store s

    lw $t0, N
    lw $t1, M
    lw $t2, p
    lw $t3, s

    add $t0, $t0, $t2 # N + p
    add $t0, $t0, $t2 # N + p + p
    sub $t4, $t0, $t1 # N + p + p - M
    blt $t4, $zero, official_error_1

    # div $t4, $t3 # (N + p + p - M) / s
    # mfhi $t9
    # bne $t9, $zero, official_error_2


    # Parse image matrix (N x N)
    la $t1, image        # Image matrix address
    lw $t2, N            # Load N
    mul $t3, $t2, $t2    # Total elements N*N
    li $t4, 0            # Counter

image_loop:
    jal get_next_float
    swc1 $f0, 0($t1)     # Store float to image matrix

    addi $t1, $t1, 4     # Next position
    addi $t4, $t4, 1     # Increment counter
    blt $t4, $t3, image_loop

    # Parse kernel matrix (M x M)
    la $t1, kernel       # Kernel matrix address
    lw $t2, M            # Load M
    mul $t3, $t2, $t2    # Total elements M*M
    li $t4, 0            # Reset counter

kernel_loop:
    jal get_next_float
    swc1 $f0, 0($t1)     # Store float to kernel matrix

    addi $t1, $t1, 4     # Next position
    addi $t4, $t4, 1     # Increment counter
    blt $t4, $t3, kernel_loop

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

get_next_float:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $s5, 0($sp)

    li $s1, 0          # int_part = 0
    li $s2, 0          # dec_part = 0
    li $s3, 1          # dec_scale = 1
    li $s4, 0          # decimal_flag = 0
    li $s5, 0          # sign_flag = 0

skip_spaces_float:
    lb $t6, ($s0)
    beq $t6, ' ', next_space_float
    beq $t6, '\n', next_space_float
    beq $t6, '\r', next_space_float   # Handle carriage return
    j parse_float
next_space_float:
    addi $s0, $s0, 1
    j skip_spaces_float

parse_float:
    lb $t6, ($s0)
    beq $t6, '-', set_negative
    j check_end_float

set_negative:
    li $s5, 1
    addi $s0, $s0, 1
    j parse_float

check_end_float:
    # Check for end of number
    beq $t6, ' ', end_float
    beq $t6, '\n', end_float
    beq $t6, '\r', end_float
    beq $t6, '\0', end_float
    beq $t6, -1, end_float

    # Check for decimal point
    beq $t6, '.', set_decimal

    # Convert digit
    subi $t6, $t6, '0'     # t6 = digit

    beqz $s4, before_decimal

    # After decimal point
    mul $s2, $s2, 10       # dec_part *= 10
    add $s2, $s2, $t6      # dec_part += digit
    mul $s3, $s3, 10       # dec_scale *= 10

    j next_char

before_decimal:
    mul $s1, $s1, 10       # int_part *= 10
    add $s1, $s1, $t6      # int_part += digit
    j next_char

set_decimal:
    li $s4, 1              # decimal_flag = 1
    j next_char

next_char:
    addi $s0, $s0, 1       # Move to next char
    j parse_float

end_float:
    # Convert int_part to float
    mtc1 $s1, $f0
    cvt.s.w $f0, $f0

    # If decimal_flag == 1
    beqz $s4, finish_get_float

    # Convert dec_part to float
    mtc1 $s2, $f2
    cvt.s.w $f2, $f2
    # Convert dec_scale to float
    mtc1 $s3, $f4
    cvt.s.w $f4, $f4
    # Compute decimal part: dec_part / dec_scale
    div.s $f2, $f2, $f4
    # Add decimal part to int_part
    add.s $f0, $f0, $f2

finish_get_float:
    beqz $s5, skip_negate
    neg.s $f0, $f0
skip_negate:
    lw $s5, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24
    jr $ra


# Function to apply padding
padded:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)

    # Load N and p
    lw $s1, N               # $s1 = N
    lw $s2, p               # $s2 = p

    # Compute padded_size = N + 2*p
    sll $t0, $s2, 1         # $t0 = 2 * p
    add $s0, $s1, $t0       # $s0 = N + 2p (padded_size)

    # Validate padded size
    li $t1, 15
    bgt $s0, $t1, padding_error
    
    # Continue with padding...
    j continue_padding

padding_error:
    li $v0, 4
    la $a0, msg_padding_error
    syscall
    j exit_program

continue_padding:

    # Save padded_size to memory for use in other functions
    sw $s0, padded_size

    # Initialize padded image with zeros
    li $t1, 0               # row index = 0
    l.s $f4, zero_float     # Load 0.0 into $f4

init_padded_loop_i:
    li $t2, 0               # column index = 0
init_padded_loop_j:
    la $t3, paddedImage
    mul $t4, $t1, $s0       # $t4 = row * padded_size
    add $t4, $t4, $t2       # $t4 = row * padded_size + col
    sll $t4, $t4, 2         # $t4 *= 4 (word size)
    add $t5, $t3, $t4
    swc1 $f4, 0($t5)        # paddedImage[row][col] = 0.0

    addi $t2, $t2, 1        # col += 1
    blt $t2, $s0, init_padded_loop_j

    addi $t1, $t1, 1        # row += 1
    blt $t1, $s0, init_padded_loop_i

    # Copy the original image into the padded image starting from (p, p)
    li $t1, 0               # row index in image
copy_image_loop_i:
    li $t2, 0               # col index in image
copy_image_loop_j:
    # Load from image
    la $t3, image
    mul $t4, $t1, $s1       # $t4 = row * N
    add $t4, $t4, $t2       # $t4 = row * N + col
    sll $t4, $t4, 2         # $t4 *= 4
    add $t5, $t3, $t4
    lwc1 $f5, 0($t5)        # $f5 = image[row][col]

    # Store into paddedImage at position (row + p, col + p)
    la $t3, paddedImage
    add $t6, $t1, $s2       # $t6 = row + p
    mul $t7, $t6, $s0       # $t7 = (row + p) * padded_size
    add $t8, $t2, $s2       # $t8 = col + p
    add $t7, $t7, $t8       # $t7 = (row + p) * padded_size + (col + p)
    sll $t7, $t7, 2         # $t7 *= 4
    add $t5, $t3, $t7
    swc1 $f5, 0($t5)        # paddedImage[row+p][col+p] = image[row][col]

    addi $t2, $t2, 1        # col += 1
    blt $t2, $s1, copy_image_loop_j

    addi $t1, $t1, 1        # row += 1
    blt $t1, $s1, copy_image_loop_i

    # Restore saved registers and return
    lw $s3, 0($sp)
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# Function to apply kernel at position
applyKernel:
    addi $sp, $sp, -40          # Allocate 40 bytes
    sw $ra, 36($sp)
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    sw $s3, 20($sp)
    sw $s4, 16($sp)
    sw $s5, 12($sp)
    sw $s6, 8($sp)

    lw $s5, padded_size         # Load padded_size
    lw $s6, M                   # Load M

    sw $a0, 4($sp)              # Save startRow at 4($sp)
    sw $a1, 0($sp)              # Save startCol at 0($sp)

    l.s $f2, zero_float         # Initialize sum = 0.0
    li $t3, 0                   # Initialize ki = 0

kernel_loop_i:
    li $t4, 0                   # Initialize kj = 0

kernel_loop_j:
    # Calculate row and column indices
    lw $a0, 4($sp)              # Load startRow
    lw $a1, 0($sp)              # Load startCol
    add $s0, $a0, $t3           # row = startRow + ki
    add $s1, $a1, $t4           # col = startCol + kj

    # Calculate paddedImage address
    la $t5, paddedImage
    mul $t6, $s0, $s5           # $t6 = row * padded_size
    add $t6, $t6, $s1           # $t6 = (row * padded_size) + col
    sll $t6, $t6, 2             # $t6 *= 4
    add $t7, $t5, $t6
    lwc1 $f4, 0($t7)            # Load paddedImage value

    # Calculate kernel address
    la $t5, kernel
    mul $t6, $t3, $s6           # $t6 = ki * M
    add $t6, $t6, $t4           # $t6 = ki * M + kj
    sll $t6, $t6, 2             # $t6 *= 4
    add $t7, $t5, $t6
    lwc1 $f6, 0($t7)            # Load kernel value

    # Multiply and accumulate
    mul.s $f4, $f4, $f6         # Multiply values
    add.s $f2, $f2, $f4         # Add to sum

    addi $t4, $t4, 1
    blt $t4, $s6, kernel_loop_j

    addi $t3, $t3, 1
    blt $t3, $s6, kernel_loop_i

    # Return sum in $f0
    mov.s $f0, $f2

    # Restore saved registers and return
    lw $s6, 8($sp)
    lw $s5, 12($sp)
    lw $s4, 16($sp)
    lw $s3, 20($sp)
    lw $s2, 24($sp)
    lw $s1, 28($sp)
    lw $s0, 32($sp)
    lw $ra, 36($sp)
    addi $sp, $sp, 40
    jr $ra

# Function to perform convolution
convolution:
    addi $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $s6, 0($sp)

    # Load parameters
    lw $s1, s               # $s1 = stride
    lw $s3, M               # $s3 = M
    lw $s5, padded_size     # $s5 = padded_size

    # Calculate result dimension
    sub $t0, $s5, $s3       # t0 = padded_size - M
    div $t0, $t0, $s1       # t0 = (padded_size - M) / stride
    mflo $t0
    addi $t0, $t0, 1        # t0 += 1
    sw $t0, resultDim       # Store result dimension

    li $v0, 4
    la $a0, msg_result_dim
    syscall

    li $v0, 1
    lw $a0, resultDim
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $t6, 0               # i = 0
convolution_loop_i:
    lw $t5, resultDim
    bge $t6, $t5, end_convolution
    mul $a0, $t6, $s1       # startRow = i * stride

    li $t7, 0               # j = 0
convolution_loop_j:
    lw $t5, resultDim
    bge $t7, $t5, next_i
    mul $a1, $t7, $s1       # startCol = j * stride

    # Save registers
    addi $sp, $sp, -8
    sw $t6, 0($sp)
    sw $t7, 4($sp)

    jal applyKernel

    # Restore registers
    lw $t6, 0($sp)
    lw $t7, 4($sp)
    addi $sp, $sp, 8

    l.s $f2, ten_float
    
    # Check if result is zero
    mtc1 $zero, $f4           # Load 0.0 into $f4
    c.eq.s $f0, $f4           # Compare if result == 0
    bc1t store_result         # If zero, skip adjustment
    
    # Check if result is negative
    c.lt.s $f0, $f4           # Compare if result < 0
    bc1t adjust_negative      # If negative, branch
    
    mul.s $f0, $f0, $f2      # result *= 10.0
    l.s $f2, epsilon_float
    add.s $f0, $f0, $f2      # result += 0.05
    # cvt.w.s $f4, $f0
    # cvt.s.w $f4, $f4
    # sub.s $f6, $f0, $f4
    # l.s $f7, point_nine_nine
    # c.lt.s $f7, $f6
    # bc1t round_up

    cvt.w.s $f0, $f0
    cvt.s.w $f0, $f0
    l.s $f2, ten_float
    div.s $f0, $f0, $f2
    j store_result

# round_up:
#     cvt.w.s $f4, $f0
#     cvt.s.w $f0, $f4
#     l.s $f7, one_float
#     add.s $f0, $f0, $f7
#     div.s $f0, $f0, $f2
#     j store_result

adjust_negative:
    # Negative case: subtract epsilon
    mul.s $f0, $f0, $f2      # result -= 0.05
    l.s $f2, epsilon_float
    sub.s $f0, $f0, $f2      # result -= 0.05
    
    # Get absolute value for comparison
    # abs.s $f4, $f0
    # cvt.w.s $f6, $f4         # Convert abs value to int
    # cvt.s.w $f6, $f6         # Back to float
    # sub.s $f8, $f4, $f6      # Get decimal part
    
    # # If decimal part > 0.99, round down (more negative)
    # l.s $f10, point_nine_nine
    # c.lt.s $f10, $f8         # If 0.99 < decimal part
    # bc1t round_down_neg
    
    # Otherwise round towards zero
    cvt.w.s $f0, $f0         # Convert to int (truncate)
    cvt.s.w $f0, $f0         # Back to float
    l.s $f2, ten_float
    div.s $f0, $f0, $f2      # Divide by 10
    j store_result

# round_down_neg:
#     cvt.w.s $f0, $f0         # Convert to int (truncate)
#     cvt.s.w $f0, $f0         # Back to float
#     l.s $f8, one_float       # Load 1.0
#     sub.s $f0, $f0, $f8      # Subtract 1 (make more negative)
#     div.s $f0, $f0, $f2      # Divide by 10
#     j store_result

store_result:
    # Store result
    la $t8, out
    lw $t9, resultDim
    mul $t9, $t6, $t9
    add $t9, $t9, $t7
    sll $t9, $t9, 2
    add $t8, $t8, $t9
    swc1 $f0, 0($t8)

    addi $t7, $t7, 1
    j convolution_loop_j

next_i:
    addi $t6, $t6, 1
    j convolution_loop_i

end_convolution:
    # Debug print all elements of out matrix
    la $t0, out              # Load address of out matrix
    lw $t1, resultDim        # Load result dimension
    mul $t1, $t1, $t1        # Total elements = resultDim * resultDim
    li $t2, 0                # Counter

print_loop:
    bge $t2, $t1, restore_and_return   # If counter >= total elements, exit loop
    
    # Print float value
    li $v0, 2                # Print float syscall
    lwc1 $f12, ($t0)         # Load float from out matrix
    syscall
    
    # Print space
    li $v0, 4
    la $a0, space            # Assuming you have a space string defined
    syscall
    
    addi $t0, $t0, 4         # Move to next float
    addi $t2, $t2, 1         # Increment counter
    j print_loop

restore_and_return:
    # Print newline
    li $v0, 4
    la $a0, newline          # Assuming you have a newline string defined
    syscall

    # Restore saved registers and return
    lw $s6, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
    jr $ra

write_result:
    addi $sp, $sp, -24       # Allocate stack space
    sw $s0, 0($sp)           # Save $s0
    sw $s1, 4($sp)           # Save $s1
    sw $s2, 8($sp)           # Save $s2
    sw $s3, 12($sp)          # Save $s3
    sw $s4, 16($sp)          # Save $s5
    sw $s5, 20($sp)          # Save $ra

    # Open output file
    li $v0, 13               # sys_open
    la $a0, file_name_out
    li $a1, 1                # Write mode
    li $a2, 0
    syscall
    bltz $v0, write_error
    move $s6, $v0            # Save file descriptor

    # Write matrix elements
    lw $t0, resultDim        # Load dimension (N)
    mul $t1, $t0, $t0        # Total elements = N * N
    sw $t1, total_elements
    la $t2, out              # Result matrix address
    li $t3, 0                # Counter

write_matrix_loop:
    # Check if all elements are written
    lw $t1, total_elements
    bge $t3, $t1, close_file
    # li $v0, 1
    # move $a0, $t3
    # syscall
    # Load float number
    lwc1 $f12, 0($t2)

    # Check if float is negative
    mtc1 $zero, $f10
    cvt.s.w $f10, $f10                # $f10 = 0.0
    c.le.s $f10, $f12                  # Compare $f12 >= 0.0
    bc1t not_negative   

    neg.s $f12, $f12
    li $s5, 1
    j convert_float 
not_negative:
    li $s5, 0

convert_float:
    # Convert float to string in buffer_write
    la $t4, buffer_write    
    beq $s5, 0, skip_negative_sign
    li $t9, '-'
    sb $t9, 0($t4)
    addi $t4, $t4, 1 
    sb $t9, negative_flag


skip_negative_sign:
    # Convert integer part
    cvt.w.s $f0, $f12
    mfc1 $t5, $f0

    # Convert integer to string (handle zero case)
    li $t8, 10               # Use $t8 instead of $t0 for constant 10
    move $t7, $t4            # $t7 points to buffer_write
    li $s0, 0                # Digit counter

    # Check if integer part is zero
    beqz $t5, handle_zero
    j convert_integer

handle_zero:
    li $t9, '0'
    sb $t9, 0($t7)
    addi $t7, $t7, 1
    addi $s0, $s0, 1
    j reverse_and_add_decimal

convert_integer:
    # Convert integer part to string in reverse order
int_to_str_loop:
    div $t5, $t8
    mfhi $t9
    addi $t9, $t9, '0'
    sb $t9, 0($t7)
    addi $t7, $t7, 1
    mflo $t5
    addi $s0, $s0, 1
    bnez $t5, int_to_str_loop
    j reverse_and_add_decimal

reverse_and_add_decimal:
    # Reverse the digits to get correct order
    move $s1, $t4            # $s1 = start of digits
    addi $s2, $t7, -1        # $s2 = end of digits


reverse_digits:
    bge $s1, $s2, reverse_done
    lb $s3, 0($s1)           # Load byte from start
    lb $t0, 0($s2)           # Load byte from end
    sb $t0, 0($s1)           # Store byte to start
    sb $s3, 0($s2)           # Store byte to end
    addi $s1, $s1, 1         # Increment start pointer
    addi $s2, $s2, -1        # Decrement end pointer
    j reverse_digits

reverse_done:
    move $s4, $t4            # $s4 points to the start of digits
    addi $s5, $t7, -1        # $s5 points to the end of digits

    # Add decimal point
    li $t9, '.'
    sb $t9, 0($t7)
    addi $t7, $t7, 1

    # Add one decimal place with rounding
    cvt.w.s $f0, $f12        # Convert integer part to float
    cvt.s.w $f2, $f0         # Convert back to float
    sub.s $f4, $f12, $f2     # Get decimal part
    l.s $f6, ten_float       # Load 10.0
    mul.s $f4, $f4, $f6      # Multiply decimal part by 10
    round.w.s $f0, $f4       # Round to nearest integer
    mfc1 $t9, $f0             # Move to $t9

    # Compare $t9 with 10
    li $t0, 10
    beq $t9, $t0, handle_carry_over
    # If not 10, proceed as usual

    # Convert the rounded decimal digit to character
    addi $t9, $t9, '0'        # Convert to ASCII
    sb $t9, 0($t7)            # Store the decimal digit
    addi $t7, $t7, 1
    j decide_space_or_newline

handle_carry_over:
    # Set decimal digit to '0'
    li $t9, '0'
    sb $t9, 0($t7)            # Store '0' as the decimal digit
    addi $t7, $t7, 1

    # Increment the integer part
    addi $s1, $s4, 0          # $s1 points to the start of digits
    addi $s2, $s5, 0          # $s2 points to the last digit

increment_loop:
    lb $t1, 0($s2)            # Load current digit
    addi $t1, $t1, 1          # Increment digit by 1
    sb $t1, 0($s2)            # Store back the incremented digit

    # Check if digit exceeds '9'
    li $t0, '.'
    beq $t1, $t0, handle_overflow_int_neg
    li $t0, '9' 
    ble $t1, $t0, increment_done
    # If digit > '9', set to '0' and carry over
    li $t9, '0'               # Use $t9 instead of $t1
    sb $t9, 0($s2)            # Set current digit to '0'
    addi $s2, $s2, -1         # Move to previous digit
    addi $sp, $sp, -4
    sw $s4, 0($sp)
    la $s4, buffer_write
    bge $s2, $s4, increment_loop
    lw $s4, 0($sp)
    addi $sp, $sp, 4

    # If all digits were '9', prepend '1'
    
    li $t9, '1'               # Use $t9 instead of $t1
    sb $t9, 0($t4)            # Prepend '1' at the start

handle_overflow_int:
    addi $sp, $sp, -8
    sw $s4, 0($sp)
    sw $s5, 4($sp)
    addi $s4, $t7, -2
    addi $s5, $t7, -1
    li $t9, '.'
    sb $t9, 0($s5)
    li $t9, '0'
    sb $t9, 0($s4)
    sb $t9, 1($s5)
    lw $s4, 0($sp)
    lw $s5, 4($sp)
    addi $t7, $t7, 1
    addi $sp, $sp, 8
    j decide_space_or_newline

handle_overflow_int_neg:
    lw $s4, 0($sp)
    addi $sp, $sp, 4
    addi $sp, $sp, -8
    sw $s4, 0($sp)
    sw $s5, 4($sp)
    li $t9, '-'
    sb $t9, -1($s4)
    li $t9, '1'
    sb $t9, 0($s4)
    li $t9, '0'
    sb $t9, 1($s4)
    li $t9, '.'
    sb $t9, 2($s4)
    li $t9, '0'
    sb $t9, 3($s4)
    addi $t7, $t7, 1
    lw $s4, 0($sp)
    lw $s5, 4($sp)
    addi $sp, $sp, 8
    j decide_space_or_newline
    

increment_done:
    # lw $s4, 0($sp)
    # addi $sp, $sp, 4
    # lb $t9, -1($s4)
    # beq $t9, '.', handle_overflow_int_neg
    j decide_space_or_newline

decide_space_or_newline:
    # Decide whether to add a space or newline
    addi $t5, $t3, 1          # t5 = counter + 1
    lw $t1, total_elements
    blt $t5, $t1, add_space  # If t5 < total elements, add space
    j write_number           # Else, add newline

add_space:
    # Add space
    li $t9, ' '
    sb $t9, 0($t7)
    addi $t7, $t7, 1
    j write_number


write_number:
    la $a1, buffer_write     # Start writing from the beginning (include '-')

    subu $a2, $t7, $a1        # Length = end - start

    # Write to file
    li $v0, 15               # sys_write
    move $a0, $s6            # File descriptor
    syscall

    addi $t2, $t2, 4         # Move to next float
    addi $t3, $t3, 1         # Increment counter
    lw $t1, total_elements
    blt $t3, $t1, write_matrix_loop

close_file:
    # Close the output file
    # li $v0, 1
    # move $a0, $t1
    # syscall
    li $v0, 16               # sys_close
    move $a0, $s6
    syscall

    # Restore saved registers
    lw $s0, 0($sp)           # Restore $s0
    lw $s1, 4($sp)           # Restore $s1
    lw $s2, 8($sp)           # Restore $s2
    lw $s3, 12($sp)          # Restore $s3
    lw $s4, 16($sp)          # Restore $s4
    lw $s5, 20($sp)          # Restore $s5
    addi $sp, $sp, 24        # Deallocate stack space
    
exit_program:
    li $v0, 10
    syscall

official_error_1:
    li $v0, 4
    la $a0, msg_error_official_1
    syscall
    
    li $v0, 13
    la $a0, file_name_out
    li $a1, 1
    li $a2, 0
    syscall

    bltz $v0, write_error
    move $s6, $v0

    # Write the error message
    li $v0, 15
    move $a0, $s6
    la $a1, msg_error_official_1
    li $a2, 21
    syscall

    # Close the output file
    li $v0, 16
    move $a0, $s6
    syscall
    j exit_program

official_error_2:
    li $v0, 4
    la $a0, msg_error_official_2
    syscall

    li $v0, 13
    la $a0, file_name_out
    li $a1, 1
    li $a2, 0
    syscall

    bltz $v0, write_error
    move $s6, $v0

    # Write the error message
    li $v0, 15
    move $a0, $s6
    la $a1, msg_error_official_2
    li $a2, 23
    syscall

    # Close the output file
    li $v0, 16
    move $a0, $s6
    syscall
    j exit_program
