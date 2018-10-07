.eqv		IMAGE_SIZE		786486
.eqv		NEW_IMAGE_SIZE	1048648
.eqv		NUM_WORDS		262144

.data		0x10010000
	img_body:
 		.word	0		
	img_original:
 		.word	0		
	filein:
		.asciiz	"img.bmp"
	textMenu:
		.asciiz 	"Escolha uma das opções abaixo:\n\t[0] Sair\t[1] Blur\t[2] Edge Extractor\t[3] Thresholding\n" # Texto que sera mostrado no menu
	cls:
		.asciiz 	"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" # espaçammento para parecer novo menu apos escolha do usuario
	textMenuError:
		.asciiz 	"\nOpção escolhida inválida, aperta '1' para continuar\n"
	textTest:
		.asciiz 	"\nOpção escolhida foi:"
	fileout:
		.asciiz	"out.bmp"
	header_original:
		.space	54						# O header possui tamanho de 54 bytes



#------------------------------------------------------------------------------------------------------------------------------------------------
.text
	main:
	# ---------------------------------------------
	# $s0 = Arquivo de entrada
	# $s1 = Arquivo de saída
	# $s2 = File descriptor do arquivo de entrada
	# $s3 = Tamanho em bytes da imagem original
	# $s4 = colunas na imagem
	# $s5 = ilnhas na imagem
	# $s6 = Quantidade de words
	# ---------------------------------------------
	la		$s0, filein

	# Abertura do arquivo de entrada
	move		$a0, $s0 				# $a0 = address of null-terminated string containing filename
	li		$a1, 0				# $a1 = flags (0 = read-only, 1 = write-only with create, 9 = write-only with create and append)
	li		$a2, 0				# $a2 = mode
	li		$v0, 13				# Prepara abertura do arquivo
	syscall
	move		$s2, $v0				# $s2 = File descriptor do arquivo de entrada

	# Leitura do header do arquivo de entrada
	move		$a0, $s2				# $a0 = file descriptor
	la		$a1, header_original		# $a1 = address of input buffer
	li		$a2, 54				# $a2 = maximum number of characters to read
	li		$v0, 14				# Prepara para leitura de arquivo
	syscall						# $v0 = number of characters read (0 if end-of-file, negative if error).

############################################################################################################################
################################### LEITURA DO HEADER ###################################
# ---------------------------------------------
# Quantidade de bytes	offset: 0x000002 - 4 bytes (1 word)
	addi		$a0, $zero, 0x000002		# Offset para o campo FileSize
	addi		$a1, $zero, 0x000004		# Tamanho do campo a ser lido, em hexa

	jal		extrai_valor_header
	move		$s3, $v0					# Salva o tamanho da imagem em memória

# ---------------------------------------------
# Colunas				offset: 0x000012 - 4 bytes (1 word)

	addi		$a0, $zero, 0x000012		# Offset para o campo FileSize
	addi		$a1, $zero, 0x000004		# Tamanho do campo a ser lido, em hexa

	jal		extrai_valor_header
	move		$s4, $v0					# Salva a largura da imagem em memória

# --------------------------------
# Linhas				offset: 0x000016 - 4 bytes (1 word)
	addi		$a0, $zero, 0x000016		# Offset para o campo FileSize
	addi		$a1, $zero, 0x000004		# Tamanho do campo a ser lido, em hexas

	jal		extrai_valor_header
	move		$s5, $v0					# Salva o comprimento da imagem em memória

# ---------------------------------------------
# Cálculo de quantidade de words
	move		$t0, $s3					# Carrega o tamanho da imagem completa
	addi		$t0, $t0, -54				# Retira o tamanho do header
	div		$t1, $t0, 3 				# $t1 = quantidade de words

	move		$s6, $t1					# salva a quantidade de words em memória

# ---------------------------------------------
# Alocação de memoria para img_body e img_original
	move		$t0, $s6					# Carrega quantidade de words
	mul		$t1, $t0, 4 				# $t1 = qnt words * 4 (tamanho em bytes da img_body)

	li		$v0, 9					# Prepara para alocação dinamica na heap
	move		$a0, $t1					# $a0 = number of bytes to allocate
	syscall							# Aloca memoria para o img_body
	sw		$v0, img_body				# Armazena o endereço em img_body


	li		$v0, 9					# Prepara para alocação dinamica na heap
	move		$a0, $s3					# $a0 = number of bytes to allocate
	syscall							# Aloca memoria para o img_body
	sw		$v0, img_original			# Armazena o endereço em img_original

