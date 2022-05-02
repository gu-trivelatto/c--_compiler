& /0000
MAIN 		JP 		INILEX
; =============================================================================
; CONSTANTES E VARIAVEIS
; =============================================================================
CEM 		K		/0100
DISP 		K 		/0000	; O dispositivo é carregado 3 vezes como 3 disps diferentes para as 3 analises
DISPLEX		K 		/0000
DISPSINT 	K 		/0000
DISPSEM		K 		/0000
GETD 		K 		/D000
DADO2BYTES  K		/0000 	; Variaveis para separar os 2 bytes lidos
DADO1 		K 		/0000
DADO2 		K 		/0000
CONTADOR 	K 		/0001	; Utilizado pelo separador de bytes
EOL 		K 		/000A
EOF 		K 		/00FF
AUX 		K 		/0000	; Auxiliar utilizado na leitura de variáveis e rótulos
AUX1		K 		/0000
AUX2 		K 		/0000
LOAD 		K 		/8000
AC_VAR 		K 		/0002	; Acumulador utilizado para percorrer as listas
FOI_ROT		K		/0001	; Indica que já há um rótulo na linha se for /FFFF
FOI_IF 		K 		/0001	; Indica que veio de um if se for /FFFF
; =============================================================================
; LISTA DE INTS - LIMITE DE 16 INTS - NOME E EMBAIXO VALOR
; =============================================================================
INICIO_INT 	K 		/1111
			$ 		=32
FIM_INT 	K		/1111
; =============================================================================
; LISTA DE CHARS - LIMITE DE 16 CHARS - NOME E EMBAIXO VALOR
; =============================================================================
INICIO_CH 	K 		/1111
			$ 		=32
FIM_CHAR 	K		/1111
; =============================================================================
; LISTA DE ROTULOS - LIMITE DE 16 ROTULOS
; =============================================================================
INICIO_ROT 	K 		/1111
			$ 		=16
FIM_ROT 	K		/1111
; =============================================================================
; CODIGO PRINCIPAL
; =============================================================================
;
; =============================================================================
; ANALISADOR LEXICO
; =============================================================================
INILEX 		K 		/0000
			LD 		DISPLEX	; Define o disp que será utilizado na analise lexica
			MM 		DISP
			SC 		LEDADO	; Carrega os primeiros 2 bytes do arquivo
			SC 		TESTDADO; Inicia a subrotina de análise léxica
			JP 		INISINT	; Passa para a próxima análise
; =============================================================================
; ANALISADOR SINTATICO
; =============================================================================
INISINT 	K 		/0000
			LD 		DISPSINT; Define o disp que será utilizado na analise sintática
			MM 		DISP
			SC 		LEDADO	; Carrega os primeiros 2 bytes do arquivo
			SC 		TESTSINT; Inicia a subrotina de análise sintática
			JP		INISEM	; Passa para a próxima análise
; =============================================================================
; ANALISADOR SEMANTICO
; =============================================================================
INISEM 		K 		/0000
			LD 		DISPSEM	; Define o disp que será utilizado na analise semântica
			MM 		DISP
			SC		LEDADO	; Carrega os primeiros 2 bytes do arquivo
			SC 		TESTSEM	; Inicia a subrotina de análise semântica
			JP 		FIM		; Encerra a execução do compilador
; =============================================================================
; SUBROTINAS
; =============================================================================
; ---- LE DADOS DO ARQUIVO FONTE ---------------------------
LEDADO 		K 		/0000
			LD 		GETD
			AD 		DISP
			MM 		MONTADO
MONTADO 	K 		/0000		; Monta o comando para ler os bytes
			MM 		DADO2BYTES	; Armazena na variável de entrada do separador de bytes
			SC 		SEPARADADO 	; Chama o separador
			RS 		LEDADO
; ---- SEPARA O DADO DE 2 BYTES EM 2 DE 1 BYTE -------------
SEPARADADO  K 		/0000
			LV 		/0001		; Carrega o contador com o valor inicial
			MM 		CONTADOR	
			LD 		DADO2BYTES
			DV 		CEM
			MM 		DADO1		; Separa o byte mais significativo
			MM 		DADOTEST	; Armazena o byte mais significativo na variável de teste (atual)
			LD  	DADO2BYTES
			MP 		CEM
			DV 		CEM
			MM 		DADO2		; Separa o byte menos significativo
			RS 		SEPARADADO
; ---- ATUALIZA DADO ---------------------------------------
ATTDADO		LD 		CONTADOR	; Carrega o contador
			JZ 		ATT1		; Se o contador estiver zerado direciona para uma nova leitura
			SB  	/0001		; Senão, zera o contador e muda o byte utilizado
			MM 		CONTADOR
			LD 		DADO2		; Carrega o byte menos significativo
			MM 		DADOTEST	; Armazena no dado de teste
			JP 		FIMATT
ATT1		SC 		LEDADO
FIMATT		RS 		ATTDADO
; ---- SUBROTINA LEXICA, DIRECIONA PROS TESTES LEXICOS ----------
TESTDADO 	K 		/0000
CICLO		LD 		DADOTEST
;
			SB 		EOL
			JZ 		EOLSR
			JP 		NEOL
EOLSR 		SC 		TRATAEOL	; Direciona para o tratamento do EOL
NEOL 		AD 		EOL
;			
			SB 		/0020
			JZ 		ESPACOSR
			JP 		NSP
ESPACOSR	SC 		TRATASP		; Direciona para o tratamento de espaços
NSP			AD 		/0020
;			
			SB 		/002A
			JN 		ERRO		; Nenhum caractere antes de 2A deveria aparecer neste momento além do espaço e do EOL
			AD 		/002A
			SB 		/002E
			JZ 		ERRO		; . não é um caractere suportado aqui
			JN 		SIMBSR1		; Se for negativo e não ouve erro antes então o caractere é um dos símbolos
			JP 		NSIMB1
SIMBSR1     SC 		TRATASIMB
NSIMB1		AD 		/002E
			SB 		/002F		; O caractere é uma barra
			JZ 		BARSR
			JP 		NBAR
BARSR		SC 		TRATABAR	; Direciona para o tratamento de barras
NBAR		AD 		/002F
;			
			SB 		/0030		
			JN 		ERRO		; Tudo que vem antes de 30 além do que já foi testado não é aceito
			AD 		/0030
			SB 		/003A
			JN 		NUMSR		; Se der negativo é um número
			JP 		NNUM
NUMSR		SC 		TRATANUM	; Direciona para o tratamento de números
NNUM		AD 		/003A
;			
			SB 		/003D
			JN 		SIMBIG		; Identifica o sinal de =
			JP 		NIG
SIMBIG		SC 		IGUALCOMP	; Direciona para o tratamento de =
NIG			AD 		/003D
;
			SB 		/003F
			JN 		SIMBSR2		; Identifica o segundo bloco de símbolos
			JP 		NSIMB2
