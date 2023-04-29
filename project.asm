.data
	#array that holds characters that user sees
	shownBoard: .space 480
	
	#array that holds characters of the full board
	hiddenBoard: .space 480
	
	#used when printing board
	newlineAndSpaces: .asciiz "\n  "
	spaceAndPipe: .asciiz "  |"
	
	#prompts for user input
	promptCommand: .asciiz "\nEnter 'd' to dig or 'f' to flag: "
	promptRow: .asciiz "Enter valid row number: "
	promptColumn: .asciiz "Enter valid column number: "
	
	promptDifficulty: .asciiz "Please select your difficulty\n1) Easy Peasy Lemon Sqeezy.\n2) Intermediate, watch your step!\n3) Expert, be sure to not sneeze!"
	promptDifficultyEnter: .asciiz "\nEnter Here: "


	#messages for end of game
	printWin: .asciiz "\nYou Win! :)"
	printLose: .asciiz "\nYou Lose! :("
	
.text

main:
	#treating s4-s7 as global constants, should not change througout program
	li $s4, 'O'
	li $s5, '.'
	li $s6, 'F'
	li $s7, 'M'

	#store 0 at first index to mark board to need generation
	li $t0, 0
	sb $t0, hiddenBoard($zero)
	
	#function that prompts user for difficulty
	jal difficulty
	
	mainLoop:
		#jal printHiddenBoard
		jal printBoard
	
		#store d and f characters for comparison
		li $t3, 'd'
		li $t4, 'f'
	
		commandLoop:
			#prompt user for dig or flag command
			li $v0, 4
			la $a0, promptCommand
			syscall
			
			#read input
			li $v0, 12
			syscall
			move $t0, $v0
			
			#loop if input invalid
			beq $t0, $t3, endCommandLoop
			beq $t0, $t4, endCommandLoop
			j commandLoop
			
		endCommandLoop:
		
		#print newline
		li $v0, 11
		li $a0, '\n'
		syscall
		
		rowLoop:
			#promt for row input
			li $v0, 4
			la $a0, promptRow
			syscall
			
			#read input
			li $v0, 5
			syscall
			move $t1, $v0
			
			#loop if input invalid
			bltz $t1, rowLoop
			bge $t1, $s0, rowLoop
			
		
		columnLoop:
			#prompt for column input
			li $v0, 4
			la $a0, promptColumn
			syscall
			
			#read input
			li $v0, 5
			syscall
			move $t2, $v0
			
			#loop if input invalid
			bltz $t2, columnLoop
			bge $t2, $s1, columnLoop
		
		#move row and column to arguments
		move $a0, $t1
		move $a1, $t2
		
		#get 1D index from row & column combo, store in a2
		jal getIndex
		move $a2, $v0
		
		#skip flagging if user input dig
		bne $t0, $t4, skipFlagToggle
		#call flag on tile
		jal flag
		#loop back
		j mainLoop
		skipFlagToggle:
		
		#check if board needs to be generated
		lb $t0, hiddenBoard($zero)
		bne $t0, $zero, skipGenerate
		
		addi $sp, $sp, -8
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		
		#generate new board
		jal generateBoard
		
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		addi $sp, $sp, 8
		
		skipGenerate:
		
		
		#get character at tile
		jal getIndex
		lb $t0, shownBoard($v0)
		
		#dig normally if unrevealed, loop back if flagged
		beq $t0, $s4, skipNearbyFlags
		beq $t0 $s6, mainLoop
		
		addi $sp, $sp, -8
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		
		#gets character digit representation of flags around tile
		jal nearbyFlags
		move $t1, $v0
		
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		addi $sp, $sp, 8
		
		#gets character at tile
		jal getIndex
		lb $t0, shownBoard($v0)
		
		#loop back if number of flags not same as tile number
		bne $t0, $t1, mainLoop
		
		addi $sp, $sp, -8
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		
		#dig immediate tiles around
		jal digAround
		
		lw $a0, 0($sp)
		lw $a1, 4($sp)
		addi $sp, $sp, 8
		
		skipNearbyFlags:
		
		#dig chosen tile
		jal dig
		
		#check win/loss conditions
		jal winCheck
		beq $v0, $zero, mainLoop
	
	#save return value of winCheck
	move $s3, $v0
	
	#jal printHiddenBoard
	jal printBoard
	
	
	beq $s3, -1, lose
	#load win message
	la $a0, printWin
	j endProgram
	
	lose:
	#load lose message
	la $a0, printLose
	
	endProgram:
	#print end message
	li $v0, 4
	syscall
	
	#end program
	li $v0, 10
	syscall




