segment code
..start:

    
    XOR AX, AX
    XOR BX, BX
    XOR CX, CX
    XOR DX, DX

    MOV     AX, data
    MOV     DS, AX
    MOV     AX, stack
    MOV     SS, AX
    MOV     SP, stacktop

    ; Configurar modo gráfico
    MOV     AH, 0Fh
    INT     10h
    MOV     [modo_anterior], AL
    MOV     AX, 0012h
    INT     10h
    CALL tela_de_dificuldade
    call limpa_tela_toda
    CALL main_loop

main_loop:
    CALL limpa_objetos
    call wait_sync
    CALL captura_entrada
    CALL atualiza_bola
    CALL verifica_colisao    ; Verifica colisões com paddles e bordas
    CALL desenhar_jogadores
    call wait_sync
    JMP main_loop


wait_sync:
    mov dx,03DAh
wait_end:
    in al,dx
    test al,8
    jnz wait_end
wait_start:
    in al,dx
    test al,8
    jz wait_start
    ret

limpa_tela_toda:
    MOV     AX, 0012h
    INT     10h
    call desenhar_linhas
    call desenhar_blocos_laterais
    jmp main_loop

limpa_objetos:
    call limpa_bola
    call limpa_jogadores

    ret

limpa_bola:
    MOV     byte [cor], preto  ; Escolha a cor da bola
    PUSH    word [bola_x_antigo]      ; Empilha X
    PUSH    word [bola_y_antigo]      ; Empilha Y
    PUSH    word [bola_raio]   ; Empilha raio
    CALL    full_circle        ; Chama a função de desenho
    RET

limpa_jogadores:

    CALL limpa_jogador_1
    CALL limpa_jogador_2
    ret


limpa_jogador_1:

    MOV AX, [ret1_y_antigo]  ; Carrega o valor de ret2_y_antigo para AX
    CMP AX, [ret1_y]         ; Compara AX com ret2_y
    je fim_limpeza
    MOV     byte [cor], preto
    MOV     CX, [ret1_x]
    MOV     DX, [ret1_y_antigo]
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura]       ; X final
    MOV     BX, DX
    ADD     BX, [altura]        ; Y final
    CALL    desenhar_retangulo
    ret

limpa_jogador_2:
    MOV AX, [ret2_y_antigo]  ; Carrega o valor de ret2_y_antigo para AX
    CMP AX, [ret2_y]         ; Compara AX com ret2_y
    je fim_limpeza
    ; Desenhar segundo retângulo (direita)
    MOV     byte [cor], preto
    MOV     CX, [ret2_x]
    MOV     DX, [ret2_y_antigo]
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura]       ; X final
    MOV     BX, DX
    ADD     BX, [altura]        ; Y final
    CALL    desenhar_retangulo
    ret

fim_limpeza:
    ret

limpa_tela:
    mov dx, 03C4h        ; Porta do Sequencer
    mov ax, 0F02h        ; Seleciona todos os planos de cor
    out dx, ax
    mov ax, 0A000h       ; Segmento de memória de vídeo
    mov es, ax
    mov bx, 20           ; Começa em y=40 (borda superior)

.loop_linhas:
    cmp bx, 460          ; Processa até y=440 (480 - 40)
    jge .fim_limpeza

    ; Offset da linha: y * 80 + byte_inicial (x=50 → byte 6)
    mov ax, bx
    mov cx, 80
    mul cx               ; AX = y * 80
    add ax, 6            ; Começa no byte 6 (x=50)
    mov di, ax

    ; Limpa 68 bytes (34 palavras) até x=590 (byte 73)
    mov cx, 34           ; 34 palavras = 68 bytes
    xor ax, ax           ; Cor preta
    rep stosw

    inc bx
    jmp .loop_linhas

.fim_limpeza:
    ret

gol_jogador1:
    jmp game_over

gol_jogador2:
    jmp game_over

reset_bola:
    mov word [bola_x], 320
    mov word [bola_y], 240
    neg word [bola_vel_x]
    neg word [bola_vel_y]
    ret

desenhar_jogadores:
    MOV     byte [cor], branco_intenso
    MOV     CX, [ret1_x]
    MOV     DX, [ret1_y]
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura]       ; X final
    MOV     BX, DX
    ADD     BX, [altura]        ; Y final
    CALL    desenhar_retangulo
    

    ; Desenhar segundo retângulo (direita)
    MOV     byte [cor], verde_claro
    MOV     CX, [ret2_x]
    MOV     DX, [ret2_y]
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura]       ; X final
    MOV     BX, DX
    ADD     BX, [altura]        ; Y final
    CALL    desenhar_retangulo

    CALL    desenhar_bola
    ret

desenhar_blocos_laterais:
    MOV CX, 5
    MOV SI, left_blocks
    call desenhar_blocos


    MOV CX, 5
    MOV SI, right_blocks
    call desenhar_blocos

    ret


