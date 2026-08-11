// ============================================================================
// Módulo: baud_rate_generator
// ============================================================================
module baud_rate_generator #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire rst,
    output wire tick
);

localparam DIVISOR = CLK_FREQ / BAUD_RATE;
reg [24:0] counter = 0;


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 0;
    end else begin
        if (counter == DIVISOR - 1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
end

assign tick = (counter == DIVISOR - 1) ? 1'b1 : 1'b0;

endmodule
