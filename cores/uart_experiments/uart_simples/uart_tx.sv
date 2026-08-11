// ============================================================================
// Módulo: uart_tx
// Descrição: Transmissor UART serial
// ============================================================================
module uart_tx (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire send,
    input wire tick,
    output reg uart_tx,
    output reg done_tx
);

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;

reg [1:0] state = IDLE;
reg [7:0] shift_reg = 0;
reg [3:0] bit_count = 0;
reg [3:0] done_counter = 0;  // Contador para manter done_tx alto por vários ciclos

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= IDLE;
        uart_tx <= 1'b1;
        shift_reg <= 0;
        bit_count <= 0;
        done_tx <= 0;
        done_counter <= 0;
    end else begin
        // Manter done_tx alto por vários ciclos após transmissão completa
        if (done_counter > 0) begin
            done_tx <= 1;
            done_counter <= done_counter - 1;
        end else begin
            done_tx <= 0;
        end
        
        case (state)
            IDLE: begin
                uart_tx <= 1'b1;
                if (send) begin
                    state <= START;
                    shift_reg <= data_in;
                end
            end
            
            START: begin
                uart_tx <= 1'b0;
                if (tick) begin
                    state <= DATA;
                    bit_count <= 0;
                end
            end
            
            DATA: begin
                uart_tx <= shift_reg[bit_count];
                if (tick) begin
                    if (bit_count == 4'd7) begin
                        state <= STOP;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end
            
            STOP: begin
                uart_tx <= 1'b1;
                if (tick) begin
                    state <= IDLE;
                    done_counter <= 8;  // Manter done_tx alto por 8 ciclos
                end
            end
        endcase
    end
end

endmodule