############################################################################################################################
################################### LEITURA DO BODY ###################################
	# Leitura do body do arquivo de entrada
	move		$a0, $s2				# $a0 = file descriptor
	lw		$a1, img_original		# $a1 = address of input buffer
	move		$a2, $s3				# $a2 = maximum number of characters to read
	li		$v0, 14				# Prepara para leitura de arquivo
	syscall						# $v0 = number of characters read (0 if end-of-file, negative if error).

	move		$s7, $v0
############################################################################################################################

	# Fecha o arquivo de entrada
	move		$a0, $s2				# File descriptor do arquivo de entrada
	li		$v0, 16
	syscall

	#j		fim

############################################################################################################################
################################### DISPLAY IMAGE ###################################
	# ---------------------------------------------
	# Display Image
	# Trecho responsável por mostrar a imagem raw no bitmap display
	# Cada pixel da imagem no arquivo encontra-se no formato BBGGRR.
	# Para mostrar no bitmap display, precisa estar no formato 0x00RRGGBB
	# Obs.: A imagem está espelhada e invertida
	# ---------------------------------------------
	lw		$t0, img_body			# $t0 = &img_body, bloco de memória que será mostrada no bitmap display
	lw		$t1, img_original		# $t1 = &img_original, bloco de memória com os dados lidos da imagem de entrada
	move		$t7, $s6				# $t7 = quantidade de words

	addi		$t2, $zero, 0			# Indice I de loop

	loop:
	addi		$t3, $zero, 0			# Zera o registrador $t3

	# Load Red
	lbu		$t4, 2($t1)			# Carrega o valor de RED da img_original
	addu		$t3, $t3, $t4			# Coloca o valor de RED no $t3
	sll		$t3, $t3, 8			# Move o valor de RED para inserir a proxima cor no $t3

	# Load Green
	lbu		$t4, 1($t1)			# Carrega o valor de GREEN da img_original
	addu		$t3, $t3, $t4			# Coloca o valor de GREEN no $t3
	sll		$t3, $t3, 8			# Move o valor de GREEN para inserir a proxima cor no $t3

	# Load Blue
	lbu		$t4, 0($t1)			# Carrega o valor de BLUE da img_original
	addu		$t3, $t3, $t4			# Coloca o valor de BLUE no $t3

	sw		$t3, 0($t0)			# Salva o pixel em img_body (formato: 0x00RRGGBB
	addi		$t1, $t1, 3			# Incrementa o endereço de img_original em 3 bytes
	addi		$t0, $t0, 4			# Incrementa o endereço de img_body em 1 word

	addi		$t2, $t2, 1			# Incremente indice I do loop

	bne		$t2, $t7, loop			# repete o Loop enquanto não inserir todas as words em img_body

	move		$s6, $t2				# $s6 = quantidade de words em img_body

	jal		inverte_img
	jal		espelha_img
	j 		menu

	#j		fim

############################################################################################################################
################################### SALVA IMAGEM ###################################
	save_img:
	
	jal		espelha_img
	jal		inverte_img
	
	lw		$t0, img_body
	lw		$t1, img_original
	addi		$t9, $zero, 0			# Contador do loop
	#j		jump
	loop_save:
	# Red
	lbu		$t2, 2($t0)			
	sb		$t2, 2($t1)
	
	# Green
	lbu		$t2, 1($t0)
	sb		$t2, 1($t1)
	
	# Blue
	lbu		$t2, 0($t0)
	sb		$t2, 0($t1)
	
	addi		$t0, $t0, 4
	addi		$t1, $t1, 3
	addi		$t9, $t9, 1

	bne		$t9, $s6, loop_save
	
	jump:
	# Abre arquivo pra escrita
	li		$v0, 13
	la		$a0, fileout
	li		$a1, 9
	li		$a2, 0
	syscall
	
	move		$t0, $v0
		
	# Salva header
	li		$v0, 15
	move		$a0, $t0
	la		$a1, header_original
	li		$a2, 54
	syscall
	
	# Append body (img_original)
	li		$v0, 15
	move		$a0, $t0
	lw		$a1, img_original
	#li		$a2, 1048648
	move		$a2, $s3
	syscall
	
	# Fecha arquivo
	li		$v0, 16
	syscall
	
	# Sair
	j 		fim

