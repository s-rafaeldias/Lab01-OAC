.eqv		SYS_BUFFER_SIZE	786486

.data
	filein:
		.asciiz
		"img.bmp"
	fileout:
		.asciiz
		"img_out.bmp"
	buffer:
		.space SYS_BUFFER_SIZE			# Tamanho do buffer 

.text
	main:
	# ---------------------------------------------
	# TODO:
	# 1. Menu de escolhas de operações (Blur, Edge Extractor e Thresholding (terminal)
	# 2. Visualizar no bitmap display e salvar em um arquivo com o nome que o usuário definir (terminal)
	# 3. Efeito de Borramento (Blur effect) com os parâmetros da máscara definido pelo usuário
	# 4. Efeito de Extração de Bordas (Edge Extractor) com os parâmetros da máscara definido pelo usuário
	# 5. Binarização por limiar (Thresholding) definido pelo usuário
	# ---------------------------------------------
	
	# ---------------------------------------------
	# $s0 = Arquivo de entrada
	# $s1 = Arquivo de saída
	# ---------------------------------------------
	la		$s0, filein			
	la		$s1, fileout
	
	move		$a0, $s0 			# abrit o filein
	li		$a1, 0			# flags (0=read, 1=write)
	jal		openFile
	move 	$s2, $v0			# file descriptor
	
	jal		readFile
	
	move		$a0, $s1			# abrir o fileout
	li		$a1, 1			# flags (0 = read-only, 1 = write-only with create, 9 = write-only with create and append)			
	jal		openFile
	
	move		$a0, $v0			# file descriptor
	jal		writeFile
	move		$t0, $v0
				
	jal		closeFile		
	
	j		fim	
#######################################################################	
	openFile:
	li		$v0, 13
	
	li		$a2, 0	# mode
	syscall
	
	jr		$ra
#######################################################################
	readFile:
	li		$v0, 14
	move		$a0, $s2
	la		$a1, buffer
	li		$a2, SYS_BUFFER_SIZE
	syscall
	
	jr		$ra
#######################################################################	
	closeFile:
	li		$v0, 16
	syscall
	
	jr		$ra
#######################################################################
	writeFile:
	li		$v0, 15
	la		$a1, buffer
	li		$a2, SYS_BUFFER_SIZE
	
	syscall
	
	jr		$ra
#######################################################################
	fim:
	li		$v0, 10
	syscall
