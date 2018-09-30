.eqv		IMAGE_SIZE		786486
.eqv		NEW_IMAGE_SIZE	1048648
.eqv		NUM_WORDS		262144
#------------------------------------------------------------------------------------------------------------------------------------------------
.#data  	0x10010000

#------------------------------------------------------------------------------------------------------------------------------------------------
# Static Memory
.data		0x10010000
	img_body:
		.space	NEW_IMAGE_SIZE	# body = imagem - header
 	img_original:
		.space 	IMAGE_SIZE		# Tamanho do buffer 	
	filein:
		.asciiz	"img.bmp"
	fileout:
		.asciiz	"img_out.bmp"	
#------------------------------------------------------------------------------------------------------------------------------------------------
# Menu:	
	textMenu:
		.asciiz 	"Escolha uma das opções abaixo:\n\t[0] Sair\t[1] Blur\t[2] Edge Extractor\t[3] Thresholding\n" # Texto que sera mostrado no menu
	cls: 
		.asciiz 	"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" # espaçammento para parecer novo menu apos escolha do usuario
	textMenuError:
		.asciiz 	"\nOpção escolhida inválida, aperta '1' para continuar\n"

	textTest:
		.asciiz 	"\nOpção escolhida foi:"
#------------------------------------------------------------------------------------------------------------------------------------------------

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
	# $s1 = Arquivo de saída
	# $s2 = File descriptor do arquivo de entrada
	# $s3 = File descriptor do arquivo de saída
	# ---------------------------------------------
	la		$s0, filein			
	la		$s1, fileout
	
	# Abertura do arquivo de entrada
	move		$a0, $s0 				# $a0 = address of null-terminated string containing filename
	li		$a1, 0				# $a1 = flags (0 = read-only, 1 = write-only with create, 9 = write-only with create and append)
	li		$a2, 0				# $a2 = mode
	li		$v0, 13				# Prepara abertura do arquivo
	syscall
	move		$s2, $v0				# $s2 = File descriptor do arquivo de entrada
	
	# Leitura do arquivo
	move		$a0, $s2				# $a0 = file descriptor
	la		$a1, img_original		# $a1 = address of input buffer
	li		$a2, IMAGE_SIZE		# $a2 = maximum number of characters to read
	li		$v0, 14				# Prepara para leitura de arquivo 
	syscall						# $v0 = number of characters read (0 if end-of-file, negative if error).	
##############################################################
# Carrega em words	
	la		$t0, img_body
	la		$t1, img_original
	li		$t7, NEW_IMAGE_SIZE
	addi		$t1, $t1, 54			# Tira o header 54 bytes
	addi		$t2, $zero, 0			# Indice I de loop

	loop:
	addi		$t3, $zero, 0
	
	# Red
	lbu		$t4, 2($t1)
	addu		$t3, $t3, $t4
	sll		$t3, $t3, 8
	
	# Green
	lbu		$t4, 1($t1)
	addu		$t3, $t3, $t4
	sll		$t3, $t3, 8
	
	# Blue
	lbu		$t4, 0($t1)
	addu		$t3, $t3, $t4
	#sll		$t3, $t3, 8
	

	sw		$t3, 0($t0)
	
	addi		$t1, $t1, 3
	addi		$t0, $t0, 4
	
	
	addi		$t2, $t2, 1
	
	bne		$t2, NUM_WORDS, loop
##############################################################


##############################################################
	# Leitura do body
	#jal		showDisplay
	
	# Abre o arquivo de saída
	move		$a0, $s1 				# $a0 = address of null-terminated string containing filename
	li		$a1, 1				# $a1 = flags (0 = read-only, 1 = write-only with create, 9 = write-only with create and append)
	li		$a2, 0				# $a2 = mode
	li		$v0, 13				# Prepara abertura do arquivo
	syscall						# $v0 = file descriptor (negative if error)

	# Escreve no arquivo de saída
	move		$a0, $v0				# $a0 = file descriptor
	la		$a1, img_body			# $a1 = address of output buffer
	li		$a2, NEW_IMAGE_SIZE	# $a2 = number of characters to write
	li		$v0, 15				# Prepara para escrita do arquivo de saida
	syscall						# $v0 = number of characters written (negative if error)
	move		$s3, $v0
						
	# Fecha os arquivos
	move		$a0, $s2				# File descriptor do arquivo de entrada
	li		$v0, 16
	syscall
	move		$a0, $s3				# File descriptor do arquivo de saída
	li		$v0, 16
	syscall
	
	#j		menu
	j		fim	
#######################################################################


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
