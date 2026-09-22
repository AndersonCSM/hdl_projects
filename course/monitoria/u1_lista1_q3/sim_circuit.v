// Write your modules here!
module sim_circuit(
  input u, d, clk,
  
  output reg [15:0] c
);
  
  // registradores e variáveis
  reg [1:0] atual, proximo;
  parameter IDLE = 2'b00, WAIT = 2'b01, SUM = 2'b10, SUB = 2'b11;

  // lógica de simulador
  initial begin
    c = 16'd0;
    atual = IDLE;
  end
  
  // FSM
  always @(posedge clk) begin
    begin
      atual <= proximo;
    end
  end
  
  // Controle
  always @(*) begin
    case (atual)
       IDLE: begin
          proximo = WAIT;
       end
       WAIT: begin
          if (~u & ~d)
            proximo = WAIT;
          else if (u == 1'b1)
            proximo = SUM;
          else if (d == 1'b1)
            proximo = SUB;
          else
            proximo = WAIT;
       end
       SUM: begin
          proximo = WAIT;
       end
       SUB: begin
          proximo = WAIT;
      end
      default: proximo = IDLE;
    endcase
  end
  
  // Datapath
  always @(posedge clk) begin
    case (atual)
      IDLE: begin
        c <= 16'd0;
      end
      SUM: begin
        if (c < 16'hFFFF)
          c <= c + 1'b1;
      end
      SUB: begin
        if (c > 16'd0)
          c <= c - 1'b1;
      end
    endcase
  end

endmodule