tela_de_pausa:
    MOV     AH, 0
    MOV     AL, [modo_anterior]
    MOV     SI, pausa_mensagem  ; Carrega o endereço da string em SI
    MOV     BL, 0x0F ; determinando a cor a partir de uma tabela fixa do registrador BL
    
    MOV     CX,5				;número de caracteres
    MOV     BX,0
    MOV     DH,15				;linha 0-29
    MOV     DL,28				;coluna 0-79
    MOV		byte[cor], branco_intenso
pausa_loop:
    CALL    cursor
    MOV     AX, [BX+pausa_mensagem]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    pausa_loop

    ; para sair da pausa
espera_p:
    MOV ah, 08h
    INT 21h
    cmp al, 'p'
    jne tela_de_pausa
    call limpa_tela_toda
    ret

desenhar_linhas:

    call desenhar_linha_superior
    call desenhar_linha_inferior
    ret


desenhar_linha_superior:
    MOV		byte[cor],branco_intenso	
	MOV		AX,20
	PUSH	AX
	MOV		AX,460
	PUSH	AX
	MOV		AX,620
	PUSH	AX
	MOV		AX,460
	PUSH	AX
	CALL	line
    ret

desenhar_linha_inferior:
    MOV		byte[cor],branco_intenso	;antenas
	MOV		AX,20
	PUSH	AX
	MOV		AX,10
	PUSH	AX
	MOV		AX,620
	PUSH	AX
	MOV		AX,10
	PUSH	AX
	CALL	line
    ret

desenhar_blocos:
    MOV ax, [SI+6] ; Ativo
    cmp ax, 0
    je .fim_blocos
    PUSH CX
    MOV     AL, [SI+4]
    MOV     byte [cor], AL
    MOV     CX, [SI]
    MOV     AX, CX
    ADD     AX, [largura]       ; X final
    MOV     DX, [SI+2]
    MOV     BX, DX
    ADD     BX, [altura]        ; Y final
    PUSH SI
    CALL    desenhar_retangulo
    POP SI
    POP CX

.fim_blocos
    ADD SI, 8
    loop desenhar_blocos
    CALL    desenhar_bola
    RET

tela_de_sair:
    MOV     AH, 0
    MOV     AL, [modo_anterior]
    MOV     SI, sair_mensagem  ; Carrega o endereço da string em SI
    MOV     BL, 0x0F ; determinando a cor a partir de uma tabela fixa do registrador BL
    
    MOV     CX,25				;número de caracteres
    MOV     BX,0
    MOV     DH,15				;linha 0-29
    MOV     DL,28				;coluna 0-79
    MOV		byte[cor], branco_intenso
    CALL    sim_ou_nao
    CMP     CL, 1
    JNE     tela_sair_fim
    CALL    encerra



tela_sair_fim:
    call limpa_tela
    RET

game_over:
    MOV     SI, game_over_mensagem ; Carrega o endereço da string em SI
    MOV     BL, 0x0F ; determinando a cor a partir de uma tabela fixa do registrador BL
    
    MOV     CX,9				;número de caracteres
    MOV     BX,0
    MOV     DH,5				;linha 0-29
    MOV     DL,35				;coluna 0-79
    MOV		byte[cor], branco_intenso
imprime_game_over:
    CALL    cursor
    MOV     AX, [BX+SI]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    imprime_game_over


tela_de_reiniciar:
    MOV     SI, reiniciar_mensagem ; Carrega o endereço da string em SI
    MOV     BL, 0x0F ; determinando a cor a partir de uma tabela fixa do registrador BL
    
    MOV     CX,29				;número de caracteres
    MOV     BX,0
    MOV     DH,15				;linha 0-29
    MOV     DL,28				;coluna 0-79
    MOV		byte[cor], branco_intenso
    CALL    sim_ou_nao
    CMP     CL, 1
    JE      reiniciando
    CALL encerra

reiniciando:
    call reset_variaveis
    CALL limpa_tela_toda
    JMP ..start

reset_variaveis:
    ; Resetar posição e velocidade da bola
    mov word [bola_x], 320
    mov word [bola_y], 240
    mov word [bola_x_antigo], 320
    mov word [bola_y_antigo], 240
    
    ; Resetar posição dos jogadores
    mov word [ret1_y], 100
    mov word [ret2_y], 100
    
    ; Resetar blocos laterais (active=1)
    mov cx, 5
    mov si, left_blocks
.reset_left:
    mov word [si+6], 1
    add si, 8
    loop .reset_left
    
    mov cx, 5
    mov si, right_blocks
.reset_right:
    mov word [si+6], 1
    add si, 8
    loop .reset_right
    ret