SIMBSR2		SC 		TRATASIMB	; Direciona para o tratamento de símbolos
NSIMB2		AD 		/003F
;			
			SB  	/0041
			JN 		ERRO		; Tudo que vem antes de 41 além do que já foi testado não é aceito
			AD 		/0041
			SB		/005B
			JN 		LETSR1		; Está no primeiro bloco de letras
			JP 		NLET1
LETSR1 		SC 		TRATALET	; Trata letras
NLET1		AD 		/005B
;			
			SB		/0061
			JN 		ERRO
			AD 		/0041
			SB 		/007B
			JN		LETSR2		; Está no segundo bloco de letras
			JP 		NLET2
LETSR2		SC 		TRATALET	; Trata letras
NLET2		AD 		/007B
;
			SB 		/00FF
			JZ 		FIMTRAT		; Testa o fim do arquivo e direciona para o final da subrotina
			AD 		/00FF
;			
ERRO 		SC 		ERROCHAR	; Se não caiu em nenhum dos casos anteriores então houve um erro
;			
FIMTRAT		RS 		TESTDADO
; ---- TRATA EOL ---------------------------------------
TRATAEOL 	K 		/0000
CICLOEOL	SC 		ATTDADO		; Atualiza o dado utilizado (fica alternando entre byte1 e byte2)
			LD  	DADOTEST
			SB 		EOL
			JZ 		CICLOEOL	; Fica em loop enquanto houver EOL
			AD 		EOL
			JP 		CICLO 		; Se achar algo diferente de EOL volta para o loop inicial sem atualizar o dado, para que ele seja analisado
			RS 		TRATAEOL
; ---- TRATA ESPACOS ---------------------------------------
TRATASP 	K 		/0000		; Mesmo funcionamento do TRATAEOL
CICLOSP		SC 		ATTDADO		
			LD  	DADOTEST
			SB 		/0020
			JZ 		CICLOSP
			AD 		/0020
			JP 		CICLO 		
			RS 		TRATASP
; ---- TRATA + - * < > -----------------------------------
TRATASIMB 	K 		/0000
CICLOSIMB	SC 		ATTDADO
			LD  	DADOTEST
			SB 		/0020
			JZ 		SIMBOK		; Simbolos precisam vir acompanhados de um espaço antes e depois
			SC 		ERROCHAR	
SIMBOK 		SC 		ATTDADO
			JP 		CICLO
; ---- TRATA = E == --------------------------------------------
IGUALCOMP 	K		/0000
CICLOIG		SC 		ATTDADO
			LD  	DADOTEST
IGTEST		SB 		/0020		; Se vier um espaço depois do = está certo
			JZ 		OKIG
			AD 		/0020
			SB 		/003D		; Se vier um = logo depois de outro = direciona para outro teste de espaço
			JZ 		OKIG2
			SC 		ERROCHAR
OKIG2 		SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0020		; Se depois de um == tiver um espaço então está OK
			JZ 		OKIG
			SC 		ERROCHAR
OKIG		SC		ATTDADO
			JP 		CICLO
; ---- TRATA / E // ----------------------------------------
TRATABAR 	K 		/0000
CICLOBAR	SC 		ATTDADO
			LD  	DADOTEST
BARTEST		SB 		/002F
			JZ 		COMENTSR	; Se houver outro / depois de uma / é um comentário
			JP		NCOMENT
COMENTSR 	SC		COMENTARIO
NCOMENT		AD 		/002F
			SB 		/0020		; Se não for comentário, vê se tem um espaço depois da barra, se não tiver está errado
			JZ 		OKBAR
			SC 		ERROCHAR
OKBAR		SC		ATTDADO
			JP 		CICLO
; ---- TRATA NUMEROS ---------------------------------------
TRATANUM 	K 		/0000
CICLONUM	SC 		ATTDADO
			LD  	DADOTEST
			SB 		/0020
			JZ 		NUMSP		; Se vier um espaço depois do número direciona para o fim da subrotina
			AD 		/0020
			SB 		/0030
			JN 		NNUM
			AD 		/0030
			SB 		/003A
			JN 		CICLONUM	; Testa o bloco de números, enquanto vier um número depois do outro está OK
			JP		NNUM
NUMSP 		SC 		ATTDADO		; Acabou a sequência de números, atualiza o dado e volta para o loop principal
			JP 		CICLO
NNUM		SC 		ERROCHAR	
; ---- TRATA LETRAS (E CONSEQUENTEMENTE NUMEROS) -----------
TRATALET 	K 		/0000
CICLOLET	SC 		ATTDADO		; Mesma lógica dos números, depois da primeira letra são aceitas letras e números até achar um espaço
			LD  	DADOTEST
			SB 		/0020
			JZ 		LETSP
			AD 		/0020
			SB 		/0030
			JN 		NLET
			AD 		/0030
			SB 		/003A
			JN 		CICLOLET
			AD 		/003A
			SB 		/0041
			JN 		NLET
			AD 		/0041
			SB 		/005B
			JN 		CICLOLET
			AD 		/005B
			SB 		/0061
			JN 		NLET
			AD 		/0061
			SB 		/007B
			JN 		CICLOLET
			JP		NLET
LETSP 		SC 		ATTDADO
			JP  	CICLO
NLET		SC 		ERROCHAR
; ---- TRATA COMENTARIO ------------------------------------
COMENTARIO 	K 		/0000		; Lê e ignora tudo que está sendo lido até encontrar um EOL, então volta para o loop principal
CICLOCMT	SC 		ATTDADO
			LD  	DADOTEST
CMTTEST     SB 		EOL
			JZ 		CICLO
			JP 		CICLOCMT
; ---- TRATA ERROS LEXICOS ---------------------------------
ERROCHAR 	K 		/0000
; DEFINIÇÃO PROVISORIA PARA O ERRO
			LV 		/FFFF		; Encerra a máquina se encontrar um erro, e carrega /FFFF
			HM 		ERROCHAR
			RS 		ERROCHAR
; ---- SUBROTINA SINTATICA, DIRECIONA PROS TESTES SINTATICOS ----------
INISINT 	K 		/0000
CICLOSINT 	LD 		DADOTEST
;
			SB 		EOL
			JZ 		EOLSRS		; Testa casos de EOL
			JP 		NEOLS
EOLSRS 		SC 		EOLSINT
NEOLS 		AD 		EOL
;
			SB 		/0020
			JZ 		ESPACOSRS	; Testa casos de espaço
			JP 		NSPS
ESPACOSRS	SC 		SPSINT
NSPS		AD 		/0020
;
			SB 		/002F
			JZ 		COMENTSRS	; Testa comentários
			JP 		NCSRS
COMENTSRS 	SC 		COMENTSINT
SCSRS 		AD 		/002F
;
			SB 		/0063     	;  TRATA COMEÇOS COM c, PARA TESTARMOS O char
			JZ 		PODE_CHAR
			JP		NCHARSINT