############################################################################################################################
################################### EFEITOS ###################################
	# ---------------------------------------------
	# Inverte imagem
	# Função de inverter a imagem no eixo vertical
	# $t0 = indice da cabeça do array img_body
	# $t1 = indice da ponta da cauda do array img_body
	# Obs.: O valor inicial de $t2 vem do Display Image, que representa a quantidade de words
	#          no array img_body
	# ---------------------------------------------
	inverte_img:
	addi		$t0, $zero, 0			# Começo do array, indice i = 0
	mul		$t2, $s6, 4			# quantidade de words * 4 = indice do ultimo elemento do array

	# end ini
	lw		$t1, img_body
	# end fim
	add		$t2, $t2, $t1

	loop2:
	lw		$t3, 0($t1)
	lw		$t4, 0($t2)

	sw		$t3, 0($t2)
	sw		$t4, 0($t1)

	addi		$t1, $t1, 4
	addi		$t2, $t2, -4

	blt		$t1, $t2, loop2

	jr		$ra
#######################################################################
	espelha_img:
	# ---------------------------------------------
	# Espelha imagem
	# Função de espelhar a imagem no eixo horizontal
	# $t0 = enderço base do img_body
	# $t1 = contador de linhas
	# $t2 = offset para proxima linha (2048)
	# $t3 = posição inicial da linha (primeira word)
	# $t4 = posição final de linha (última word)
	# ---------------------------------------------
	lw		$t0, img_body			# endereço inicial do img_body
	addi		$t1, $zero, 0			# Contador de linhas
	
	move		$t2, $s4				# Quantidade de colunas
	sll		$t2, $t2, 2			# colunas * 4 (2048)
	
	loop3:
	mult		$t1, $t2
	mflo		$t3					# offset da linha
				
	add		$t4, $t0, $t3			# Posição de inicio de linha	
	add		$t5, $t4, $t2
	addi		$t5, $t5, -4			# Fim de linha (última word)
	
	sub_loop3:
	lw		$t6, 0($t4)			# Carrega pixel do começo da linha
	lw		$t7, 0($t5)			# Carrega pixel do fim da linha
	
	# SWAP
	sw		$t7, 0($t4)	
	sw		$t6, 0($t5)
	
	addi		$t4, $t4, 4
	addi		$t5, $t5, -4
	
	blt		$t4, $t5, sub_loop3

	addi		$t1, $t1, 1
	
	bne		$t1, $s5, loop3

	jr		$ra
#######################################################################
	thresholding:
	lw		$t0, img_body			# Endereço do img_body
	move		$t1, $s6				# Quantidade de words
	addi		$t5, $zero, 0
	li		$t9, 100				# input do user
	li		$t8, 3
	
	loop4:
	addi		$t5, $t5, 1
	bgt		$t5, $s6, end		
	
	lbu		$t2, 1($t0)			# Carrega R
	lbu		$t3, 2($t0)			# Carrega G
	lbu		$t4, 3($t0)			# Carrega B
	
	# (R + G + B) / 3
	add		$t2, $t2, $t3
	add		$t2, $t2, $t4
	
	div		$t2, $t8
	mflo		$t2
	
	blt		$t2, $t9, black
	
	# White
	addi		$t2, $zero, 0x00000000
	sw		$t2, 0($t0)
	addi		$t0, $t0, 4
	j		loop4
	
	black:
	addi		$t2, $zero, 0x00FFFFFF
	sw		$t2, 0($t0)
	addi		$t0, $t0, 4
	j		loop4

	end:

	j		menu
	#jr		$ra
