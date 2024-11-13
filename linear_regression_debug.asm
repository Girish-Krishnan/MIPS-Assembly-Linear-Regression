####################################
# Linear Regression in MIPS Assembly
# Girish Krishnan
###################################

    .data
file_path:      .asciiz "./data.txt"  # File path for x and y values
buffer:         .space 256                  # Buffer to store data read from file
line1:          .space 128                  # First line storage (x-values)
line2:          .space 128                  # Second line storage (y-values)
.align 2                                  # Ensure word alignment for float storage
x_vals:         .space 128                   # Array to store floats from the first line (x-values)
.align 2
y_vals:         .space 128                   # Array to store floats from the second line (y-values)
newline:        .asciiz "\n"                # Newline for output formatting
first_line_msg: .asciiz "First line:\n"     # Message for first line
second_line_msg: .asciiz "Second line:\n"   # Message for second line
equation:       .asciiz "\nThe resulting regression equation is: y = "
wx_plus_b:      .asciiz " * x + "
float_msg:      .asciiz "Float: "
mse_msg: .asciiz "Mean Squared Error (MSE): "
alpha:          .float 0.001                # Learning rate
w:              .float 0.0                  # Weight initialization
b:              .float 0.0                  # Bias initialization
m:              .word 0                     # Number of data points (initialized to 0, but will be updated based on data.txt)
iterations:     .word 3                # Number of SGD iterations
debug_msg_x:     .asciiz "\nDebug x_i: "
debug_msg_y:     .asciiz "\nDebug y_i: "
debug_msg_wb:    .asciiz "\nDebug w and b: "
debug_msg_f8:    .asciiz "\nDebug (wx + b - y): "

.text
.globl main
main:
    # Open the file for reading
    li $v0, 13                             # Syscall for open file
    la $a0, file_path                      # File path
    li $a1, 0                              # Mode 0 = read-only
    li $a2, 0                              # Flags
    syscall
    move $t0, $v0                          # Store file descriptor in $t0

    # Check if file was opened successfully
    bgez $t0, read_file                    # If fd >= 0, go to read_file
    li $v0, 10                             # If open failed, exit
    syscall

read_file:
    # Initialize pointers and counters
    la $s0, line1                          # Pointer to line1 (x-values)
    la $s1, line2                          # Pointer to line2 (y-values)
    li $t1, 1                              # Line counter (1 for first line, 2 for second line)

    # Read from file until two lines are read or EOF
    li $v0, 14                             # Syscall for read file
    move $a0, $t0                          # File descriptor
    la $a1, buffer                         # Address of buffer
    li $a2, 256                            # Maximum number of bytes to read
    syscall

    # Check if we reached EOF
    blez $v0, close_file                   # If no bytes read, close file and exit

    # Process the buffer to separate lines
    move $t2, $v0                          # $t2 holds the number of bytes read
    la $t3, buffer                         # $t3 points to the start of buffer

copy_lines:
    lb $t4, 0($t3)                         # Load a byte from buffer
    beq $t4, 0xA, new_line                 # If newline ('\n'), go to new_line
    beq $t4, 0, close_file                 # If null terminator, close file and exit

    # Copy character to line1 or line2 based on line counter
    beq $t1, 1, copy_to_line1              # If first line, copy to line1
    beq $t1, 2, copy_to_line2              # If second line, copy to line2

next_char:
    addi $t3, $t3, 1                       # Move to next character in buffer
    subi $t2, $t2, 1                       # Decrease byte counter
    bgtz $t2, copy_lines                   # If more bytes, keep processing
    j close_file                           # If finished reading buffer, close file

copy_to_line1:
    sb $t4, 0($s0)                         # Store character in line1
    addi $s0, $s0, 1                       # Move to next position in line1
    j next_char                            # Go back to process next character

copy_to_line2:
    sb $t4, 0($s1)                         # Store character in line2
    addi $s1, $s1, 1                       # Move to next position in line2
    j next_char                            # Go back to process next character

