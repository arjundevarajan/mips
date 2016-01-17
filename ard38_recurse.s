# Arjun Devarajan
# 9/23/2015
# Homework #2: Problem 2 (MIPS and Recursion)
# Write a recursive version of strlen from C
# Read string input, find string length, print to screen using syscall

.data 
	strInput: .asciiz "Enter a string: \n" # First line printed to the screen
	buffer: .space 128 # Make a memory space called buffer with 128 bytes
	
.text
	.globl main
	
main:
	li $v0, 4 # When v0 = 4, syscall prints a string
	la $a0, strInput # Load strInput into a0
	syscall
	
	li $v0, 8 # When v0 = 8, syscall reads in the string
	la $a0, buffer # Make a0 contain the amount of space in buffer
	li $a1, 128 # Set the possible length of the input string to 128
	syscall
	
	addi $sp, $sp, -4 # Decrement stack pointer
	sw $s1, 0($sp) # Store s1 into the stack
	
	li $s1, -1 # Set initial length equal to 0
	
	jal strlen
	
	move $a0, $v0 # Move v0 into a0, which will get printed if syscall'd
	li $v0, 1 # When v0 = 1, syscall prints an integer at a0
	syscall
	
	lw $s1, 0($sp) # Release s1 from the stack
	addi $sp, $sp, 4 # Re-increment stack pointer
	
	j exit

strlen:
	addi $sp, $sp, -4 # Decrement stack pointer
	sw $s1, 0($sp) # Save each new instance of s1 into the stack
	lbu $t1, 0($a0)
	beqz $t1, base
	addi $a0, $a0, 1
	addi $s1, $s1, 1
	j strlen
	lw $s1, 0($sp) # Release each new instance of s1 out of the stack
	addi $sp, $sp, 4 # Re-increment stack pointer
	
base: 
	add $v0, $s1, $0
	jr $ra
	
exit:
	li $v0, 10 # When v0 = 10, syscall exits the program
	syscall