sim_ou_nao:
    CALL    cursor
    MOV     AX, [BX+SI]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    sim_ou_nao

    ; caixa para ter um "sim" escrito
    MOV     byte [cor], branco_intenso
    MOV     CX, [retsim_x]
    MOV     DX, [retsim_y]
    
    CALL    desenha_caixa_sim

    ; caixa para ter um "não" escrito
    MOV     byte [cor], branco_intenso
    MOV     CX, [retnao_x]
    MOV     DX, [retnao_y]
    
    CALL    desenha_caixa_nao

; precisa trabalhar limpeza de buffer com isso daqui, mas funciona para seleções múltiplas (base da tela de dificuldade)
seleciona_nao:
    MOV     byte [cor], branco_intenso
    MOV     CX, [retsim_x]
    MOV     DX, [retsim_y]
    CALL    desenha_caixa_sim

    MOV     byte [cor], ciano
    MOV     CX, [retnao_x]
    MOV     DX, [retnao_y]
    CALL    desenha_caixa_nao

    MOV     AH, 08h
    INT     21h
    CMP     AL, 4DH ; seta direita
    JE      seleciona_sim
    CMP     AL, 4BH ; seta esquerda
    JE      seleciona_sim
    CMP     AL, 0DH
    JNE     seleciona_nao
    RET

seleciona_sim:
    MOV     byte [cor], branco_intenso
    MOV     CX, [retnao_x]
    MOV     DX, [retnao_y]
    CALL    desenha_caixa_nao

    MOV     byte [cor], ciano
    MOV     CX, [retsim_x]
    MOV     DX, [retsim_y]
    CALL    desenha_caixa_sim

    MOV     AH, 08h
    INT     21h
    CMP     AL, 0DH
    JE      seta_flag_sim
    CMP     AL, 4DH ; seta direita
    JE      seleciona_nao
    CMP     AL, 4BH ; seta esquerda
    JE      seleciona_nao
    JMP     seleciona_sim

seta_flag_sim:
    MOV     CL, 1
    RET

seta_flag_nao:
    MOV     CL, 0
    RET

encerra:
    CALL    limpa_tela
    INT     10h
    MOV     AX, 4C00h
    INT     21h

tela_de_dificuldade:
    MOV     SI, texto_dificuldade ; Carrega o endereço da string em SI
    MOV     BL, 0x0F ; determinando a cor a partir de uma tabela fixa do registrador BL
    
    MOV     CX,23				;número de caracteres
    MOV     BX,0
    MOV     DH,15				;linha 0-29
    MOV     DL,28				;coluna 0-79
    MOV		byte[cor], branco_intenso
dificuldade_loop:
    CALL    cursor
    MOV     AX, [BX+texto_dificuldade]
    CALL    caracter
    INC     BX					;proximo caracter
	INC     DL					;avanca a coluna
    LOOP    dificuldade_loop

    ; caixa para ter um "fácil" escrito
    MOV     byte [cor], branco_intenso
    MOV     CX, [retfacil_x]
    MOV     DX, [retfacil_y]
    
    CALL    desenha_caixa_facil

    ; caixa para ter um "medio" escrito
    MOV     byte [cor], branco_intenso
    MOV     CX, [retmedio_x]
    MOV     DX, [retmedio_y]
    
    CALL    desenha_caixa_medio

    ; caixa para ter um "dificil" escrito
    MOV     byte [cor], branco_intenso
    MOV     CX, [retdificil_x]
    MOV     DX, [retdificil_y]
    
    CALL    desenha_caixa_dificil

seleciona_dificuldade:
    MOV     byte [cor], ciano
    MOV     CX, [retfacil_x]
    MOV     DX, [retfacil_y]
    CALL    desenha_caixa_facil

    MOV     AH, 08h
    INT     21h
    CMP     AL, 4BH ; seta esquerda
    JE      seleciona_dificil
    CMP     AL, 4DH ; seta direita
    JE      seleciona_medio
    CMP     AL, 0DH
    JNE     seleciona_dificuldade
    RET

seleciona_medio:
    MOV     word [bola_vel_x], 15
    MOV     word [bola_vel_y], 15
    MOV     byte [cor], branco_intenso
    MOV     CX, [retfacil_x]
    MOV     DX, [retfacil_y]
    CALL    desenha_caixa_facil

    MOV     byte [cor], ciano
    MOV     CX, [retmedio_x]
    MOV     DX, [retmedio_y]
    CALL    desenha_caixa_medio


    MOV     byte [cor], branco_intenso
    MOV     CX, [retdificil_x]
    MOV     DX, [retdificil_y]
    CALL    desenha_caixa_dificil

    MOV     AH, 08h
    INT     21h
    CMP     AL, 4BH ; seta esquerda
    JE      seleciona_facil
    CMP     AL, 4DH ; seta direita
    JE      seleciona_dificil
    CMP     AL, 0DH
    JNE      seleciona_medio
    RET