new_line:
    # Switch to the next line
    addi $t1, $t1, 1                       # Increment line counter
    beq $t1, 3, close_file                 # If we've read two lines, exit

    # Move to the next character after newline
    addi $t3, $t3, 1                       # Move to next character in buffer
    subi $t2, $t2, 1                       # Decrease byte counter
    bgtz $t2, copy_lines                   # If more bytes, keep processing
    j close_file                           # If finished reading buffer, close file

close_file:
    # Null-terminate line1 and line2
    sb $zero, 0($s0)                       # Null-terminate line1
    sb $zero, 0($s1)                       # Null-terminate line2

    # Close the file
    li $v0, 16                             # Syscall for close file
    move $a0, $t0                          # File descriptor
    syscall

    # Parse and store floats in x_vals and y_vals
    la $a0, line1                          # Parse line1
    la $a1, x_vals                         # Store floats from line1 (x-values)
    jal parse_floats                       # Call parse_floats for x_vals
    
    # Store the number of parsed floats (inferred m) into m
    sw $t8, m                              # Save the count in m
    
    la $t0, m           		   # Load the address of m
    lw $a0, 0($t0)      		   # Load the value of m into $a0
    li $v0, 1           		   # Syscall code for printing an integer
    syscall             		   # Execute syscall to print the value of m

    la $a0, line2                          # Parse line2
    la $a1, y_vals                         # Store floats from line2 (y-values)
    jal parse_floats                       # Call parse_floats for y_vals

    # Now perform linear regression using the parsed x and y values
    # Load learning rate into register
    la   $t0, alpha
    lwc1 $f0, 0($t0)

    # Initialize weight (w) and bias (b) to 0
    la   $t1, w
    lwc1 $f1, 0($t1)
    la   $t2, b
    lwc1 $f2, 0($t2)

    # Initialize outer loop counter (for iterations)
    li   $t9, 0              # Iteration counter
    la   $t8, iterations     # Load the number of iterations
    lw   $t8, 0($t8)         # Store number of iterations in $t8

outer_loop:
    # Exit outer loop if we have completed all iterations
    bge  $t9, $t8, done_iterations

    # Initialize loop counter (i = 0) and load number of data points
    li   $s0, 0
    la   $s1, m
    lw   $s1, 0($s1)      # Load m into $s1

inner_loop:
    # Exit inner loop if we have processed all data points
    bge  $s0, $s1, end_inner_loop

    # Load current x and y values (x_i and y_i)
    la   $t3, x_vals
    la   $t4, y_vals
    sll  $t7, $s0, 2        # Compute offset for current x_i, y_i
    add  $t3, $t3, $t7      # Address of x_i
    add  $t4, $t4, $t7      # Address of y_i
    lwc1 $f3, 0($t3)        # Load x_i
    lwc1 $f4, 0($t4)        # Load y_i

    # Debug: Print x_i
    li $v0, 4               # Print string syscall
    la $a0, debug_msg_x
    syscall
    li $v0, 2               # Print float syscall
    mov.s $f12, $f3         # Load x_i into $f12
    syscall

    # Debug: Print y_i
    li $v0, 4               # Print string syscall
    la $a0, debug_msg_y
    syscall
    li $v0, 2               # Print float syscall
    mov.s $f12, $f4         # Load y_i into $f12
    syscall

    # Calculate (wx + b - y)
    mul.s $f5, $f1, $f3     # f5 = w * x_i
    add.s $f5, $f5, $f2     # f5 = w * x_i + b
    sub.s $f8, $f5, $f4     # f8 = (wx + b - y)

    # Debug: Print (wx + b - y)
    li $v0, 4               # Print string syscall
    la $a0, debug_msg_f8
    syscall
    li $v0, 2               # Print float syscall
    mov.s $f12, $f8         # Load f8 into $f12
    syscall

    # Calculate gradients
    mul.s $f5, $f8, $f3     # gradient_w = (wx + b - y) * x_i
    mov.s $f6, $f8          # gradient_b = (wx + b - y)

    # Update w: w = w - alpha * gradient_w
    mul.s $f7, $f0, $f5     # alpha * gradient_w
    sub.s $f1, $f1, $f7     # w = w - alpha * gradient_w

    # Update b: b = b - alpha * gradient_b
    mul.s $f7, $f0, $f6     # alpha * gradient_b
    sub.s $f2, $f2, $f7     # b = b - alpha * gradient_b

    # Debug: Print w and b
    li $v0, 4               # Print string syscall
    la $a0, debug_msg_wb
    syscall
    li $v0, 2               # Print float syscall
    mov.s $f12, $f1         # Load w into $f12
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall
    
    li $v0, 2               # Print float syscall
    mov.s $f12, $f2         # Load b into $f12
    syscall

    # Increment loop counter and continue
    addi $s0, $s0, 1
    j inner_loop