PODE_CHAR	SC 		CHARTEST
NCHARSINT 	AD 		/0063
;
			SB 		/0067     	;  TRATA COMEÇOS COM g, PARA TESTARMOS O goto
			JZ 		PODE_GOTO
			JP		NGOTOSINT
PODE_GOTO	SC 		GOTOTEST
NGOTOSINT 	AD 		/0067
;
			SB 		/0069     	;  TRATA COMEÇOS COM i, PARA TESTARMOS O int E O if
			JZ 		PODE_INT
			JP		NINTSINT
PODE_INT	SC 		INTTEST
NINTSINT 	AD 		/0069
;
			SB 		/0070     	;  TRATA COMEÇOS COM p, PARA TESTARMOS O print
			JZ 		PODE_PRINT
			JP		NPRINTSINT
PODE_PRINT	SC 		PRINTTEST
NPRINTINT 	AD 		/0070
;
			SB 		/0073     	;  TRATA COMEÇOS COM s, PARA TESTARMOS O scan
			JZ 		PODE_SCAN
			JP		NSCANSINT
PODE_SCAN	SC 		SCANTEST
NSCANSINT 	AD 		/0073
;
			SB		/0041 	  	;  TRATAMENTO PARA LETRAS
			JN 		SINT_ERRO
			AD 		/0041
;
			SB 		/005B
			JZ 		PODE_VAR1
			JP		NVARSINT1
PODE_VAR1	SC 		TESTROT		; Direciona para o tratamento de char, int e rótulos
			SC 		ATTDADO
			JP 		CICLOSINT
NVARSINT1	AD 		/005B
;
			SB 		/0061
			JN 		SINT_ERRO
			AD 		/0061
;
			SB 		/007B
			JZ 		PODE_VAR2
			SC 		ERROSINT
PODE_VAR2	SC 		TESTROT		; Direciona para o tratamento de char, int e rótulos
			SC 		ATTDADO
			JP 		CICLOSINT
;
SINT_ERRO 	SC 		ERROSINT	; Se de alguma forma passar por tudo, entra no caso de erro
FIM_SINT	RS 		INISINT
; ---- TESTES DE SINTAXE ----------------------------------------------
; ---- TESTA EOL ------------------------------------------------------
EOLSINT 	K 		/0000
			LV 		/0001
			MM 		FOI_ROT		; Um EOL reseta o status do rótulo, na próxima linha o compilador consegue armazenar um rótulo novo
CEOLSINT	SC 		ATTDADO
			LD  	DADOTEST
EOLSTEST	SB 		/000A
			JZ 		CEOLSINT
			AD 		/000A
			JP 		CICLOSINT 	; Fica em loop até achar algo que não seja EOL
			RS 		EOLSINT
; ---- TESTA ESPACO ---------------------------------------------------
SPSINT	 	K 		/0000
CICLOSPS	SC 		ATTDADO		
			LD  	DADOTEST
SPSTEST		SB 		/0020
			JZ 		CICLOSP
			AD 		/0020
			JP 		CICLOSINT 	; Fica em loop até achar algo que não seja espaço	
			RS 		SPSINT
; ---- CHECA INT, CHAR E ROTULOS --------------------------------------
BUSCA_VAR	K 		/0000
CICLO_INT	LD 		AC_VAR
			AD 		INICIO_INT
			AD 		LOAD
			MM 		PERCORRE1
PERCORRE1 	K 		/0000		; Carrega o endereço inicial da tabela e ints
			SB 		/1111
			JZ 		CICLO_CHAR	; Muda para o teste de char quando atinge o fim da lista
			AD 		/1111
			SB 		AUX
			JZ 		ERA_INT		; Se encontrar o Aux (que contém a variável lida) na lista, define que é um int
			AD 		AUX
			LD 		AC_VAR
			AD 		/0004		; Se não encontrar incrementa dois endereços (a lista é em par nome depois valor)
			MM 		AC_VAR
			JP 		CICLO_INT 	; Continua em looping
CICLO_CHAR	LD 		AC_VAR		; Faz a mesma coisa que o looping de int, mas procurando na lista de chars
			AD 		INICIO_CH	
			AD 		LOAD
			MM 		PERCORRE2
PERCORRE2 	K 		/0000
			SB 		/1111
			JZ 		NOT_DEF 	; Indica que não está na lista de variáveis definidas
			AD 		/1111
			SB 		AUX
			JZ 		ERA_CHAR
			AD 		AUX
			LD 		AC_VAR
			AD 		/0004
			MM 		AC_VAR
			JP 		CICLO_CHAR
NOT_DEF 	SC 		ERROSINT	; A variável não foi instanciada, exibe um erro
ERA_INT		LV 		/0002		; O valor 2 no retorno indica que é int
			JP 		FIM_BUSCA
ERA_CHAR 	LV 		/0001		; O valor 1 no retorno indica que é char
FIM_BUSCA	RS 		BUSCA_VAR
; ---- TESTA char -----------------------------------------------------
CHARTEST 	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST
TEST_CH		SB 		/0068
			JZ 		TEST_CHA
			AD 		/0068
			JP 		NOT_CHAR
TEST_CHA 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0061
			JZ 		TEST_CHAR
			SC 		ERROSINT
TEST_CHAR 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0072
			JZ 		TEST_CHAR_
			SC 		ERROSINT
TEST_CHAR_ 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0020
			JZ 		EHCHAR
			SC 		ERROSINT
EHCHAR 		SC 		ARM_CHAR	; Depois de testar todos caracteres de char até o espaço, direciona para a subrotina de armazenar a variavel
			SC 		ATTDADO
			LD 		DADOTEST
			SB 		/003B		; Verifica se houve ; depois da definição do char
			JZ 		END_CHAR	
			SC 		ERROSINT
NOT_CHAR	LV 		/6300		; A segunda letra não era H, carrega o aux com /6300 (C_) e soma com a letra lida
			AD 		DADOTEST
			MM 		AUX			; Armazena no auxiliar
			SC 		TESTROT		; Envia o auxiliar para o teste de rótulo
END_CHAR	SC 		ATTDADO
			LD 		FOI_IF		; Indica se estava dentro de um bloco if, se estava envia de volta para o looping do if
			JN 		IF_CHAR
			JP 		CICLOSINT	; Se não estava em um if volta para o looping principal
IF_CHAR		JP 		RETORNO_IF
; ---- ARMAZENA char --------------------------------------------------
ARM_CHAR 	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST	; Atualiza o dado para pegar o primeiro byte do nome do char
			ML 		/0100		; Joga ele para a esquerda do Aux
			MM 		AUX
			LD 		DADOTEST	; Carrega o primeiro byte novamente
			SB 		/0041		; Faz a verificação se ele é uma letra
			JN 		NCHAR
			AD 		/0041
			SB 		/005B
			JN 		CHAROK1
			AD 		/005B
			SB 		/0061
			JN 		NCHAR
			AD 		/0061
			SB 		/007B
			JN 		CHAROK1		; Se a primeira letra estiver ok, segue para a próxima
			JP		NCHAR