seleciona_dificil:
    MOV     word [bola_vel_x], 20
    MOV     word [bola_vel_y], 20
    MOV     byte [cor], branco_intenso
    MOV     CX, [retfacil_x]
    MOV     DX, [retfacil_y]
    CALL    desenha_caixa_facil

    MOV     byte [cor], branco_intenso
    MOV     CX, [retmedio_x]
    MOV     DX, [retmedio_y]
    CALL    desenha_caixa_medio


    MOV     byte [cor], ciano
    MOV     CX, [retdificil_x]
    MOV     DX, [retdificil_y]
    CALL    desenha_caixa_dificil

    MOV     AH, 08h
    INT     21h
    CMP     AL, 4BH ; seta esquerda
    JE      near seleciona_medio
    CMP     AL, 4DH ; seta direita
    JE      near seleciona_facil
    CMP     AL, 0DH
    JNE     seleciona_dificil
    RET

seleciona_facil:
    MOV     word [bola_vel_x], 10
    MOV     word [bola_vel_y], 10
    MOV     byte [cor], ciano
    MOV     CX, [retfacil_x]
    MOV     DX, [retfacil_y]
    CALL    desenha_caixa_facil

    MOV     byte [cor], branco_intenso
    MOV     CX, [retmedio_x]
    MOV     DX, [retmedio_y]
    CALL    desenha_caixa_medio


    MOV     byte [cor], branco_intenso
    MOV     CX, [retdificil_x]
    MOV     DX, [retdificil_y]
    CALL    desenha_caixa_dificil

    MOV     AH, 08h
    INT     21h
    CMP     AL, 4BH ; seta esquerda
    JE      near seleciona_facil
    CMP     AL, 4DH ; seta direita
    JE      near seleciona_dificil
    CMP     AL, 0DH
    JNE     seleciona_facil
    RET

sair:
    MOV     AH, 0
    MOV     AL, [modo_anterior]
    INT     10h  
    MOV     AX, 4C00h
    INT     21h
;-------------------------------------------------------------------------------
; FUNÇÕES DE MOVIMENTO
;-------------------------------------------------------------------------------


escrever_texto:
    ; Agora imprime a string
    mov ah, 0Eh     ; Função para escrever caractere
imprimir_loop:
    lodsb           ; Carrega o próximo caractere de SI em AL
    cmp al, 0       ; Verifica se é o fim da string
    je fim_imprimir ; Se for o fim da string, termina
    int 10h         ; Exibe o caractere
    jmp imprimir_loop ; Repete para o próximo caractere
fim_imprimir:
    ret

inverte_y:
    NEG     word [bola_vel_y]  ; Inverte direção vertical
    ret

verifica_colisao:
    ; --- Colisão com bordas superior/inferior ---
    mov ax, [bola_y]
    sub ax, [bola_raio]       ; Considera o topo da bola
    cmp ax, 40                ; Rebater ao ultrapassar os 20px no topo
    jl inverte_y              ; Inverter a direção Y se ultrapassou

    ; --- Colisão com a borda inferior ---
    mov ax, [bola_y]
    add ax, [bola_raio]       ; Considera a base da bola
    cmp ax, 440               ; Rebater ao ultrapassar os 460px (480 - 20)
    jg inverte_y              ; Inverter a direção Y se ultrapassou

    ; --- Verificação de gols ---
    mov ax, [bola_x]
    sub ax, [bola_raio]
    cmp ax, BORNA_ESQUERDA ; Bola ultrapassou a borda esquerda?
    jle near gol_jogador2

    mov ax, [bola_x]
    add ax, [bola_raio]
    cmp ax, BORNA_DIREITA  ; Bola ultrapassou a borda direita?
    jge near gol_jogador1

    ; --- Colisão com paddles ---

    call colisao_paddle_direito
    call colisao_paddle_esquerdo


    call colisao_blocos_direita
    call colisao_blocos_esquerda
    ret
    

colisao_paddle_esquerdo:
    cmp word [bola_vel_x], 0
    jg fim_colisoes_esquerdo
    ; Verifica colisão com paddle esquerdo

    mov ax, [ret1_x]
    add ax, [largura]
    sub ax, [bola_raio]
    add ax, [largura]
    cmp [bola_x], ax
    jg fim_colisoes_esquerdo
    mov ax, [ret1_y]
    cmp [bola_y], ax
    jl fim_colisoes_esquerdo
    mov ax, [ret1_y]
    add ax, [altura]
    sub ax, [bola_raio]
    cmp [bola_y], ax
    jl near colisao


colisao_blocos_esquerda:
    cmp word [bola_vel_x], 0
    jg fim_colisoes_esquerdo
    mov SI, left_blocks
    mov ax, [SI+6]
    cmp ax, 0
    je fim_colisoes_esquerdo
    mov ax, [SI]
    add ax, [largura]
    add ax, [bola_raio]
    cmp [bola_x], ax
    jg fim_colisoes_esquerdo

    mov cx, 5
    jmp verifica_y

