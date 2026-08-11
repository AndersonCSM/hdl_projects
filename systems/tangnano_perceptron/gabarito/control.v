// Controle (FSM - Máquina de Estados)
module control ( clk, rst, 
                 load_w0, load_w1, clear_w0, clear_w1, 
                 load_epoch, clear_epoch, load_n, clear_n,
                 lerp, clrw, s, calcular,
                 epoch_menor, n_maior, btn2);
                 
   // ================== Declaração de portas ==================
   
   input clk, rst;              // clock e reset
   input btn2;                  // botão para iniciar treino
   input epoch_menor;           // status: pode continuar épocas
   input n_maior;               // status: padrão chegou ao final
   
   // Sinais de controle para datapath
   output reg load_w0, load_w1;
   output reg clear_w0, clear_w1;
   output reg load_epoch, clear_epoch;
   output reg load_n, clear_n;
   output reg lerp;             // ativa aprendizado
   output reg clrw;             // limpar pesos
   output reg s;                // seletor
   output reg calcular;         // habilita cálculo
   
   // ================== Registradores da máquina de estados ==================
   
   reg [1:0] estado_atual, estado_proximo;
   
   // Estados da máquina
   parameter Start = 2'b00,
             Wait = 2'b01,
             Forward = 2'b10,
             Backpropagation = 2'b11;
   
   // ================== Controle de estado (FF com reset) ==================
   
   always @(posedge clk, posedge rst) begin
      if (rst == 1) 
         estado_atual <= Start;
      else 
         estado_atual <= estado_proximo;
   end
   
   // ================== Descrição combinacional da FSM ==================
   
   always @(*) begin
      
      // Inicializações — para evitar latches
      estado_proximo = estado_atual;
      
      // Limpar todos os sinais de controle
      load_w0 = 1'b0;
      load_w1 = 1'b0;
      clear_w0 = 1'b0;
      clear_w1 = 1'b0;
      load_epoch = 1'b0;
      clear_epoch = 1'b0;
      load_n = 1'b0;
      clear_n = 1'b0;
      lerp = 1'b0;
      clrw = 1'b0;
      s = 1'b0;
      calcular = 1'b0;
      
      case (estado_atual)
      
         // ===== ESTADO: Start (Inicialização) =====
         Start : begin
            // Ativações: zerar tudo para começar o treino
            clrw = 1'b1;           // limpar pesos
            clear_epoch = 1'b1;    // limpar contador de épocas
            clear_n = 1'b1;        // limpar contador de padrões
            
            // Próximo estado: esperar botão
            estado_proximo = Wait;
         end
         
         // ===== ESTADO: Wait (Espera) =====
         Wait : begin
            // Ativações: nenhuma
            // Espera btn2 ou btn1 (reset)
            
            if (btn2 == 1'b0) begin  // botão pressionado (ativo baixo)
               // Começar treino
               estado_proximo = Forward;
            end else begin
               estado_proximo = Wait;
            end
         end
         
         // ===== ESTADO: Forward (Propagação Direta) =====
         Forward : begin
            // Ativações: calcular saída
            calcular = 1'b1;        // habilitar cálculo na datapath
            lerp = 1'b1;            // ativar aprendizado
            
            // Próximo estado: atualizar pesos
            estado_proximo = Backpropagation;
         end
         
         // ===== ESTADO: Backpropagation (Retropropagação/Atualização) =====
         Backpropagation : begin
            // Ativações: passar para próximo padrão
            load_n = 1'b1;          // incrementar contador de padrões
            
            // Verificar se terminou os 4 padrões
            if (n_maior == 1'b1) begin
               // Terminou todos os padrões, vamos para próxima época
               clear_n = 1'b1;      // zerar contador de padrões
               load_epoch = 1'b1;   // incrementar contador de épocas
               
               // Verificar se terminou todas as épocas
               if (epoch_menor == 1'b0) begin
                  // Treino completo
                  estado_proximo = Wait;
               end else begin
                  // Continuar com próxima época
                  estado_proximo = Forward;
               end
            end else begin
               // Continuar com próximo padrão
               estado_proximo = Forward;
            end
         end
         
         default : begin
            estado_proximo = Start;
         end
         
      endcase
   end
   
endmodule