CHAROK1		SC 		ATTDADO
			LD 		DADOTEST
			AD 		AUX
			MM 		AUX			; Carrega o byte menos significativo e junta ele com o mais significativo
			LD 		DADOTEST	; Carrega o segundo byte novamente
			SB 		/0030		; Verifica a validade, para o segundo caractere números também são aceitos
			JN 		NCHAR
			AD 		/0030
			SB 		/003A
			JN 		CHAROK2
			AD 		/003A
			SB 		/0041
			JN 		NCHAR
			AD 		/0041
			SB 		/005B
			JN 		CHAROK2
			AD 		/005B
			SB 		/0061
			JN 		NCHAR
			AD 		/0061
			SB 		/007B
			JN 		CHAROK2		; Segundo caractere está ok, passa para a verificação na lista de chars armazenados
			JP		NCHAR		
CHAROK2		LD 		AC_VAR		; Carrega o primeiro endereço da lista de chars
			AD 		INICIO_CH
			AD 		LOAD
			MM 		PERCORREC
PERCORREC 	K 		/0000		; Coloca a instrução montada para carregar o valor do endereço atual, marcado pelo AC_VAR
			SB 		/1111
			JZ 		CHAR_CHEIO	; Se encontrar /1111 chegou a o fim da lista sem achar um espaço vazio, logo, a lista está cheia
			AD 		/1111
			SB 		AUX			; Se ele já estiver na lista é direcionado para um erro, o mesmo char foi instanciado duas vezes
			JZ 		CHAR_EXISTE
			AD 		AUX
			JZ 		CHAR_SLOT	; Se achar um espaço zerado, então ainda tem espaço, direciona para o armazenamento
			LD 		AC_VAR
			AD 		/0004		; Atualiza o acumulador, dois endereços por vez, pois é armazenado em pares nome + valor
			MM 		AC_VAR
			JP 		CHAROK2		; Reinicia o loop caso não tenha caído em nenhum dos casos possíveis
CHAR_SLOT 	LD 		AC_VAR		; Carrega o último endereço lido antes da interrupção do loop, ou seja, o primeiro endereço livre
			AD 		INICIO_CH
			AD 		MEMO
			MM		GUARDA_C
			LD 		AUX
GUARDA_C	K 		/0000		; Instrução de memória montada, armazena o nome do char (que está no aux) no endereço da lista de chars
			JP 		END_CHAR_A
CHAR_CHEIO 	SC 		ERROSINT
NCHAR 		SC 		ERROSINT
CHAR_EXISTE	SC 		ERROSINT
END_CHAR_A 	RS 		ARM_CHAR
; ---- TESTA int  -----------------------------------------------------
INTTEST 	K 		/0000
			SC 		ATTDADO		
			LD 		DADOTEST
TEST_IN		SB 		/006E
			JZ 		TEST_INT
			AD 		/006E
			JP 		NOT_INT
TEST_INT 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0074
			JZ 		TEST_INT_
			SC 		ERROSINT
TEST_INT_ 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0020
			JZ 		EHINT
			SC 		ERROSINT
EHINT 		SC 		ARM_INT		; Depois de testar todas letras de int (inclusive o espaço), direciona para o armazenamento do int
			SC 		ATTDADO
			LD 		DADOTEST	; Verifica se depois do nome do int existe um ;
			SB 		/003B
			JZ 		END_INT
			SC 		ERROSINT
NOT_INT		SB 		/0066		; Se a segunda letra não foi um n, testa o caso do if
			JZ 		EH_IF		; Se for um if direciona para o tratamento
			AD 		/0066
			LV		/6900		; Caso não seja, significa que é uma variável/rótulo, carrega I_, junta com a próxima letra e salva no aux
			AD 		DADOTEST
			MM 		AUX
			SC 		TESTROT		; Com o aux salvo, manda para o teste de rótulos e variáveis
			JP 		END_INT
EH_IF		SC 		IFTEST		; Se foi identificado um if, redireciona para o tratamento
END_INT		SC 		ATTDADO
			LD 		FOI_IF		; Se o indicador do if está ativo, retorna para o ciclo do tratamento do int
			JN 		IF_INT
			JP 		CICLOSINT
IF_INT 		JP 		RETORNO_IF	; Senão, volta para o loop principal
; ---- ARMAZENA int --------------------------------------------------
ARM_INT 	K 		/0000
			SC 		ATTDADO		; Carrega o primeiro byte do nome do int
			LD 		DADOTEST
			ML 		/0100
			MM 		AUX			; Armazena no byte mais significativo do aux
			LD 		DADOTEST	; Carrega o byte novamente e testa se ele é uma letra
			SB 		/0041
			JN 		NINT
			AD 		/0041
			SB 		/005B
			JN 		INTOK1
			AD 		/005B
			SB 		/0061
			JN 		NINT
			AD 		/0061
			SB 		/007B
			JN 		INTOK1
			JP		NINT
INTOK1		SC 		ATTDADO		; Se o primeiro byte for uma letra continua para o segundo
			LD 		DADOTEST	; Atualiza para ler o segundo byte do nome
			AD 		AUX
			MM 		AUX			; Junta com o aux já armazenado e armazena o nome completo no aux
			LD 		DADOTEST	; Carrega o byte novamente
			SB 		/0030		; Agora há a possibilidade do caractere ser um número
			JN 		NINT
			AD 		/0030
			SB 		/003A
			JN 		INTOK2
			AD 		/003A
			SB 		/0041
			JN 		NINT
			AD 		/0041
			SB 		/005B
			JN 		INTOK2
			AD 		/005B
			SB 		/0061
			JN 		NINT
			AD 		/0061
			SB 		/007B
			JN 		INTOK2
			JP		NINT
INTOK2		LD 		AC_VAR		; Se o nome não quebrar as regras começa o ciclo para percorrer a lista de ints armazenados
			AD 		INICIO_INT
			AD 		LOAD
			MM 		PERCORREI
PERCORREI 	K 		/0000		; Instrução de load montada com o endereço atual do acumulador
			SB 		/1111
			JZ 		INT_CHEIO	; Se encontrar /1111 é por que chegou no fim da lista, logo, ela está cheia
			AD 		/1111
			SB 		AUX
			JZ 		INT_EXISTE	; Se encontrar o nome na lista houve um erro, o int foi instanciado duas vezes
			AD 		AUX
			JZ 		INT_SLOT	; Se encontrar um espaço vazio direciona para o armazenamento do int de fato
			LD 		AC_VAR
			AD 		/0004		; Atualiza o acumulador em 2 endereços, pois o int é armazenado no par nome + valor
			MM 		AC_VAR
			JP 		INTOK2		; Reinicia o loop caso não tenha caído em nenhum dos casos anteriores
INT_SLOT 	LD 		AC_VAR		; Carrega o último endereço acessado, logo, o primeiro endereço livre
			AD 		INICIO_INT	
			AD 		MEMO
			MM		GUARDA_I
			LD 		AUX
