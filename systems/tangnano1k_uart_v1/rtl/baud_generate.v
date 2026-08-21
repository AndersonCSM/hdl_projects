module baud_generate #(
    parameter BAUD_RATE = 115200,     
    parameter CLK_FREQ = 27_000_000    
) (
    input wire clk_i,
    input wire rst_i,
    
    output wire baud_tick
);

    // Calcula o divisor para 16x Oversampling:
    // Fórmula: baud_tick = CLK_FREQ / (BAUD_RATE * 16)
    // Ex: Para 27MHz e 115200 baud, 27M / 1.84M ≈ 14.6 (arredonda para 15 ciclos)
    // Isso gera 16 pulsos (amostras) super rápidos para cada 1 bit recebido,
    // permitindo que o RX leia o dado exatamente no meio do bit (tick 7).
    
    localparam DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    
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