difficulty:
	#show difficulty options
	li $v0, 4
	la $a0, promptDifficulty
	syscall
	
	difficultyLoop:
		#prompt for input
		li $v0, 4
		la $a0, promptDifficultyEnter
		syscall
		
		#read input
		li $v0, 12
		syscall
		
		#loop if invalid
		beq $v0, '1', diffChoice1
		beq $v0, '2', diffChoice2
		beq $v0, '3', diffChoice3
		
		j difficultyLoop

	#s0-s3 treated as global variables for maxRow, maxColumn, maxBoardSize, and mineCount
	
	diffChoice1:
		li $s0, 10
		li $s1, 10
		li $s2, 100
		li $s3, 10
		j endDiff
	diffChoice2:
		li $s0, 16
		li $s1, 16
		li $s2, 256
		li $s3, 40
		j endDiff
	diffChoice3:
		li $s0, 16
		li $s1, 30
		li $s2, 480
		li $s3, 99
	endDiff:
	
	li $t0, 0
	
	#fill shown board with hidden tiles
	fillShownLoop:
		sb $s4, shownBoard($t0)
		addi $t0, $t0, 1
		blt $t0, $s2, fillShownLoop
	
	jr $ra	


	
		

generateBoard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#represents current number of mines
	li $t0, 0
	
	#set syscall to generate random number between 0 and board size
	li $v0, 42
	move $a1, $s2
	
	assignLoop:
		#get random number
		syscall
		
		#loop if tile is user's first choice (prevents turn 1 loss)
		beq $a0, $a2, assignLoop
		
		#loop if tile already a mine
		lb $t1, hiddenBoard($a0)
		beq $t1, $s7, assignLoop
	
		#assign mine to tile and increment number of current mines
		sb $s7, hiddenBoard($a0)
		addi $t0, $t0, 1
		
		#loop if current mines not yet at total needed
		blt $t0, $s3, assignLoop

	li $a0, 0
	
	fillHiddenOuterLoop:
		li $a1, 0
		
		fillHiddenInnerLoop:
			addi $sp, $sp, -8
			sw $a0, 0($sp)
			sw $a1, 4($sp)
			
			#get character digit of number of mines surrounding tile
			jal nearbyMines
			move $t0, $v0
			
			lw $a0, 0($sp)
			lw $a1, 4($sp)
			addi $sp, $sp, 8
			
			#set character to number of mines surrounding tile
			jal getIndex
			sb $t0, hiddenBoard($v0)
			
			#increment column and loop if not max column
			addi $a1, $a1, 1
			blt $a1, $s1, fillHiddenInnerLoop
		
		#increment row and loop if not max row
		addi $a0, $a0, 1
		blt $a0, $s0, fillHiddenOuterLoop
	
	#exit function
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

nearbyMines:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#get character at tile
	jal getIndex
	lb $v0, hiddenBoard($v0)
	
	#return if character is mine
	bne $v0, $s7, skipReturnMine
	j exitNearbyMines
	skipReturnMine:
	
	move $a2, $a0
	move $a3, $a1
	
	#used to count number of surrounding mines
	li $t2, 0
	
	#used for offset
	li $t0, -1
	
	nearbyMinesOuterLoop:
		#used for offset
		li $t1, -1
		
		#get row with offset
		add $a0, $a2, $t0
		
		nearbyMinesInnerLoop:
			#get column with offset
			add $a1, $a3, $t1
			
			#check if surrounding tile is mine
			jal getIndex
			lb $t4, hiddenBoard($v0)
			bne  $t4, $s7, skipCount
			
			#check if surrounding tile exists
			jal tileExists
			beq $v0, $zero, skipCount
			
			#increment count of surrounding mines
			addi $t2, $t2, 1
			
			skipCount:
			#update loop variable and loop if less than 2
			addi $t1, $t1, 1
			blt $t1, 2, nearbyMinesInnerLoop
			
		#update loop variable and loop if less than 2 
		addi $t0, $t0, 1
		blt $t0, 2, nearbyMinesOuterLoop
	
	#set to empty character if no surrounding mines, return that value	
	bne $t2, $zero, skipReturnEmpty
	move $v0, $s5
	j exitNearbyMines
	skipReturnEmpty:
	
	#set to character digit of number of surrounding mines
	addi $v0, $t2, '0'
	
	exitNearbyMines:
	#exit and return value
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

