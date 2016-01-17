# Arjun Devarajan
# 9/25/2015
# Homework #2: Problem 3 (MIPS and Most Valuable Player)
# Create a sorted linked list essentially
# Read lines of string input for player name, ppg, rpg, tpg, sort the (ppg + rpg)/tpg in descrending order, and the name of the MVP

.data
	buffer: .space 256 # Sets aside 256 bytes for each player's name length
	newLine: .asciiz "\n"
	newSpace: .asciiz " "
	textDone: .asciiz "DONE\n"
	.align 2
	
.text
	.globl main
	
main:
	jal createLinkedList # Go to createLinkedList
	j exit
	
createLinkedList:
	move $t7, $ra
	li $a0, 256 # Makes the size of that block of memory 264 (256 bytes for the player name, 4 for the float score, 4 for the next pointer)
	li $v0, 9 # Mallocs a block of memory
	syscall
	move $a0, $v0 # Moves the block of memory into s0
	jal readName # Go to readName
	jal readStats # Go to readEntries
	jal findScore # Go to findScore
	jal nextPtr # Add next pointer
	j createLinkedList
	move $ra, $t7
	jr $ra
	
readName:
	move $t5, $ra # Save the return address for readName into t7
	li $v0, 8 # When v0 = 8, syscall reads in an string from the console
	li $a1, 256 # Set the possible length of the input string to 256 characters (bytes)
	syscall
	la $a2, textDone # Set a2 equal to "DONE\n"
	move $s0, $a0 # Store a0 in temporary space s0
	addi $t0, $a0, 0  # Store a0 in t0
	addi $t1, $a2, 0 # Store a2 in t1
	jal stringCompare # Check to see if name = DONE
	li $a0, 264 # Makes space for temporary node
	li $v0, 9
	syscall
	move $s1, $v0 # Create node with size 264
	sw $s0, 0($s1) # Store the name (256 bytes) inside the node (264 bytes)
	move $ra, $t5 # Bring back the return address
	jr $ra # Go back to createLinkedList
	
stringCompare:
	lb $t2($t0) # Load first letter of player name
	lb $t3($t1) # Load first letter of "DONE\n"
	sub $t4, $t2, $t3 # Compare them
	bne $t4, $zero, different # If they're the different, move on
	beq $t2, $zero, validation # If they're the same, check to see if the player name is over
	addi $t0,$t0,1 # Go to the next letter of the player name 
	addi $t1,$t1,1 # Go to the next letter of "DONE\n"
	j stringCompare 

different:   
	jr $ra
	
validation:  
	bne $t3, $zero, different # If "DONE\n" is also over, move on
	la $s0, 0($s1) # If not, set s0 also equal to the head of the linked list and move to sorting and printing
	j createNegative

readStats:	
	li $v0, 6 # When v = 5, syscall reads in the ppg from the console
	syscall
	mov.s $f1, $f0 # Move the ppg to f1
	li $v0, 6 # When v = 5, syscall reads in the rpg from the console
	syscall
	mov.s $f2, $f0 # Move the rpg to f2	
	li $v0, 6 # When v = 5, syscall reads in the tpg from the console
	syscall
	mov.s $f3, $f0 # Move the tpg to f3
	jr $ra # return to main

findScore:
	add.s $f4, $f1, $f2 # ppg + rpg -> f4
	div.s $f4, $f4, $f3 # f4/tpg -> f4 = (ppg+rpg)/tpg; f4 = overall rating
	s.s $f4, 256($s1) # Store the player's overall rating from f4 into s0 at the 256th address
	jr $ra # return to main

nextPtr:
	sw $s2, 260($s1) # Add pointer to next node (s2) to s1
	move $s2, $s1 # curr = curr->next
	jr $ra # return to main

createNegative:
	li $t1, -1 # Create -1 register
	mtc1 $t1, $f7 # Convert it to a float
	cvt.s.w $f7, $f7
	li $t2, 0 # Create a counter register
	la $a3, newLine # Create a register that holds a new line

increment: # s1 is traversing pointer, s2 is pointer to highest scored player
	beq $s1, $zero, printNode # If s1 has reached the end of the list, print the node of the best player
	jal sort
	lw $s1, 260($s1) # Move s1 forward to the next player
	j increment
	
sort:
	l.s $f5, 256($s1) # Store s1 player's score
	l.s $f6, 256($s2) # Store s2 player's score
	c.lt.s $f6, $f5 # Compare them and set condition flag 0 = true if s2.score<s1.score
	bc1t updateLargest # If the flag is true, then s1 is the new lar
	jr $ra # move on to the next player

updateLargest:
	la $s2, 0($s1) # Change s2 to point to the new best player
	jr $ra

printNode:
	addi $t2, $t2, 1 # Increment the counter to show that it's the 1st best player
	lw $a0, 0($s2) # Set the highest player = a0
	l.s $f12, 256($s2) # Set their score = f12
	jal checkIfMVP # Check if that player is the MVP
	c.eq.s $f7, $f12 # Check if that player's score = -1, meaning if the list has been exhausted (then set condition flag 0 to true)
	bc1t printMVP # If the list has been exhausted (if condition flag 0 is true) then print the MVP at the end
	la $a1, 0($a0) # Store the current player's name in a1
	jal removeNewLine # Remove the automatic new line at the end of the player's name and substitute it with a null space
	li $v0, 4 # Print the player's name
	syscall
	la $a0, newSpace # Print the space between the player's name and their score
	li $v0, 4
	syscall
	li $v0, 2 # Print the player's score
	syscall
	move $a0, $a3 # Print a new line before the next player (or the MVP)
	li $v0, 4
	syscall
	s.s $f7, 256($s2) # Replace the printed player's score with -1 so it will no longer show up in the maximum search algorithm
	la $s1, 0($s0) # Reset s1 so it points to the head of the list
	j increment

checkIfMVP:
	beq $t2, 1, saveMVP # If the counter is at 1, player is MVP
	jr $ra

saveMVP:
	la $s3, 0($s2) # Set s3 as a temporary player register
	jr $ra

printMVP:
	lw $a0, 0($s3) # Store the MVP's name in a0
	li $v0, 4 # Print the MVP's name
	syscall
	j exit

removeNewLine:
	lb $t3, 0($a1) # Load the first character of the player's name
	addi $a1, $a1, 1 # Increment a1 by one to get to the next character
	bne $t3, $zero, removeNewLine # If you haven't reached the null terminator, repeat
	addi $a1, $a1, -2 # If you have, go back 2 spaces to the new line
	sb $zero, 0($a1) # And replace the new line with a new null terminator
	jr $ra # Return to the printing process

exit:
	li $v0, 10 # When v0 = 10, syscall exits the program
	syscall
	