GUARDA_I	K 		/0000		; Monta a instrução de memória para armazenar o nome do int (presente no aux) no endereço correpondente
			JP 		END_INT_A
INT_CHEIO 	SC 		ERROSINT
NINT 		SC 		ERROSINT
INT_EXISTE 	SC 		ERROSINT
END_INT_A 	RS 		ARM_INT
; ---- TESTA ROTULO E VARIÁVEIS -----------------------------------------
TESTROT 	K 		/0000
			SC 		ATTDADO		; Atualiza o dado testado
			LD 		DADOTEST	
			SB 		/0020
			JZ 		SP_ROT_OK	; Se houver um espaço logo dps do nome é um possível rótulo ou variável
			SC 		ERROSINT
SP_ROT_OK 	SC 		ATTDADO		; Atualiza para o próximo byte depois do espaço
			LD 		DADOTEST
			SB 		/003D		; Testa se é um =, se for, então a atribuição de uma variável
			JZ 		N_ROT_VAR	; Direciona para os testes de variáveis
			AD 		/003D
			LD 		FOI_ROT		; Verifica se o indicador de rótulo já lido está ativo (/FFFF), se estiver ele da erro
			JN 		ERRO_ROT
			LD 		DADOTEST	; Se não estiver ativo, começa a ler o que vem em seguida
			SB 		/0041
			JN 		ERRO_ROT
			AD 		/0041
			SB 		/005B
			JN 		N_VAR_ROT
			AD 		/005B
			SB 		/0061
			JN 		ERRO_ROT
			AD 		/0061
			SB 		/007B
			JN 		N_VAR_ROT
ERRO_ROT	SC 		ERROSINT
N_VAR_ROT 	SC 		ARM_ROT		; Se for o próximo byte depois do rótulo for uma letra, ele armazena o rótulo que ainda estava no aux
			LD 		FOI_ROT
			ML 		/FFFF		; Atualiza o indicador de rótulo, para informar que esta linha já possui um rótulo
			MM 		FOI_ROT
			JP 		FIM_A_ROT
N_ROT_VAR	SC 		BUSCA_VAR	; Se chegou aqui então não era um rótulo, então chama a rotina de busca de variável para descobrir seu tipo
			SB 		/0001
			JZ 		N_ROT_CHAR	; Se a rotina retornou /0001, então era um char
			AD 		/0001
			SB 		/0002		; Se a rotina retornou /0002, então era um int
			JZ 		N_ROT_INT
			SC 		ERROSINT	; Se não retornou nenhum dos dois então houve algum erro
N_ROT_CHAR	SC 		ATTDADO
			LD 		DADOTEST	; Rotina caso tenha identificado char
			SB 		/0020		; Verifica se veio um espaço depois do =
			JZ 		CONT_CHAR1
			SC 		ERROSINT
CONT_CHAR1	SC 		ATTDADO		; Carrega o byte que vem depois do = e verifica se ele é uma letra ou número (que será usado como caractere)
			LD 		DADOTEST
			SB 		/0030
			JN 		STOP_CHAR
			AD 		/0030
			SB 		/003A
			JN 		CONT_CHAR2
			AD 		/003A
			SB 		/0041
			JN 		STOP_CHAR
			AD 		/0041
			SB 		/005B
			JN 		CONT_CHAR2
			AD 		/005B
			SB 		/0061
			JN 		STOP_CHAR
			AD 		/0061
			SB 		/007B
			JN 		CONT_CHAR2
STOP_CHAR 	SC 		ERROSINT
CONT_CHAR2	LD 		DADOTEST	; Caso o char esteja dentro da regra, continua para o armazenamento do valor
			MM 		AUX			; Armazena o valor do char no aux
			LD 		AC_VAR		; Carrega o acumulador de endereço encontrado quando encontrou o nome do char na lista
			AD 		INICIO_CH
			AD 		MEMO
			AD 		/0002		; Incrementa o acumulador em um endereço, para chegar ao endereço do valor
			MM 		GUARDA_CHAR
			LD 		AUX			; Carrega o valor do char
GUARDA_CHAR K 		/0000		; Armazena no endereço correspondente
			LV 		/0002
			MM 		AC_VAR		; Reseta o acumulador
			LV 		/0000
			MM 		AUX			; Zera o aux
			SC 		ATTDADO
			LD 		DADOTEST	; Carrega o próximo byte e verifica se é um ;
			SB 		/003B
			JZ 		FIM_A_ROT
			SC 		ERROSINT
N_ROT_INT	SC 		ATTDADO		; Verifica se é um espaço depois do =
			LD 		DADOTEST
			SB 		/0020
			JZ 		CONT_INT1
			SC 		ERROSINT
CONT_INT1	SC 		ATTDADO		; Verifica o número do primeiro byte
			LD 		DADOTEST
			SB 		/0030
			JN 		STOP_INT
			AD 		/0030
			SB 		/003A
			JN 		CONT_INT2
			AD 		/003A
STOP_INT 	SC 		ERROSINT
CONT_INT2	LD 		DADOTEST
			ML 		/0100
			MM 		AUX			; Armazena o primeiro número no byte mais significativo
			SC 		ATTDADO		; Carrega o próximo byte
			LD 		DADOTEST
			SB 		/0030
			JN 		STOP_INT2
			AD 		/0030
			SB 		/003A
			JN 		CONT_INT3
			AD 		/003A
STOP_INT2 	SC 		ERROSINT
CONT_INT3	LD 		DADOTEST	; Se o segundo número também estiver certo prossegue no funcionamento
			AD 		AUX			; Junta com o byte anterior e armazena no byte menos significativo do aux
			SC 		ASCII_NUM	; Converte de ASCII para hexadecimal, para poder trabalhar com os valores
			LD 		AC_VAR		; Carrega o endereço do nome do int
			AD 		INICIO_CH
			AD 		MEMO
			AD 		/0002		; Soma dois para acessar o endereço do valor daquele int
			MM 		GUARDA_INT
			LD 		AUX
GUARDA_INT 	K 		/0000
			LV 		/0002		; Reseta o acumulador
			MM 		AC_VAR
			LV 		/0000		; Reseta o aux
			MM 		AUX
			SC 		ATTDADO
			LD 		DADOTEST	; Verifica se depois da atribuição vem um ;
			SB 		/003B
			JZ 		FIM_A_ROT
			SC 		ERROSINT
FIM_A_ROT 	RS 		TESTROT
; ---- ARMAZENA ROTULO --------------------------------------------------
ARM_ROT 	K 		/0000
C_A_ROT		LD 		AC_VAR		; Carrega o acumulador com o endereço inicial
			AD 		INICIO_ROT
			AD 		LOAD
			MM 		PERCORRER