fim_colisoes_esquerdo:
    ret

colisao_paddle_direito:
    ; Verifica colisão com paddle direito
    cmp word [bola_vel_x], 0
    jl fim_colisoes_direita
    mov ax, [ret2_x]
    add ax, [bola_raio]
    sub ax, [largura]
    cmp [bola_x], ax
    jl fim_colisoes_direita
    mov ax, [ret2_y]
    cmp [bola_y], ax
    jl fim_colisoes_direita
    mov ax, [ret2_y]
    add ax, [altura]
    cmp [bola_y], ax
    jl colisao

colisao_blocos_direita:

    cmp word [bola_vel_x], 0
    jl fim_colisoes_direita
    mov SI, right_blocks
    mov ax, [SI+6]
    cmp ax, 0
    je fim_colisoes_direita
    mov ax, [SI]
    sub ax, [bola_raio]
    cmp [bola_x], ax
    jl fim_colisoes_direita

    mov cx, 5
    jmp verifica_y
    
fim_colisoes_direita:
    ret

verifica_y:
    MOV ax, [SI + 6]
    CMP ax, 0
    je loop_blocos
    MOV ax, [SI + 2]
    ADD ax, [altura]
    cmp [bola_y], ax
    jle colisao_bloco
loop_blocos:
    ADD SI, 8
    loop verifica_y

colisao:
    neg word [bola_vel_x]  ; Inverte direção horizontal
    ret

colisao_bloco:
    neg word [bola_vel_x]  ; Inverte direção horizontal
    MOV word [SI+6], 0
    call limpa_tela_toda
    ret
fim_colisoes:
    ret


atualiza_bola:


    
    MOV AX, [bola_x]       
    MOV [bola_x_antigo], AX 
    MOV AX, [bola_y]      
    MOV [bola_y_antigo], AX

    MOV     AX, [bola_vel_x]
    ADD     [bola_x], AX
    MOV     AX, [bola_vel_y]
    ADD     [bola_y], AX


captura_entrada:
    ; Leitura de teclado não bloqueante
    mov ah, 01h
    int 16h
    jz .fim
    
    mov ah, 00h
    int 16h
    
    ; Controles paddle esquerdo (W/S)
    cmp al, 'w'
    je p1_up
    cmp al, 's'
    je p1_down

    cmp ah, 48h
    je p2_up
    cmp ah, 50h
    je p2_down

    ; Tecla q para sair
    cmp al, 'q'
    je near tela_de_sair

    ; tecla p para pausar
    cmp al, 'p'
    je near tela_de_pausa

    cmp al, 'r'
    je near tela_de_reiniciar

.fim:
    ret


p1_up:
    MOV AX, [ret1_y]
    MOV [ret1_y_antigo], AX
    add word [ret1_y], velocidade_paddle
    jmp limite_p1
p1_down:
    MOV AX, [ret1_y]
    MOV [ret1_y_antigo], AX
    sub word [ret1_y], velocidade_paddle

limite_p1:
    mov ax, [ret1_y]
    ; Limite inferior (topo não passa de 20px do topo da tela)
    cmp ax, 20                ; Novo mínimo = 20px 
    jge check_max_p1
    mov ax, 20
    jmp p1_save
    
check_max_p1:
    ; Limite superior (topo não passa de 480-20-altura_paddle)
    mov bx, 460               ; Altura total da tela (modo 12h)
    sub bx, 20                ; Margem inferior de 20px
    sub bx, [altura]   ; Subtrai a altura do paddle
    cmp ax, bx
    jle p1_save
    mov ax, bx
    
p1_save:
    mov [ret1_y], ax
    ret

p2_up:
    MOV AX, [ret2_y]
    MOV [ret2_y_antigo], AX
    add word [ret2_y], velocidade_paddle
    jmp limite_p2
p2_down:
    MOV AX, [ret2_y]
    MOV [ret2_y_antigo], AX
    sub word [ret2_y], velocidade_paddle

limite_p2:
    mov ax, [ret2_y]
    cmp ax, 20                
    jge check_max_p2
    mov ax, 20
    jmp p2_save
    
check_max_p2:
    ; Limite superior (topo não passa de 480-20-altura_paddle)
    mov bx, 460               ; Altura total da tela (modo 12h)
    sub bx, 20                ; Margem inferior de 20px
    sub bx, [altura]    ; Subtrai a altura do paddle
    cmp ax, bx
    jle p2_save
    mov ax, bx
p2_save:
    mov [ret2_y], ax
    ret
   

;-------------------------------------------------------------------------------
; FUNÇÕES DE DESENHO
;-------------------------------------------------------------------------------
desenhar_retangulo:
    ; Preencher o retângulo
    MOV     SI, DX              ; SI = Y atual