end_inner_loop:
    # Increment outer loop iteration counter
    addi $t9, $t9, 1
    j outer_loop

done_iterations:
    # Print the final regression equation
    li   $v0, 4              # Print string syscall
    la   $a0, equation
    syscall

    # Print the value of w
    li   $v0, 2              # Print float syscall
    mov.s $f12, $f1         # Load w into $f12
    syscall

    # Print the string " * x + "
    li   $v0, 4
    la   $a0, wx_plus_b
    syscall

    # Print the value of b
    li   $v0, 2              # Print float syscall
    mov.s $f12, $f2         # Load w into $f12
    syscall

    # Print a newline
    li   $v0, 4
    la   $a0, newline
    syscall

     # Initialize variables for MSE calculation
    li $t9, 0                   # Reset outer loop counter
    li $s0, 0                   # Initialize loop counter (for data points)
    la $s1, m                   # Load the number of data points
    lw $s1, 0($s1)              # Load m into $s1 (number of points)

    # Initialize sum of squared errors to zero
    mtc1 $zero, $f10            # $f10 will hold the sum of squared errors

mse_loop:
    # Check if we have processed all data points
    bge $s0, $s1, mse_done

    # Load current x and y values (x_i and y_i)
    la $t3, x_vals
    la $t4, y_vals
    sll $t7, $s0, 2             # Compute offset for current x_i, y_i
    add $t3, $t3, $t7           # Address of x_i
    add $t4, $t4, $t7           # Address of y_i
    lwc1 $f3, 0($t3)            # Load x_i into $f3
    lwc1 $f4, 0($t4)            # Load y_i into $f4

    # Calculate predicted y (w * x_i + b)
    mul.s $f5, $f1, $f3         # f5 = w * x_i
    add.s $f5, $f5, $f2         # f5 = w * x_i + b

    # Calculate error = (w * x_i + b) - y_i
    sub.s $f6, $f5, $f4         # f6 = error

    # Calculate squared error = error^2
    mul.s $f7, $f6, $f6         # f7 = error^2

    # Accumulate squared errors: sum += error^2
    add.s $f10, $f10, $f7       # $f10 = sum of squared errors

    # Increment loop counter and continue
    addi $s0, $s0, 1
    j mse_loop

mse_done:
    # Calculate MSE by dividing sum of squared errors by m
    mtc1 $s1, $f8               # Move m into $f8 as float
    cvt.s.w $f8, $f8            # Convert integer m to float
    div.s $f9, $f10, $f8        # f9 = MSE = sum of squared errors / m

    # Print the MSE
    la $a0, newline             # Print newline for formatting
    li $v0, 4
    syscall

    la $a0, newline             # Message for clarity
    li $v0, 4
    syscall

    la $a0, mse_msg             # Message for MSE
    li $v0, 4
    syscall

    mov.s $f12, $f9             # Load MSE result into $f12 for printing
    li $v0, 2                   # Syscall to print float
    syscall

    # Exit program
    li $v0, 10
    syscall