PERCORRER 	K 		/0000		; Monta a instrução load para percorrer a lista
			SB 		/1111
			JZ 		ROT_CHEIO	; Se encontrar /1111 chegou ao fim da lista, logo, ela está cheia
			AD 		/1111
			SB 		AUX
			JZ 		ROT_EXISTE	; Se o rótulo for encontrado na lista há um erro, pois esse rótulo já foi utilizado anteriormente
			AD 		AUX
			JZ 		ROT_SLOT	; Se encontrar um espaço em branco, então há espaço para um novo rótulo
			LD 		AC_VAR
			AD 		/0002		; Incrementa o acumulador em um endereço, pois rótulos são informações individuais
			MM 		AC_VAR
			JP 		C_A_ROT		; Volta para o loop do rótulo caso nenhuma das condições anteriores tenha sido satisfeita
ROT_SLOT 	LD 		AC_VAR
			AD 		INICIO_ROT	; Utiliza o endereço encontrado para o primeiro endereço vazio
			AD 		MEMO
			MM		GUARDA_R
			LD 		AUX
GUARDA_R	K 		/0000		; Monta a instrução memória para armazenar o rótulo
			JP 		END_ROT_A
ROT_CHEIO 	SC 		ERROSINT
ROT_EXISTE 	SC 		ERROSINT
END_ROT_A 	RS 		ARM_ROT
; ---- TESTA if   -----------------------------------------------------
IFTEST 		K 		/0000
TEST_IFP 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0028		; Carrega o próximo caractere e verifica se é um (
			JZ 		EHIF
			SC 		ERROSINT
EHIF 		SC 		ATTDADO		; Começa a verificar o que tem dentro do parênteses
			LD 		DADOTEST 	; Verifica a primeira letra da primeira variável
			SB 		/0041
			JN 		IF_ERR
			AD 		/0041
			SB 		/005B
			JN 		ARG1_OK1
			AD 		/005B
			SB 		/0061
			JN 		IF_ERR
			AD 		/0061
			SB 		/007B
			JN 		ARG1_OK1
			JP		IF_ERR
ARG1_OK1 	SB 		/0030		; Se estiver ok, verifica a segunda letra da primeira variável (aqui pode haver números)
			JN 		IF_ERR
			AD 		/0030
			SB 		/003A
			JN 		ARG1_OK2
			AD 		/003A
			SB 		/0041
			JN 		IF_ERR
			AD 		/0041
			SB 		/005B
			JN 		ARG1_OK2
			AD 		/005B
			SB 		/0061
			JN 		IF_ERR
			AD 		/0061
			SB 		/007B
			JN 		ARG1_OK2
			JP		IF_ERR
ARG1_OK2	SC 		ATTDADO		; Verifica o condicional
			LD 		DADOTEST
			SB 		/003C		; Testa se é um <
			JZ 		OP_IF_OK
			AD 		/003C
			SB 		/003E		; Testa se é um >
			JZ 		OP_IF_OK
			AD 		/003E
			SB 		/003D		; Testa se é um =
			JZ 		IG_2		; Se for um igual redireciona para testar se o segundo = vem logo em seguida
			SC 		ERROSINT
IG_2 		SC 		ATTDADO		; Carrega o próximo dado
			LD 		DADOTEST
			SB 		/003D		; Verifica se é um ==
			JZ 		OP_IF_OK
			SC 		ERROSINT
OP_IF_OK	SC 		ATTDADO		; Prossegue para a próxima variável
			LD 		DADOTEST 	; Verifica o primeiro caractere
			SB 		/0041
			JN 		IF_ERR
			AD 		/0041
			SB 		/005B
			JN 		ARG2_OK1
			AD 		/005B
			SB 		/0061
			JN 		IF_ERR
			AD 		/0061
			SB 		/007B
			JN 		ARG2_OK1
			JP		IF_ERR
ARG2_OK1 	SB 		/0030		; Verifica o segundo caractere (pode conter números)
			JN 		IF_ERR
			AD 		/0030
			SB 		/003A
			JN 		ARG2_OK2
			AD 		/003A
			SB 		/0041
			JN 		IF_ERR
			AD 		/0041
			SB 		/005B
			JN 		ARG2_OK2
			AD 		/005B
			SB 		/0061
			JN 		IF_ERR
			AD 		/0061
			SB 		/007B
			JN 		ARG2_OK2
			JP		IF_ERR
ARG2_OK2	SC 		ATTDADO		; Carrega o próximo byte
			LD 		DADOTEST
			SB 		/0029		; Verifica se é um )
			JZ 		PAR_IF_OK
			SC 		ERROSINT
PAR_IF_OK	SC 		ATTDADO		; Carrega o próxim byte
			LD 		DADOTEST
			SB 		/007B		; Verifica se é um {
			JZ 		CHAVE1_OK
IF_ERR		SC 		ERROSINT
CHAVE1_OK 	SC 		TEST_CMD	; Direciona para o teste do conteúdo do if
			SC 		ATTDADO		; Após o teste do conteúdo, atualiza o dado lido
NOT_IF		LD 		FOI_IF		; Verifica se o if já estava dentro de outro if
			JN 		IF_IF
			JP 		CICLOSINT	; Se não, retorna para o loop principal
IF_IF 		JP 		RETORNO_IF	; Se sim, retorna para o ciclo do if
; ---- TESTA COMANDOS DO IF -------------------------------------------
TESTA_CMD	K 		/0000
			LD 		FOI_IF
			ML 		/FFFF		; Atualiza o valor do indicador de if
			MM 		FOI_IF
CICLO_IF	SC 		ATTDADO		; Atualiza o dado e joga a execução para o loop principal, com o indicador de if ativo
			JP		CICLOSINT
RETORNO_IF 	SC 		ATTDADO		; Quando retornar da execução dos comandos dentro do if, retorna para cá
			LD 		DADOTEST
			SB 		/007D		; Testa se tem um } depois do comando
			JZ 		FIM_IF		; Se sim, encerra o tratamento do if
			JP 		CICLO_IF	; Se não, volta para o ciclo para ler um novo comando
FIM_IF		LD 		FOI_IF		; Atualiza o valor da flag do if
			ML 		/FFFF
			MM 		FOI_IF
			RS 		TESTA_CMD
; ---- TESTA goto -----------------------------------------------------
GOTOTEST 	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST
TEST_GO		SB 		/006F
			JZ 		TEST_GOT
			AD 		/006F
			JP 		NOT_GOTO
TEST_GOT 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0074
			JZ 		TEST_GOTO
			SC 		ERROSINT
TEST_GOTO 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/006F
			JZ 		TEST_GOTO_
			SC 		ERROSINT
TEST_GOTO_ 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0020
			JZ 		EHGOTO
			SC 		ERROSINT
EHGOTO 		SC 		ATTDADO		; Após verificar todas letras do goto (inclusive o espaço), direciona para o tratamento
			LD 		DADOTEST 	; Começa a testar a primeira letra do rótulo referenciado
			SB 		/0041
			JN 		ROT_ERR
			AD 		/0041
			SB 		/005B
			JN 		ROT_OK1
			AD 		/005B
			SB 		/0061
			JN 		ROT_ERR
			AD 		/0061
			SB 		/007B
			JN 		ROT_OK1
			JP		ROT_ERR