flag:
	#get character at tile
	lb $t4, shownBoard($a2)
	
	#flag if hidden
	bne $t4, $s4, skipFlagging
	sb $s6, shownBoard($a2)
	j endFlag
	skipFlagging:

	#unflag if flagged
	bne $t4, $s6, skipHidden
	sb $s4, shownBoard($a2)
	skipHidden:
	endFlag:
	jr $ra

#nearly identical to nearbyMines but checks number of surrounding flagged tiles
nearbyFlags:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $a2, $a0
	move $a3, $a1
	
	#flag count
	li $t2, 0
	
	li $t0, -1
	
	nearbyFlagsOuterLoop:
		li $t1, -1
		
		add $a0, $a2, $t0
		
		nearbyFlagsInnerLoop:
		
			add $a1, $a3, $t1
			
			jal getIndex
			lb $t4, shownBoard($v0)
			bne  $t4, $s6, skipFlagCount
			
			jal tileExists
			beq $v0, $zero, skipFlagCount
			
			addi $t2, $t2, 1
			
			skipFlagCount:
			addi $t1, $t1, 1
			blt $t1, 2, nearbyFlagsInnerLoop
			
		addi $t0, $t0, 1
		blt $t0, 2, nearbyFlagsOuterLoop
		
	addi $v0, $t2, '0'
	
	endNearbyFlags:
	lw $ra, 0($sp)
	addi, $sp, $sp, 4
	jr $ra
	
	
#------------------------Jaden Keller Start------------------------------------
tileExists:
	#return false if given row is less than 0
	bltz $a0, tileExistsFalse 

	#return false if given row is more than or equal to maxRow
	bge $a0, $s0, tileExistsFalse
	
	#return fasle if given column is less than 0
	bltz $a1, tileExistsFalse 

	#return false given column is more than or equal to maxColumn
	bge $a1, $s1, tileExistsFalse 
	
	#return true
	li $v0, 1
	jr $ra
	
	tileExistsFalse:
	#return false
	li $v0, 0
	jr $ra
	
		
getIndex:
	#multiply row by maxColumn
	mul $v0, $a0, $s1
	
	#add column
	add $v0, $v0, $a1
	
	jr $ra
	
	
	
dig:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#get index of row&column combo
	jal getIndex
	
	#get character of shownBoard at index
	lb $t0, shownBoard($v0)
	bne $t0, $s4, exitDig
	
	lb $t0, hiddenBoard($v0)
	sb $t0, shownBoard($v0)
	
	bne $t0, $s7, go
	add $zero, $zero, $zero
	go:
	
	bne $t0, $s5, exitDig
	
	jal digAround
	
	exitDig:
	lw $ra, 0($sp)
  	addi $sp, $sp, 4
	
	jr $ra
	
	
digAround:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#set stable argument
	move $a2, $a0
	move $a3, $a1
	
	#set t0 to -1 for outer loop variable
	li $t0, -1
	
	digAroundOuterLoop:
		#set t1 to -1 for inner loop variable
		li $t1, -1
		
		digAroundInnerLoop:
			#update row argument
			add $a0, $a2, $t0
		
			#update column argument
			add $a1, $a3, $t1
			
			#next iteration if off of board
			jal tileExists
			beq $v0, $zero, skipDig
			
			#next iteration if tile already dug
			jal getIndex
			lb $v0, shownBoard($v0)
			beq $v0, $s5, skipDig

			#store variables in case of recursive call
      			addi $sp, $sp, -16
      			sw $t0, 0($sp)
      			sw $t1, 4($sp)
      			sw $a2, 8($sp)
	    		sw $a3, 12($sp)
			
			#call dig on current tile
			jal dig

			#restore variables after dig
      			lw $t0, 0($sp)
      			lw $t1, 4($sp)
      			lw $a2, 8($sp)
	    		lw $a3, 12($sp)
	    		addi $sp, $sp, 16

			skipDig:
			addi $t1, $t1, 1
			blt $t1, 2, digAroundInnerLoop
			
		addi $t0, $t0, 1
		blt $t0, 2, digAroundOuterLoop
		
	lw $ra, 0($sp)
  	addi $sp, $sp, 4

  	jr $ra
#----------------------------------Jaden Keller End-------------------------------------	

#used just for formatting number of spaces in print call, prints one space if number in t0 is single digit
printSpace:
	move $t1, $t0
	div $t1, $t1, 10
	bne $t1, $zero, noSpace
	li $a0, ' '
	syscall
	noSpace:
	jr $ra


