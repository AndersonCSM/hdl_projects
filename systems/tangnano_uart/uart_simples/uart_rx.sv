// ============================================================================
// Módulo: uart_rx
// Descrição: Receptor UART serial
// ============================================================================
module uart_rx (
    input wire clk,
    input wire rst,
    input wire uart_rx,
    input wire tick,
    output reg [7:0] data_out,
    output reg done_rx,
    // Debug signals
    output wire [1:0] debug_state,
    output wire [3:0] debug_bit_count,
    output wire [3:0] debug_done_counter
);

localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam STOP = 2'b11;

reg [1:0] state = IDLE;
reg [7:0] shift_reg = 0;
reg [3:0] bit_count = 0;
reg [3:0] done_counter = 0;  // Contador para manter done_rx alto por vários ciclos

// Sincronização do sinal RX
reg rx_sync0, rx_sync1, rx_sync2;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rx_sync0 <= 1'b1;
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
    end else begin
        rx_sync0 <= uart_rx;
        rx_sync1 <= rx_sync0;
        rx_sync2 <= rx_sync1;
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= IDLE;
        shift_reg <= 0;
        bit_count <= 0;
        data_out <= 0;
        done_rx <= 0;
        done_counter <= 0;
    end else begin
        // Manter done_rx alto por vários ciclos após recepção completa
        if (done_counter > 0) begin
            done_rx <= 1;
            done_counter <= done_counter - 1;
        end else begin
            done_rx <= 0;
        end
        
        case (state)
            IDLE: begin
                if (!rx_sync2) begin
                    state <= START;
                end
            end
            
            START: begin
                if (tick) begin
                    state <= DATA;
                    bit_count <= 0;
                end
            end
            
            DATA: begin
                if (tick) begin
                    shift_reg[bit_count] <= rx_sync2;
                    if (bit_count == 4'd7) begin
                        state <= STOP;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end
            end
            
            STOP: begin
                if (tick) begin
                    state <= IDLE;
                    data_out <= shift_reg;
                    done_counter <= 8;  // Manter done_rx alto por 8 ciclos
                end
            end
        endcase
    end
end

// Debug: export internal state
assign debug_state = state;
assign debug_bit_count = bit_count;
assign debug_done_counter = done_counter;

endmodule