preencher:
    CMP     SI, BX
    JGE     fim_preenchimento   ; Terminar quando SI >= Y final
    PUSH    CX                  ; X inicial
    PUSH    SI                  ; Y
    PUSH    AX                  ; X final
    PUSH    SI                  ; Y
    CALL    line
    
    INC     SI                  ; Próxima linha
    JMP     preencher
fim_preenchimento:
    RET

desenha_caixa_sim:
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura_com_texto]       ; X final
    MOV     BX, DX
    ADD     BX, [altura_com_texto]        ; Y final
    CALL    desenhar_retangulo

    MOV     CX,3				;número de caracteres
    MOV     BX,0
    MOV     DH,20				;linha 0-29
    MOV     DL,25				;coluna 0-79
    MOV		byte[cor], branco_intenso
sim_confirma:
    CALL    cursor
    MOV     AX, [BX+texto_sim]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    sim_confirma

    RET

desenha_caixa_nao:
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura_com_texto]       ; X final
    MOV     BX, DX
    ADD     BX, [altura_com_texto]        ; Y final
    CALL    desenhar_retangulo

    MOV     CX,3				;número de caracteres
    MOV     BX,0
    MOV     DH,20				;linha 0-29
    MOV     DL,45				;coluna 0-79
    MOV		byte[cor], branco_intenso
nao_confirma:
    CALL    cursor
    MOV     AX, [BX+texto_nao]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    nao_confirma

    RET

desenha_caixa_facil:
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura_com_texto]       ; X final
    MOV     BX, DX
    ADD     BX, [altura_com_texto]        ; Y final
    CALL    desenhar_retangulo

    MOV     CX,5				;número de caracteres
    MOV     BX,0
    MOV     DH,20				;linha 0-29
    MOV     DL,15				;coluna 0-79
    MOV		byte[cor], branco_intenso
facil_confirma:
    CALL    cursor
    MOV     AX, [BX+texto_facil]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    facil_confirma

    RET

desenha_caixa_medio:
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura_com_texto]       ; X final
    MOV     BX, DX
    ADD     BX, [altura_com_texto]        ; Y final
    CALL    desenhar_retangulo

    MOV     CX,5				;número de caracteres
    MOV     BX,0
    MOV     DH,20				;linha 0-29
    MOV     DL,35				;coluna 0-79
    MOV		byte[cor], branco_intenso
medio_confirma:
    CALL    cursor
    MOV     AX, [BX+texto_medio]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    medio_confirma

    RET

desenha_caixa_dificil:
    ; CX = X inicial, DX = Y inicial
    MOV     AX, CX
    ADD     AX, [largura_com_texto]       ; X final
    MOV     BX, DX
    ADD     BX, [altura_com_texto]        ; Y final
    CALL    desenhar_retangulo

    MOV     CX,7				;número de caracteres
    MOV     BX,0
    MOV     DH,20				;linha 0-29
    MOV     DL,52				;coluna 0-79
    MOV		byte[cor], branco_intenso
dificil_confirma:
    CALL    cursor
    MOV     AX, [BX+texto_dificil]
    CALL    caracter
    INC     BX					;proximo caracter
	INC		DL					;avanca a coluna
    LOOP    dificil_confirma

    RET

plot_xy:
    PUSH    BP
    MOV     BP,SP
    PUSHf
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
    MOV     AH,0Ch
    MOV     AL,[cor]
    MOV     BH,0
    MOV     DX,479
    SUB     DX,[BP+4]
    MOV     CX,[BP+6]
    INT     10h
    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    POPf
    POP     BP
    RET     4

line:
    PUSH    BP
    MOV     BP,SP
    PUSHf
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
    MOV     AX,[BP+10]
    MOV     BX,[BP+8]
    MOV     CX,[BP+6]
    MOV     DX,[BP+4]
    CMP     AX,CX
    JE      line2
    JB      line1
    XCHG    AX,CX
    XCHG    BX,DX
    JMP     line1
line2:
    CMP     BX,DX
    JB      line3
    XCHG    BX,DX
line3:
    PUSH    AX
    PUSH    BX
    CALL    plot_xy
    CMP     BX,DX
    JNE     line31
    JMP     fim_line
line31:
    INC     BX
    JMP     line3
line1:
    PUSH    CX
    SUB     CX,AX
    MOV     [deltax],CX
    POP     CX
    PUSH    DX
    SUB     DX,BX
    JA      line32
    NEG     DX
line32:
    MOV     [deltay],DX
    POP     DX
    PUSH    AX
    MOV     AX,[deltax]
    CMP     AX,[deltay]
    POP     AX
    JB      line5
    PUSH    CX
    SUB     CX,AX
    MOV     [deltax],CX
    POP     CX
    PUSH    DX
    SUB     DX,BX
    MOV     [deltay],DX
    POP     DX
    MOV     SI,AX