winCheck:
	#loop variable
	li $t0, 0
	
	#mineCount
	li $t3, 0
	
	winCheckLoop:
		#get character, don't return -1 if not mine
		lb $t1, shownBoard($t0)
		bne $t1, $s7, skipLose
		
		li $v0, -1
		jr $ra
		skipLose:
		
		#increment t3 for every hidden and flagged tile
		beq $t1, $s4, incrementMineCount
		beq $t1, $s6, incrementMineCount
		j skipLoop
		
		incrementMineCount:
		addi $t3, $t3, 1
		
		skipLoop:
		#update loop variable and loop if less than board size
		addi $t0, $t0, 1
		blt $t0, $s2, winCheckLoop
	
	#return 1 if number of unrevealed tiles is same as number of mines
	seq $v0, $t3, $s3
	jr $ra


printBoard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#print two newlines
	li $v0, 4
	la $a0, newlineAndSpaces
	syscall
	syscall


	li $t0, 0
	
	topNumbersLoop:
		#print space
		li $v0, 11
		li $a0, ' '
		syscall
		
		#print extra space if necessary
		jal printSpace
		
		#print column number	
		li $v0, 1
		move $a0, $t0
		syscall
		
		#update loop, check condition
		addi $t0, $t0, 1
		blt $t0, $s1, topNumbersLoop
	
	#print one newline
	li $v0, 4
	la $a0, newlineAndSpaces
	syscall
	
	#load pipe
	la $a0, spaceAndPipe
	
	#print number of pipes necessary for column
	li $t0, 0
	topPipes:
		syscall
		addi $t0, $t0, 1
		blt $t0, $s1, topPipes
	
	#set to print character
	li $v0, 11
	
	li $t0, 0
	printBoardOuterLoop:
		#print newline
		li $a0, '\n'
		syscall
		
		#print row number
		li $v0, 1
		move $a0, $t0
		syscall
		
		#print hyphen
		li $v0, 11
		li $a0, '-'
		syscall
		
		#print space if necessary
		jal printSpace
		
		li $t1, 0
		printBoardInnerLoop:
			#set argument registers
			move $a0, $t0
			move $a1, $t1
			
			#get 1D index
			jal getIndex
			move $t2, $v0
			
			#print space
			li $v0, 11
			li $a0, ' '
			syscall
			
			#print character of tile
			lb $a0, shownBoard($t2)
			syscall
			
			#print space
			li $a0, ' '
			syscall
			
			#update loop and check condition
			addi $t1, $t1, 1
			bne $t1, $s1, printBoardInnerLoop
			
		#update loop and check condition
		addi $t0, $t0, 1
		bne $t0, $s0, printBoardOuterLoop
		
	#exit function
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#used for debug purposes, just like printboard but prints the hidden board
printHiddenBoard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 4
	la $a0, newlineAndSpaces
	syscall
	syscall

	li $t0, 0
	
	topNumbersLoopHidden:
		li $v0, 11
		li $a0, ' '
		syscall
		
		jal printSpace
				
		li $v0, 1
		move $a0, $t0
		syscall
		
		addi $t0, $t0, 1
		blt $t0, $s1, topNumbersLoopHidden
		
	li $v0, 4
	la $a0, newlineAndSpaces
	syscall
	
	la $a0, spaceAndPipe
	
	li $t0, 0
	topPipesHidden:
		syscall
		addi $t0, $t0, 1
		blt $t0, $s1, topPipesHidden
	
	li $v0, 11
	
	li $t0, 0
	
	printHiddenBoardOuterLoop:
		li $a0, '\n'
		syscall
		
		li $v0, 1
		move $a0, $t0
		syscall
		
		li $v0, 11
		li $a0, '-'
		syscall
		
		jal printSpace
		
		li $t1, 0
		
		printHiddenBoardInnerLoop:
			move $a0, $t0
			move $a1, $t1
			
			jal getIndex
			move $t2, $v0
			
			li $v0, 11
			li $a0, ' '
			syscall
			
			lb $a0, hiddenBoard($t2)
			syscall
			
			li $a0, ' '
			syscall
			
			addi $t1, $t1, 1
			bne $t1, $s1, printHiddenBoardInnerLoop
			
		
		
		addi $t0, $t0, 1
		bne $t0, $s0, printHiddenBoardOuterLoop
		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