#######################################################################
	# ---------------------------------------------
	# Função extrai_valor_header
	# IN
	# $a0 = offset do campo a ser acessado
	# $a1 = tamanho do campo a ser lido, em hexa
	# OUT
	# $v0 = valor do campo definido no header
	# ---------------------------------------------
	extrai_valor_header:
	la		$t0, header_original			# carrega endereço do header

	add		$t0, $t0, $a0				# Offset para a info a ser buscada
	addu		$t0, $t0, $a1				# Vai pro fim da info (busca invertida)

	add		$t1, $zero, $zero			# Indice I do loop
	add		$t2, $zero, $zero			# temp
	addi		$t3, $a1, 1				# condicao de fim de loop

	loop_extrai_byte:
	sll		$t2, $t2,8
	lbu		$t4, 0($t0)
	addu		$t2, $t2, $t4

	addi		$t0, $t0, -1
	addi		$t1, $t1, 1

	bne		$t1, $t3, loop_extrai_byte

	move		$v0, $t2

	jr		$ra
############################################################################################################################
################################### MENU ###################################
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

	beq $v0, 2, edge  # faz o Edge Extractor
	#jal edge

	beq $v0, 3, thresholding  #faz o Thresholding
	#jal thresholding
	
	beq	$v0, 4, save_img

	bgt $v0, 4, notOption
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

##############################################################################################################################################
	edge:

	addi $t6,$zero,0 #Inicializa indice do loop
	la $t0, img_body # Carrega endereco do inicio da imagem

	escala_cinza: #Aplica o Filtro cinza na imagem

	addi $t3,$zero,3 #Inicializa t2 com 3
	addi $t2,$zero,0 #Inicializa t2 com 0
	addi $t5,$zero,0 #Inicializa t5 com 0

	lbu $t1,0($t0) # t1 recebe a cor azul
	add $t2,$t2,$t1

	lbu $t1,1($t0) # t1 recebe a cor verde
	add $t2,$t2,$t1

	lbu $t1,2($t0) # t1 recebe a cor vermelha
	add $t2,$t2,$t1

	div $t2,$t3 # calcula a media das cores

	mflo $t4 # pega o valor da divisao

	addu $t5, $t5, $t4	# Coloca o valor do cinza no $t5
	sll  $t5, $t5, 8	# Move o valor de Cinza para inserir a proxima cor no $t5
	addu $t5,$t5 $t4
	sll $t5,$t5,8
	addu $t5,$t5 $t4

	sw $t5,0($t0) # Altera o pixel original para um em escala cinza

        addi $t0, $t0, 4			# Incrementa o endereço de img_body em 1 word
	addi $t6, $t6, 1			# Incremente indice I do loop

	bne $t6, NUM_WORDS, escala_cinza	# repete o Loop enquanto não inserir todas as words em img_body

	#addi $t1,$zero,2044 # Tamanho da imagem * 4 + 4
	#add $t4,$zero, 2040 # Tamanho da imagem * 4
	la $t0, img_body # volta para o inicio da imagem
	addi $t7,$zero,0 # Reseta t7
	robert_cross: # Aplica o algoritmo de Robert Cross na imagem

	addi $t5, $zero,0 # Zera t5
	addi $t2,$zero,4 # Reseto o $t2
	lbu $t1,0($t0) # Pega o pixal [i,j]
	lbu $t2,2040($t0) #pega o pixel [i+1,j+1]
	sub $t3,$t2,$t1 # diferenca entre os valores
	abs $t3,$t3 # valor absoluto de t3
	div $t3,$t3,2 #divide por 2
	mflo $t3 #salva em t3

	addi $t2,$zero,4 # Reseto o $t2
	lbu $t1,2036($t0) # Pega o pixal [i,j]
	lbu $t2,4($t0) #pega o pixel [i+1,j+1]
	sub $t5,$t2,$t1 # diferenca entre os valores
	abs $t5,$t5 # valor absoluto de t3
	div $t5,$t5,2 #divide por 2
	mflo $t5 #salva em t3

	add $t6,$t3,$t5 # Novo valor do pixel

	addu $t5, $t5, $t6	# Coloca o valor do filtro no $t6
	sll  $t5, $t5, 8	# Move o valor do filtro para inserir a proxima cor no $t6
	addu $t5,$t5 $t6
	sll $t5,$t5,8
	addu $t5,$t5 $t6

	sw $t5, 0($t0) # Altera o pixel original para um em escala cinza

        addi $t0, $t0, 4			# Incrementa o endereço de img_body em 1 word
	addi $t7, $t7, 1			# Incremente indice I do loop

	bne $t7, 262143, robert_cross	# repete o Loop enquanto não inserir todas as words em img_body

	j fim

#######################################################################
	fim:
	li		$v0, 10
	syscall
