.data
	filein:
		.asciiz
		"img.bmp"
	fileout:
		.asciiz
		"img_out.bmp"
	buffer:
		.space 3145944	# Tamanho do buffer 

.text
	main:
	la		$s0, filein	
	
	jal		openFile
	move 	$s1, $v0	# file descriptor
	
	jal		readFile
	la		$a0, buffer
	
	# Printa imagem no bitmap display
	li		$v0, 4
	syscall
	
	jal		closeFile
	j		fim	
#######################################################################	
	openFile:
	li		$v0, 13
	
	move		$a0, $s0
	li		$a1, 0	# flags
	li		$a2, 0	# mode
	syscall
	
	jr		$ra
#######################################################################
	readFile:
	li		$v0, 14
	move		$a0, $s1
	la		$a1, buffer
	la		$a2, 3145944
	syscall
	
	jr		$ra
#######################################################################	
	closeFile:
	li		$v0, 16
	move		$a0, $s1
	syscall
	
	jr		$ra
#######################################################################	
	fim:
	li		$v0, 10
	syscall