# Parses a line of space-separated numbers into floats
# Parses a line of space-separated numbers into floats and counts them
parse_floats:
    # Initialize pointers and variables
    li $t0, 1                      # $t0 - parsing integer part (1) or fraction part (0)
    li $t1, 0                      # Integer part accumulator
    li $t2, 1                      # Fractional multiplier divisor
    li $t3, 0                      # Sign flag (0 for positive, 1 for negative)
    li $t6, 0                      # Fractional accumulator
    li $t8, 0                      # Initialize count for parsed floats
    move $t4, $a0                  # $t4 - pointer to the start of the line
    move $t5, $a1                  # $t5 - pointer to float storage array (x_vals or y_vals)

parse_char:
    lb $t7, 0($t4)                 # Load the current character
    beq $t7, 0, end_parse_floats   # If end of string, end parsing
    addi $t4, $t4, 1               # Move to next character

    # Check if character is a space (delimiter between numbers)
    beq $t7, 32, store_float       # If space, store the float and reset accumulators

    # Check if character is a minus sign
    beq $t7, 45, set_negative

    # Check if character is a decimal point
    beq $t7, 46, start_fraction

    # Check if character is a digit
    blt $t7, 48, parse_char        # Skip if not a digit (ASCII '0' = 48)
    bgt $t7, 57, parse_char        # Skip if not a digit (ASCII '9' = 57)

    # Parsing integer part
    beq $t0, 0, parse_fraction     # If parsing fraction, jump to fraction handling
    subi $t7, $t7, 48              # Convert ASCII to integer
    mul $t1, $t1, 10               # Multiply current integer by 10
    add $t1, $t1, $t7              # Add current digit

    j parse_char                   # Continue to next character

set_negative:
    li $t3, 1                      # Set sign flag to negative
    j parse_char                   # Continue to next character

start_fraction:
    li $t0, 0                      # Switch to parsing fraction part
    j parse_char                   # Continue to next character

parse_fraction:
    subi $t7, $t7, 48              # Convert ASCII to integer
    mul $t6, $t6, 10               # Increase fractional accumulator
    add $t6, $t6, $t7              # Add current digit to fractional part
    mul $t2, $t2, 10               # Adjust divisor for fraction
    j parse_char                   # Continue to next character

store_float:
    # Convert integer part to floating-point
    mtc1 $t1, $f0                  # Move integer part to $f0 register
    cvt.s.w $f0, $f0               # Convert integer to float

    # Handle fractional part if it exists
    bne $t2, 1, process_fraction   # If divisor != 1, process fraction
    j finalize_float               # If no fraction, skip to finalize

process_fraction:
    mtc1 $t6, $f1                  # Move fractional accumulator to $f1
    cvt.s.w $f1, $f1               # Convert fraction to float
    mtc1 $t2, $f2                  # Move divisor to $f2
    cvt.s.w $f2, $f2               # Convert divisor to float
    div.s $f1, $f1, $f2            # Divide fraction by divisor
    add.s $f0, $f0, $f1            # Combine integer and fractional parts

finalize_float:
    # Apply sign if needed
    beqz $t3, positive_store       # If positive, skip to store
    neg.s $f0, $f0                 # Otherwise, negate the value

positive_store:
    swc1 $f0, 0($t5)               # Store float in memory
    addi $t5, $t5, 4               # Move to next float storage location

    # Increment count of parsed floats
    addi $t8, $t8, 1               # Increment the float counter

    # Reset variables for next number
    li $t1, 0                      # Reset integer part
    li $t6, 0                      # Reset fractional accumulator
    li $t2, 1                      # Reset divisor for fraction
    li $t3, 0                      # Reset sign flag
    li $t0, 1                      # Switch back to parsing integer part
    j parse_char                   # Continue parsing

end_parse_floats:
    jr $ra                          # Return from function