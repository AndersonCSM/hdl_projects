// MÓDULO: datapath (Núcleo do Perceptron)
// Descrição:
//   Implementa o caminho de dados do perceptron single-layer. Responsável por:
//   • Armazenar pesos (w0, w1) de 8 bits com sinal
//   • Carregar dados de treinamento
//   • Calcular soma ponderada: soma = x0*w0 + x1*w1
//   • Aplicar função de ativação (threshold)
//   • Calcular erro: erro = y_esperado - y_predito
//   • Atualizar pesos com aprendizado Hebbiano
//
// Portas:
//   - clk: Clock do sistema
//   - load_indice_amostra: Incrementar contador de amostras (N)
//   - clr_indice_amostra: Resetar contador de amostras
//   - load_epoch: Incrementar contador de épocas
//   - clr_epoch: Resetar contador de épocas
//   - update_pesos: Atualizar pesos com aprendizado
//   - rst_pesos: Zerar todos os pesos
//   - load_erro: Registrar o erro calculado
//   - clr_erro: Zerar o registrador de erro
//   - max_epoch: Máximo de épocas permitidas
//   - epoch_disponivel: STATUS - ainda há épocas para treinar?
//   - amostra_disponivel: STATUS - ainda há amostras para processar?
//   - w0, w1: Saída dos pesos (visível para os LEDs)
//
// Equações do Perceptron:
//   1. Soma ponderada: s = x[0]*w0 + x[1]*w1
//   2. Ativação: y_pred = (s >= threshold) ? 1 : 0
//   3. Erro: e = y_esperado - y_pred
//   4. Atualização: w = w + e*x

