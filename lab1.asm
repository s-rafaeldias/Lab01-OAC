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
	textMenu:
		.asciiz "Escolha uma das opções abaixo:\n\t[0] Sair\t[1] Blur\t[2] Edge Extractor\t[3] Thresholding\n" # Texto que sera mostrado no menu
	cls: 
		.asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" # espaçammento para parecer novo menu apos escolha do usuario
	textMenuError:
		.asciiz "\nOpção escolhida inválida, aperta '1' para continuar\n"

	textTest:
		.asciiz "\nOpção escolhida foi:"

.text
	main:
	# ---------------------------------------------
	# TODO:
	# 1. Menu de escolhas de operaÃ§Ãµes (Blur, Edge Extractor e Thresholding (terminal)
	# 2. Visualizar no bitmap display e salvar em um arquivo com o nome que o usuÃ¡rio definir (terminal)
	# 3. Efeito de Borramento (Blur effect) com os parÃ¢metros da mÃ¡scara definido pelo usuÃ¡rio
	# 4. Efeito de ExtraÃ§Ã£o de Bordas (Edge Extractor) com os parÃ¢metros da mÃ¡scara definido pelo usuÃ¡rio
	# 5. BinarizaÃ§Ã£o por limiar (Thresholding) definido pelo usuÃ¡rio
	# ---------------------------------------------
	
	# ---------------------------------------------
	# $s0 = Arquivo de entrada
	# $s1 = Arquivo de saÃ­da
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
	
	j		menu	
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
	menu:
	la $a0, cls   # carregar o espaçamento
	li $v0, 4     # print do espaçamento
	syscall
	
	la $a0, textMenu
	syscall
	
	li $v0, 5    # Esperando resposta do usuario
	syscall
	
	beq $v0, 0, fim  # Sai do programa
	
	beq $v0, 1, teste  # faz o Blur
	#jal blue
	
	beq $v0, 2, teste  # faz o Edge Extractor
	#jal edge
	
	beq $v0, 3, teste  #faz o Thresholding
	#jal thresholding
	
	bgt $v0, 3, notOption
#######################################################################
	teste:
	move $t0, $v0
	li $v0, 4
	la $a0, textTest
	syscall
	
	li $v0, 1
	move $a0, $t0
	syscall
	
	b menu
#######################################################################	
	notOption:
	li $v0, 4
	la $a0, textMenuError
	syscall
	
	li $v0, 5
	syscall
	
	b menu
	
#######################################################################
	fim:
	li		$v0, 10
	syscall