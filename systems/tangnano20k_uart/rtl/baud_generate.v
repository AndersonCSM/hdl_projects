module baud_generate #(
    parameter BAUD_RATE = 115200,     
    parameter CLK_FREQ = 27_000_000    
) (
    input wire clk_i,
    input wire rst_i,
    
    output wire baud_tick
);

    // Calcula o divisor para 16x Oversampling com ARREDONDAMENTO:
    // A soma de "(BAUD_RATE * 8)" equivale a somar 0.5 antes de dividir.
    // Assim, 14.64 vira 15.14, e ao truncar, o Verilog crava no 15 correto!
    
    localparam DIVISOR = (CLK_FREQ + (BAUD_RATE * 8)) / (BAUD_RATE * 16);
    
    reg [24:0] contador_baud;
    
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            contador_baud <= 25'b0;
        end
        else if (contador_baud >= DIVISOR - 1) begin
            contador_baud <= 25'b0;
        end
        else begin
            contador_baud <= contador_baud + 1'b1;
        end
    end
    
    // Gera um pulso (baud_tick) a cada DIVISOR clocks (16 pulsos formam 1 bit)
    assign baud_tick = (contador_baud == DIVISOR - 1) ? 1'b1 : 1'b0;

endmodule