line4:
    PUSH    AX
    PUSH    DX
    PUSH    SI
    SUB     SI,AX
    MOV     AX,[deltay]
    IMUL    SI
    MOV     SI,[deltax]
    SHR     SI,1
    CMP     DX,0
    JL      ar1
    ADD     AX,SI
    ADC     DX,0
    JMP     arc1
ar1:
    SUB     AX,SI
    SBB     DX,0
arc1:
    IDIV    word [deltax]
    ADD     AX,BX
    POP     SI
    PUSH    SI
    PUSH    AX
    CALL    plot_xy
    POP     DX
    POP     AX
    CMP     SI,CX
    JE      fim_line
    INC     SI
    JMP     line4
line5:
    CMP     BX,DX
    JB      line7
    XCHG    AX,CX
    XCHG    BX,DX
line7:
    PUSH    CX
    SUB     CX,AX
    MOV     [deltax],CX
    POP     CX
    PUSH    DX
    SUB     DX,BX
    MOV     [deltay],DX
    POP     DX
    MOV     SI,BX
line6:
    PUSH    DX
    PUSH    SI
    PUSH    AX
    SUB     SI,BX
    MOV     AX,[deltax]
    IMUL    SI
    MOV     SI,[deltay]
    SHR     SI,1
    CMP     DX,0
    JL      ar2
    ADD     AX,SI
    ADC     DX,0
    JMP     arc2
ar2:
    SUB     AX,SI
    SBB     DX,0
arc2:
    IDIV    word [deltay]
    MOV     DI,AX
    POP     AX
    ADD     DI,AX
    POP     SI
    PUSH    DI
    PUSH    SI
    CALL    plot_xy
    POP     DX
    CMP     SI,DX
    JE      fim_line
    INC     SI
    JMP     line6
fim_line:
    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    POPf
    POP     BP
    RET     8

cursor:
    PUSHf
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
    PUSH    BP
    MOV     AH,2
    MOV     BH,0
    INT     10h
    POP     BP
    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    POPf
    RET

caracter:
    PUSHf
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
    PUSH    BP
    MOV     AH,9
    MOV     BH,0
    MOV     CX,1
    MOV     bl,[cor]
    INT     10h
    POP     BP
    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    POPf
    RET


desenhar_bola:
    MOV     byte [cor], ciano  ; Escolha a cor da bola
    PUSH    word [bola_x]      ; Empilha X
    PUSH    word [bola_y]      ; Empilha Y
    PUSH    word [bola_raio]   ; Empilha raio
    CALL    full_circle        ; Chama a função de desenho
    RET

full_circle:
	PUSH 	BP
	MOV	 	BP,SP
	PUSHf                        ;coloca os flags na pilha
	PUSH 	AX
	PUSH 	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI

	MOV		AX,[BP+8]    		;resgata xc
	MOV		BX,[BP+6]    		;resgata yc
	MOV		CX,[BP+4]    		;resgata r
	
	MOV		SI,BX
	SUB		SI,CX
	PUSH    AX					;coloca xc na pilha			
	PUSH	SI					;coloca yc-r na pilha
	MOV		SI,BX
	ADD		SI,CX
	PUSH	AX					;coloca xc na pilha
	PUSH	SI					;coloca yc+r na pilha
	CALL line
		
	MOV		DI,CX
	SUB		DI,1	 			;DI = r-1
	MOV		DX,0  				;DX será a variável x. CX é a variavel y
	
;aqui em cima a lógica foi invertida, 1-r => r-1 e as comparações passaram a ser
;JL => JG, assimm garante valores positivos para d

stay_full:						;LOOP
	MOV		SI,DI
	CMP		SI,0
	JG		inf_full       		;caso d for menor que 0, seleciona pixel superior (não  salta)
	MOV		SI,DX				;o JL é importante porque trata-se de conta com sinal
	SAL		SI,1				;multiplica por doi (shift arithmetic left)
	ADD		SI,3
	ADD		DI,SI     			;nesse ponto d = d+2*DX+3
	INC		DX					;Incrementa DX
	JMP		plotar_full
inf_full:	
	MOV		SI,DX
	SUB		SI,CX  				;faz x - y (DX-CX), e salva em DI 
	SAL		SI,1
	ADD		SI,5
	ADD		DI,SI				;nesse ponto d=d+2*(DX-CX)+5
	INC		DX					;Incrementa x (DX)
	DEC		CX					;Decrementa y (CX)
	
