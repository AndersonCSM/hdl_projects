module datapath(clk, load_w0, load_w1, clear_w0, clear_w1, load_epoch, clear_epoch, 
                load_n, clear_n, lerp, clrw, s, calcular, 
                epoch_menor, n_maior, y_pred, w0, w1);
   // ================== Declaração de portas ==================
   
   // Entradas
   input clk;
   input load_w0, load_w1;           // carregar novos valores em w0, w1
   input clear_w0, clear_w1;         // limpar (zerar) pesos
   input load_epoch, clear_epoch;    // carregar/limpar contador de épocas
   input load_n, clear_n;            // carregar/limpar contador de padrões
   input lerp;                       // sinal de escrita para os pesos (learning rate)
   input clrw;                       // limpar todos os pesos (reset do treino)
   input s;                          // selecionar qual padrão usar
   input calcular;                   // sinal para calcular propagação direta
   
   // Saídas
   output reg epoch_menor;           // status: época < máximo
   output reg n_maior;               // status: padrão chegou ao final (N > 3)
   output reg y_pred;                // saída do perceptron
   output reg signed [7:0] w0, w1;   // pesos (8 bits com sinal)
   
   // ================== Registradores internos ==================
   
   reg [3:0] N;                      // contador de padrões (0-3, 4 padrões no máximo)
   reg [3:0] EP;                     // contador de épocas
   
   reg signed [15:0] soma;           // resultado da soma ponderada (x0*w0 + x1*w1)
   reg signed [1:0] erro;            // erro = y_target - y_pred
   
   // Dados de treino para função OR (4 amostras)
   reg [1:0] x [3:0];                // entradas: {x1, x0}
   reg [0:0] y_target [3:0];         // saídas esperadas
   
   // Variáveis temporárias para cálculo
   reg [1:0] entrada_atual;
   reg saida_esperada;
   
   // ================== Parâmetros ==================
   
   parameter signed [31:0] LIMIAR = 32'd1;
   parameter MAX_EPOCH = 4'd15;       // máximo de épocas
   
   // ================== Inicialização de dados de treino ==================
   
   initial begin
      // Função OR: 00→0, 01→1, 10→1, 11→1
      x[0] = 2'b00; y_target[0] = 1'b0;
      x[1] = 2'b01; y_target[1] = 1'b1;
      x[2] = 2'b10; y_target[2] = 1'b1;
      x[3] = 2'b11; y_target[3] = 1'b1;
      
      // Inicializar pesos
      w0 = 8'h00;
      w1 = 8'h00;
      
      // Inicializar contadores
      N = 4'd0;
      EP = 4'd0;
   end
   
   // ================== Lógica combinacional (status) ==================
   
   always @(*) begin
      // Verificar se época ainda é menor que máximo
      epoch_menor = (EP < MAX_EPOCH) ? 1'b1 : 1'b0;
      
      // Verificar se padrão chegou além do máximo (estouro)
      n_maior = (N > 4'd3) ? 1'b1 : 1'b0;
      
      // Selecionar entrada atual baseado no padrão N
      entrada_atual = x[N];
      saida_esperada = y_target[N];
   end
   
   // ================== Lógica sequencial (atualização) ==================
   
   always @(posedge clk) begin
      
      // ===== Reset dos pesos (clrw) =====
      if (clrw) begin
         w0 <= 8'h00;
         w1 <= 8'h00;
      end
      
      // ===== Controle de limpar pesos individuais =====
      else if (clear_w0) begin
         w0 <= 8'h00;
      end
      else if (clear_w1) begin
         w1 <= 8'h00;
      end
      
      // ===== Controle de carregar novos valores de pesos =====
      // (será preenchido com dados de atualização no backpropagation)
      else if (load_w0) begin
         // Aqui virão os novos valores de w0 após aprendizado
         // w0 <= w0 + (erro * x0)  em algumas implementações
      end
      else if (load_w1) begin
         // Aqui virão os novos valores de w1 após aprendizado
         // w1 <= w1 + (erro * x1)  em algumas implementações
      end
      
      // ===== Controle de contador de épocas =====
      if (clear_epoch) begin
         EP <= 4'd0;
      end
      else if (load_epoch) begin
         EP <= EP + 4'd1;
      end
      
      // ===== Controle de contador de padrões =====
      if (clear_n) begin
         N <= 4'd0;
      end
      else if (load_n) begin
         N <= N + 4'd1;
      end
      
      // ===== Cálculo da propagação direta (forward pass) =====
      if (calcular) begin
         // Obter entrada atual
         entrada_atual <= x[N];
         saida_esperada <= y_target[N];
         
         // Calcular soma ponderada: soma = x[0]*w0 + x[1]*w1
         soma <= (entrada_atual[0] * $signed(w0)) + (entrada_atual[1] * $signed(w1));
         
         // Aplicar função de ativação (comparador com limiar)
         if (soma >= LIMIAR) begin
            y_pred <= 1'b1;
         end else begin
            y_pred <= 1'b0;
         end
         
         // Calcular erro: erro = y_target - y_pred
         erro <= saida_esperada - y_pred;
         
         // Atualizar pesos se houve erro (aprendizado Hebbiano simples)
         if (lerp && erro != 2'b00) begin
            // w0 = w0 + erro * x0
            w0 <= w0 + (entrada_atual[0] * $signed(erro));
            // w1 = w1 + erro * x1
            w1 <= w1 + (entrada_atual[1] * $signed(erro));
         end
      end
   end
   
endmodule