ROT_OK1 	SC 		ATTDADO		; Se o primeiro caracter estava ok, testa o segundo (agora aceita números tbm)
			LD 		DADOTEST
			SB 		/0030		
			JN 		ROT_ERR
			AD 		/0030
			SB 		/003A
			JN 		ROT_OK2
			AD 		/003A
			SB 		/0041
			JN 		ROT_ERR
			AD 		/0041
			SB 		/005B
			JN 		ROT_OK2
			AD 		/005B
			SB 		/0061
			JN 		ROT_ERR
			AD 		/0061
			SB 		/007B
			JN 		ROT_OK2
			JP		ROT_ERR
ROT_OK2 	SC 		ATTDADO		; Carrega o próximo dado
			LD 		DADOTEST
			SB 		/003B		; Verifica se há um ; no fim
			JZ 		ROT_OK
ROT_ERR		SC 		ERROSINT	
NOT_GOTO	LV 		/6700		; Se a segunda letra não for um o, então pode ser um rótulo ou variável
			AD 		DADOTEST	; Carrega G_, junta com a letra seguinte e armazena no aux
			MM 		AUX			
			SC 		TESTROT		; Chama a rotina de testes para definir se é rótulo ou variável
END_GOTO	SC 		ATTDADO
			LD 		FOI_IF		; Testa se está num if para decidir para onde retorna
			JN 		IF_GOTO
			JP 		CICLOSINT
IF_GOTO 	JP 		RETORNO_IF
; ---- TESTA print -----------------------------------------------------
PRINTTEST 	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST
TEST_PR		SB 		/0072
			JZ 		TEST_PRI
			AD 		/0072
			JP 		NOT_PRINT
TEST_PRI 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0069
			JZ 		TEST_PRIN
			SC 		ERROSINT
TEST_PRIN 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/007E
			JZ 		TEST_PRINT
			SC 		ERROSINT
TEST_PRINT 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0074
			JZ 		TEST_PRINTP
			SC 		ERROSINT
TEST_PRINTP	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0028
			JZ 		EHPRINT
			SC 		ERROSINT
EHPRINT		SC 		ATTDADO		; Chega aqui depois de testar todas letras do print (inclusive o parênteses)
			LD 		DADOTEST	; Carrega o primeiro caractere da variável que o print vai imprimir
			ML 		/0100		; Coloca o caractere no byte mais significativo do aux
			MM 		AUX
			LD 		DADOTEST	; Testa o byte
			SB 		/0041
			JN 		N_VAR_PR
			AD 		/0041
			SB 		/005B
			JN 		VAR_PR1
			AD 		/005B
			SB 		/0061
			JN 		N_VAR_PR
			AD 		/0061
			SB 		/007B
			JN 		VAR_PR1
			JP		N_VAR_PR
VAR_PR1		SC 		ATTDADO		; Se não houverem problemas testa o próximo byte
			LD 		DADOTEST
			AD 		AUX			; Armazena no byte menos significativo do aux
			MM 		AUX
			LD 		DADOTEST	; Testa se está na regra (aqui também pode haver número)
			SB 		/0030
			JN 		N_VAR_PR
			AD 		/0030
			SB 		/003A
			JN 		VAR_PR2
			AD 		/003A
			SB 		/0041
			JN 		N_VAR_PR
			AD 		/0041
			SB 		/005B
			JN 		VAR_PR2
			AD 		/005B
			SB 		/0061
			JN 		N_VAR_PR
			AD 		/0061
			SB 		/007B
			JN 		VAR_PR2
N_VAR_PR 	SC 		ERROSINT
VAR_PR2 	SC 		BUSCA_VAR	; Verifica se a variável existe na memória
			SB 		/0001
			JZ 		OK_PRINT
			AD 		/0001
			SB 		/0002
			JZ 		OK_PRINT
			SC 		ERROSINT
OK_PRINT 	SC 		ATTDADO		; Se a variável existir, testa se há um ) depois
			LD 		DADOTEST
			SB 		/0029
			JZ 		PAR_PR_OK
			SC 		ERROSINT
PAR_PR_OK 	SC 		ATTDADO
			LD 		DADOTEST	; Se tudo estiver certo, chega a existência de um ; depois do comando
			SB 		/003B
			JZ 		OK_PRINT2
			SC 		ERROSINT
OK_PRINT2 	SC 		ATTDADO
NOT_PRINT	JP 		CICLOSINT
			RS 		PRINTTEST
; ---- TESTA scan -----------------------------------------------------
SCANTEST 	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST
TEST_SC		SB 		/0063
			JZ 		TEST_SCA
			AD 		/0063
			JP 		NOT_SCAN
TEST_SCA 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0061
			JZ 		TEST_SCAN
			SC 		ERROSINT
TEST_SCAN 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/006E
			JZ 		TEST_SCANP
			SC 		ERROSINT
TEST_SCANP 	SC 		ATTDADO
			LD 		DADOTEST
			SB 		/0028
			JZ 		EHSCAN
			SC 		ERROSINT
EHSCAN 		SC 		ATTDADO		; Direciona para cá depois de testar todas letras do scan (inclusive o parênteses)
			LD 		DADOTEST
			ML 		/0100		; Armazena no byte mais significativo do aux
			MM 		AUX
			LD 		DADOTEST 	; Carrega o caractere novamente para testar
			SB 		/0041
			JN 		N_VAR_SC
			AD 		/0041
			SB 		/005B
			JN 		VAR_SC1
			AD 		/005B
			SB 		/0061
			JN 		N_VAR_SC
			AD 		/0061
			SB 		/007B
			JN 		VAR_SC1
			JP		N_VAR_SC
VAR_SC1		SC 		ATTDADO		; Se o primeiro caracter estiver ok carrega o próximo
			LD 		DADOTEST
			AD 		AUX			; Armazena no byte menos significativo do aux
			MM 		AUX
			LD 		DADOTEST	; Carrega o caractere para testar (aqui também aceita número)
			SB 		/0030
			JN 		N_VAR_SC
			AD 		/0030
			SB 		/003A
			JN 		VAR_SC2
			AD 		/003A
			SB 		/0041
			JN 		N_VAR_SC
			AD 		/0041
			SB 		/005B
			JN 		VAR_SC2
			AD 		/005B
			SB 		/0061
			JN 		N_VAR_SC
			AD 		/0061
			SB 		/007B
			JN 		VAR_SC2
N_VAR_SC 	SC 		ERROSINT
VAR_SC2 	SC 		BUSCA_VAR	; Verifica se a variável utilizada no scan existe
			SB 		/0001
			JZ 		OK_SCAN
			AD 		/0001
			SB 		/0002
			JZ 		OK_SCAN
			SC 		ERROSINT
OK_SCAN 	SC 		ATTDADO
			LD 		DADOTEST	; Se a variável existir então testa se tem um ) depois
			SB 		/0029
			JZ 		PAR_SC_OK
			SC 		ERROSINT