plotar_full:	
	MOV		SI,AX
	ADD		SI,CX
	PUSH	SI					;coloca a abcisa y+xc na pilha			
	MOV		SI,BX
	SUB		SI,DX
	PUSH    SI					;coloca a ordenada yc-x na pilha
	MOV		SI,AX
	ADD		SI,CX
	PUSH	SI					;coloca a abcisa y+xc na pilha	
	MOV		SI,BX
	ADD		SI,DX
	PUSH    SI					;coloca a ordenada yc+x na pilha	
	CALL 	line
	
	MOV		SI,AX
	ADD		SI,DX
	PUSH	SI					;coloca a abcisa xc+x na pilha			
	MOV		SI,BX
	SUB		SI,CX
	PUSH    SI					;coloca a ordenada yc-y na pilha
	MOV		SI,AX
	ADD		SI,DX
	PUSH	SI					;coloca a abcisa xc+x na pilha	
	MOV		SI,BX
	ADD		SI,CX
	PUSH    SI					;coloca a ordenada yc+y na pilha	
	CALL	line
	
	MOV		SI,AX
	SUB		SI,DX
	PUSH	SI					;coloca a abcisa xc-x na pilha			
	MOV		SI,BX
	SUB		SI,CX
	PUSH    SI					;coloca a ordenada yc-y na pilha
	MOV		SI,AX
	SUB		SI,DX
	PUSH	SI					;coloca a abcisa xc-x na pilha	
	MOV		SI,BX
	ADD		SI,CX
	PUSH    SI					;coloca a ordenada yc+y na pilha	
	CALL	line
	
	MOV		SI,AX
	SUB		SI,CX
	PUSH	SI					;coloca a abcisa xc-y na pilha			
	MOV		SI,BX
	SUB		SI,DX
	PUSH    SI					;coloca a ordenada yc-x na pilha
	MOV		SI,AX
	SUB		SI,CX
	PUSH	SI					;coloca a abcisa xc-y na pilha	
	MOV		SI,BX
	ADD		SI,DX
	PUSH    SI					;coloca a ordenada yc+x na pilha	
	CALL	line
	
	CMP		CX,DX
	JB		fim_full_circle  	;se CX (y) está abaixo de DX (x), termina     
	JMP		stay_full			;se CX (y) está acima de DX (x), continua no LOOP
	
fim_full_circle:
	POP		DI
	POP		SI
	POP		DX
	POP		CX
	POP		BX
	POP		AX
	POPf
	POP		BP
	RET		6

segment data

    ; Relacionados ao retangulo
    largura      dw      20
    altura       dw      80
    ret1_x       dw      50
    ret1_y       dw      100
    ret2_x       dw      570
    ret2_y       dw      100
    velocidade_paddle dw  7

    ; Relacionados aos retangulos com confirmação
    ; escolha de 30px a partir do meio para sim e não
    largura_com_texto   dw  100
    altura_com_texto    dw 100
    retsim_x            dw 190
    retsim_y            dw 100
    retnao_x            dw 350
    retnao_y            dw 100
    retfacil_x          dw 100
    retfacil_y          dw 100
    retmedio_x          dw 250
    retmedio_y          dw 100
    retdificil_x        dw 400
    retdificil_y        dw 100

    ; relacionado às telas
    pausa_mensagem     db "Pausa", 0
    sair_mensagem      db "Voce deseja sair do jogo?", 0
    reiniciar_mensagem db "Voce deseja reiniciar o jogo?", 0 
    game_over_mensagem db "GAME OVER",0
    texto_sim          db "Sim", 0
    texto_nao          db "Nao", 0
    texto_dificuldade  db "Selecione a dificuldade",0
    texto_facil        db "Facil", 0
    texto_medio        db "Medio", 0
    texto_dificil      db "Dificil", 0

    ; Cores
    cor          db      branco_intenso
    preto           equ     0
    branco_intenso  equ     15
    verde_claro     equ     10
    ciano         equ 0Ch

    modo_anterior db     0
    deltax       dw      0
    deltay       dw      0

    ; Relacionados a bola
    bola_x dw 320      ; Posição X inicial (centro da tela 640x480)
    bola_y dw 240      ; Posição Y inicial
    bola_vel_x dw 10   ; Velocidade horizontal
    bola_vel_y dw 10    ; Velocidade vertical
    bola_raio dw 10     ; Raio da bola

    ;Limites de tela

    BORNA_ESQUERDA    equ 0
    BORNA_DIREITA     equ 640


    ret1_y_antigo dw 100
    ret2_y_antigo dw 100
    bola_x_antigo dw 320
    bola_y_antigo dw 240


    right_blocks:
        dw 600, 20, 9, 1    ; x, y, color, active
        dw 600, 105, 10, 1
        dw 600, 190, 11, 1
        dw 600, 275, 12, 1
        dw 600, 360, 13, 1
    
    left_blocks:
        dw 20, 20, 9, 1    ; x, y, color, active
        dw 20, 105, 10, 1
        dw 20, 190, 11, 1
        dw 20, 275, 12, 1
        dw 20, 360, 13, 1


segment stack stack
    resb 256
stacktop:
