module top( clk, btn1, btn2, led );
   
   input clk;
   input btn1, btn2;
   output [5:0] led;

   // Frequência do clk: 27MHz, dividor para reduzir para ~1Hz (teste)
   reg [23:0] contador = 24'hFFFFFF;
   reg clk_n;

   always @(posedge clk) begin
      if ( !btn1 ) 
         contador <= 24'd0;
      else if ( contador == 24'd13500000 ) begin
         contador <= 24'd0;
      end
      else 
         contador <= contador + 1;
      
      clk_n = ( contador == 24'd0 );
   end

   // =====================================================
   // Sinais de controle (FSM -> Datapath)
   // =====================================================
   wire load_w0, load_w1, clear_w0, clear_w1;
   wire load_epoch, clear_epoch;
   wire load_n, clear_n;
   wire lerp, clrw, s, calcular;

   // =====================================================
   // Sinais de status (Datapath -> FSM)
   // =====================================================
   
   wire epoch_menor, n_maior;
   wire [7:0] w0, w1;
   wire y_pred;

   // =====================================================
   // Conversão de reset (ativo baixo para ativo alto)
   // =====================================================
   
   wire rst = ~btn1;

   // =====================================================
   // Instância do módulo de controle (FSM)
   // =====================================================
   
   control ctrl (
       .clk(clk_n),
       .rst(rst),
       .btn2(btn2),
       .load_w0(load_w0),
       .load_w1(load_w1),
       .clear_w0(clear_w0),
       .clear_w1(clear_w1),
       .load_epoch(load_epoch),
       .clear_epoch(clear_epoch),
       .load_n(load_n),
       .clear_n(clear_n),
       .lerp(lerp),
       .clrw(clrw),
       .s(s),
       .calcular(calcular),
       .epoch_menor(epoch_menor),
       .n_maior(n_maior)
   );

   // =====================================================
   // Instância do módulo datapath (Perceptron)
   // =====================================================
   
   datapath dp (
       .clk(clk_n),
       .load_w0(load_w0),
       .load_w1(load_w1),
       .clear_w0(clear_w0),
       .clear_w1(clear_w1),
       .load_epoch(load_epoch),
       .clear_epoch(clear_epoch),
       .load_n(load_n),
       .clear_n(clear_n),
       .lerp(lerp),
       .clrw(clrw),
       .s(s),
       .calcular(calcular),
       .epoch_menor(epoch_menor),
       .n_maior(n_maior),
       .y_pred(y_pred),
       .w0(w0),
       .w1(w1)
   );

   // =====================================================
   // Saída nos LEDs
   // =====================================================
   
   // 3 leds - 3 bits menos significativos de w0
   // 3 leds - 3 bits menos significativos de w1
   assign led = {w0[2:0], w1[2:0]};
   
endmodule