PAR_SC_OK 	SC 		ATTDADO
			LD 		DADOTEST	; Se estiver tudo ok testa se há um ; depois de tudo
			SB 		/003B
			JZ 		OK_SCAN2
			SC 		ERROSINT
OK_SCAN2 	SC 		ATTDADO
NOT_SCAN	JP 		CICLOSINT
			RS 		SCANTEST
; ---- ASCII PARA NUMERO HEXADECIMAL ----------------------------------
ASCII_NUM 	K 		/0000
			LD 		AUX
			ML	 	/0100
			DV 		/0100
			SB 		/0030		; Subtrai 30 do byte menos siginifivativo para deixar em decimal
			MM 		AUX1		; Coloca o byte menos significativo do aux em aux1
			LD 		AUX			
			DV 		/0100		; Pega o byte mais significativo de aux
			SB 		/0030		; Subtrai 30 para chegar no valor decimal
			ML 		/000A		; Multiplica por A para definir as dezenas
			MM 		AUX2		
			AD 		AUX1		; Soma com o valor do byte menos significativo 
			MM 		AUX			; Armazena o valor já convertido para hexadecimal
			RS 		ASCII_NUM
; ---- TRATA COMENTÁRIO -----------------------------------------------
COMENTSINT	K		/0000
			SC 		ATTDADO
			LD 		DADOTEST	; Testa se há outra barra
			SB 		/002F
			JZ		COMENTOK
			SC 		ERROSINT
COMENTOK 	SC 		ATTDADO		; Se tiver, entra em loop e fica lendo dados e descartando até achar um EOL
			LD 		DADOTEST
			SB 		EOL			; Após achar um EOL direciona para o fim da subrotina
			JZ 		FIMCOMENT
			JP 		COMENTOK
FIMCOMENT 	SC 		ATTDADO
			JP 		CICLOSINT
; ---- ERRO SINTÁTICO -----------------------------------------------
ERROSINT 	K 		/0000
; DEFINIÇÃO PROVISORIA PARA O ERRO
			LV 		/FFFF		; Encerra a máquina se encontrar um erro, e carrega /FFFF
			HM 		ERROSINT
			RS 		ERROSINT
; ---- SUBROTINA SEMANTICA, DIRECIONA PROS TESTES SEMANTICOS ----------
INISEM		K		/0000
;
			SB 		EOL			; Testa o EOL para direcionar para o tratamento
			JZ 		EOLSRSEM
			JP 		NEOLSEM
EOLSRSEM 	SC 		EOLSEM
NEOLSEM		AD 		EOL
;
			SB 		/0020		; Testa o espaço para direcionar para o tratamento
			JZ 		ESPACOSEM
			JP 		NSPSEM
ESPACOSEM	SC 		SPSEM
NSPSEM		AD 		/0020
;
			SB 		/002F		; Checa barra para direcionar para o tratamento de comentário
			JZ 		COMENTSRSE
			JP 		NCSRSE
COMENTSRSE 	SC 		COMENTSEM
SCSRSE 		AD 		/002F
;
			SB 		/0067     ;  TRATA COMEÇOS COM g, PARA TESTARMOS O goto
			JZ 		GOTOSEMSR
			JP		NGOTOSEM
GOTOSEMSR	SC 		GOTO_SEM
NGOTOSEM 	AD 		/0067
;
			SB 		/0069     ;  TRATA COMEÇOS COM i, PARA TESTARMOS O if
			JZ 		INTSEMSR
			JP		NINTSEM
INTSEMSR	SC 		INT_SEM
NINTSEM 	AD 		/0069
;
			SB 		/0070     ;  TRATA COMEÇOS COM p, PARA TESTARMOS O print
			JZ 		PRINTSEMSR
			JP		NPRINTSEM
PRINTSEMSR	SC 		PRINT_SEM
NPRINTSEM 	AD 		/0070
;
			SB 		/0073     ;  TRATA COMEÇOS COM s, PARA TESTARMOS O scan
			JZ 		SCANSEMSR
			JP		NSCANSEM
SCANSEMSR	SC 		SCAN_SEM
NSCANSEM 	AD 		/0073
;
			SB		/0041 	  ;  TRATAMENTO PARA LETRAS
			JN 		SEM_ERRO
			AD 		/0041
;
			SB 		/005B
			JZ 		VAR1SEM
			JP		NVARSEM1
VAR1SEM		SC 		TESTVSEM	; Direciona para o teste de rótulos/variáveis
			SC 		ATTDADO
			JP 		CICLOSEM
NVARSEM1	AD 		/005B
;
			SB 		/0061
			JN 		SEM_ERRO
			AD 		/0061
;
			SB 		/007B
			JZ 		VAR2SEM
			SC 		ERROSEM
VAR2SEM		SC 		TESTVSEM	; Direciona para o teste de rótulos/variáveis
			SC 		ATTDADO
			JP 		CICLOSEM
;
SEM_ERRO 	SC 		ERROSEM
			RS 		INISEM
;
; ---- EOL SEMANTICO --------------------------------------------------
EOLSEM 		K 		/0000
ENTRY_EOL	SC 		ATTDADO		; Lê e descarta EOL até encontrar qualquer outro byte diferente
			LD  	DADOTEST
			SB 		EOL
			JZ 		ENTRY_EOL
			JP 		CICLOSEM
; ---- ESPACO SEMANTICO -----------------------------------------------
SPSEM 		K 		/0000	
ENTRY_SP	SC 		ATTDADO		; Lê e descarta espaços até encontrar qualquer outro byte diferente
			LD  	DADOTEST
			SB 		/0020
			JZ 		ENTRY_SP
			JP 		CICLOSEM
; ---- COMENTARIO SEMANTICO -------------------------------------------
COMENTSEM	K 		/0000
			SC 		ATTDADO
			LD 		DADOTEST
			SB 		/002F		; Testa a segunda barra do comentário
			JZ 		ENTRY_CMT
			SC 		ERROSEM
ENTRY_CMT	SC 		ATTDADO		; Se houver o // começa a ler e descartar entradas até encontrar um EOL
			LD  	DADOTEST
			SB 		EOL
			JZ 		CICLOSEM
			JP 		ENTRY_CMT
; ---- CHAR SEMANTICO -------------------------------------------------
; ---- INT SEMANTICO --------------------------------------------------
; ---- VARIAVEIS E ROTULOS SEMANTICO ----------------------------------
; ---- GOTO SEMANTICO -------------------------------------------------
; ---- IF SEMANTICO ---------------------------------------------------
; ---- PRINT SEMANTICO ------------------------------------------------
; ---- SCAN SEMANTICO -------------------------------------------------
; ---- ERRO SEMANTICO -------------------------------------------------
ERROSEM 	K 		/0000
; DEFINIÇÃO PROVISORIA PARA O ERRO
			LV 		/FFFF		; Encerra a máquina se encontrar um erro, e carrega /FFFF
			HM 		ERROSEM
			RS 		ERROSEM
;
FIM 		HM 		FIM
;			
# MAIN			