module datapath(
    // ENTRADAS
    input clk,
    input load_indice_amostra,        
    input clr_indice_amostra,         
    input load_epoch,             
    input clr_epoch,              
    input update_pesos,           
    input rst_pesos,              
    input load_erro,              
    input clr_erro,               
    input [3:0] max_epoch,        // (máximo de épocas)
    
    // SAÍDAS DE STATUS
    output epoch_disponivel,      // epoch_disponivel (pode treinar mais épocas?)
    output amostra_disponivel,    // amostra_disponivel (há mais amostras?)
    
    // SAÍDAS DE DADOS
    output reg signed [7:0] peso_w0,    // w0
    output reg signed [7:0] peso_w1     // w1
);

    // REGISTRADORES INTERNOS
    
    // Contadores
    reg [3:0] contador_amostra;             // qual amostra: 0-3
    reg [3:0] contador_epoca;               // qual época
    reg signed [1:0] registrador_erro;      // Armazena erro calculado

    // Dados de treinamento (Função OR)
    reg [1:0] entrada_amostras [0:3];       // X (4 amostras de 2 bits)
    reg saida_esperada [0:3];               // y_target (4 saídas esperadas)

    // Sinais combinacionais internos
    wire signed [8:0] soma_ponderada;       // soma (resultado da multiplicação)
    wire saida_predita;                     // y_pred (saída da função de ativação)
    wire signed [1:0] erro_calculado;       // erro_wire (erro combinacional)

    // PARÂMETROS
    
    parameter signed THRESHOLD = 1;         // limiar = 1 (Função de Ativação)

    // INICIALIZAÇÃO - Dados de Treinamento (Função OR)
    
    // Tabela de Verdade da Porta OR:
    //   Entrada (x1, x0) │ Saída Esperada (y)
    //   ─────────────────┼───────────────────
    //        (0, 0)      │        0
    //        (0, 1)      │        1
    //        (1, 0)      │        1
    //        (1, 1)      │        1
    //
    initial begin
        entrada_amostras[0] = 2'b00; saida_esperada[0] = 1'b0;
        entrada_amostras[1] = 2'b01; saida_esperada[1] = 1'b1;
        entrada_amostras[2] = 2'b10; saida_esperada[2] = 1'b1;
        entrada_amostras[3] = 2'b11; saida_esperada[3] = 1'b1;
        
        peso_w0 = 8'sd0;           // w0 começa em 0
        peso_w1 = 8'sd0;           // w1 começa em 0
        contador_amostra = 4'd0;   // N = 0
        contador_epoca = 4'd0;     // EP = 0
        registrador_erro = 2'sd0;  // Erro = 0
    end

    // LÓGICA COMBINACIONAL - Cálculo da Predição
    
    // Passo 1: Multiplicar entradas pelos pesos (x * w)
    wire signed [8:0] termo_w0 = entrada_amostras[contador_amostra][0] * peso_w0;
    wire signed [8:0] termo_w1 = entrada_amostras[contador_amostra][1] * peso_w1;
    
    // Passo 2: Calcular soma ponderada
    // soma = x0*w0 + x1*w1
    assign soma_ponderada = termo_w0 + termo_w1;
    
    // Passo 3: Aplicar Função de Ativação (Threshold)
    // saída = 1 se soma >= threshold, senão 0
    assign saida_predita = (soma_ponderada >= THRESHOLD) ? 1'b1 : 1'b0;

    // Passo 4: Calcular Erro
    // erro = y_esperado - y_predito
    // considera o sinal da operação
    assign erro_calculado = $signed({1'b0, saida_esperada[contador_amostra]}) - 
                            $signed({1'b0, saida_predita});


    // LÓGICA COMBINACIONAL - Sinais de Status
    
    // Status 1: Há mais épocas para treinar?
    // epoch_disponivel = 1 se contador_epoca < max_epoch
    assign epoch_disponivel = (contador_epoca < max_epoch) ? 1'b1 : 1'b0;
    
    // Status 2: Há mais amostras para processar? Caso usar mais amostras modificar
    // amostra_disponivel = 1 se contador_amostra < 4 (temos 4 amostras: 0-3)
    assign amostra_disponivel = (contador_amostra < 4) ? 1'b1 : 1'b0;

    // LÓGICA SEQUENCIAL - Registradores (Ativados na Borda de Subida do CLK)
    always @(posedge clk) begin
        
        // CONTROLE DO CONTADOR DE AMOSTRAS (N)
        // N percorre as 4 amostras de treinamento: 0, 1, 2, 3
        if (clr_indice_amostra) begin
            // Reseta para começar da amostra 0
            contador_amostra <= 4'd0;
        end
        else if (load_indice_amostra) begin
            // Passa para a próxima amostra
            contador_amostra <= contador_amostra + 4'd1;
        end
        
        // CONTROLE DO CONTADOR DE ÉPOCAS
        // Contabiliza quantas vezes todos os padrões foram processados
        if (clr_epoch) begin
            // Reseta para começar a época 0
            contador_epoca <= 4'd0;
        end
        else if (load_epoch) begin
            // Passa para a próxima época
            contador_epoca <= contador_epoca + 4'd1;
        end
        
        // CONTROLE DO REGISTRADOR DE ERRO
        // Armazena o erro calculado (y_esperado - y_predito)
        if (clr_erro) begin
            // Zera o erro armazenado
            registrador_erro <= 2'sd0;
        end
        else if (load_erro) begin
            // Captura o erro calculado pela lógica combinacional
            registrador_erro <= erro_calculado;
        end
        
        // CONTROLE DOS PESOS (w0, w1)
        // Equação de Atualização: w_novo = w_antigo + erro * entrada
        if (rst_pesos) begin
            // Reseta todos os pesos para 0 (começo do treino)
            peso_w0 <= 8'sd0;
            peso_w1 <= 8'sd0;
        end
        else if (update_pesos) begin
            // Atualiza os pesos usando o erro armazenado e a entrada atual
            // w0 ← w0 + registrador_erro * x[N][0]
            peso_w0 <= peso_w0 + (registrador_erro * entrada_amostras[contador_amostra][0]);
            // w1 ← w1 + registrador_erro * x[N][1]
            peso_w1 <= peso_w1 + (registrador_erro * entrada_amostras[contador_amostra][1]);
        end
        
    end

endmodule