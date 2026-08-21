module baud_generate #(
    parameter BAUD_RATE = 115200,      // ← recebe da instância
    parameter CLK_FREQ = 27_000_000    // ← recebe da instância
) (
    input wire clk,
    input wire rst,
    output wire tick_rate
);

    // Calcula o divisor compatível com Lushay: tick_rate = CLK_FREQ / BAUD_RATE
    // Para 27MHz e 115200 baud: 27_000_000 / 115200 = 234.375 ≈ 234
    // Usa 1 amostra por bit (não 16x oversampling)
    
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;
    
    reg [24:0] contador_baud;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            contador_baud <= 25'b0;
        end
        else if (contador_baud >= DIVISOR - 1) begin
            contador_baud <= 25'b0;
        end
        else begin
            contador_baud <= contador_baud + 1'b1;
        end
    end
    
    // tick_rate gera um pulso a cada DIVISOR clocks (1 amostra por bit)
    assign tick_rate = (contador_baud == DIVISOR - 1) ? 1'b1 : 1'b0;

endmodule
