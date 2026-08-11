`default_nettype none

// ============================================================================
// UART Echo - Tang Nano 20K
// Descrição: TX/RX com retransmissão automática
// Baud Rate: 115200 bps
// Clock: 27 MHz
// Portas: clk, btn1 (reset), uart_rx, uart_tx
// ============================================================================



// ============================================================================
// Módulo: top
// Descrição: Top-level UART Echo
// Portas: clk (27MHz), btn1 (reset), uart_rx, uart_tx
// ============================================================================
module top (
    input wire clk,
    input wire btn1,
    input wire uart_rx,
    output wire uart_tx
);


// ===== SINAIS INTERNOS =====
wire rst = ~btn1;  // Reset ativo baixo
wire tick;        // Clock de baud rate

wire [7:0] rx_data;
wire rx_done;

wire [7:0] tx_data;
wire tx_send;
wire tx_done;

// Gerador de baud rate - OK
baud_rate_generator #(
    .CLK_FREQ(27_000_000),
    .BAUD_RATE(115200)
) baud_gen (
    .clk(clk),
    .rst(rst),
    .tick(tick)
);

// Receptor UART
uart_rx rx_inst (
    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .tick(tick),
    .data_out(rx_data),
    .done_rx(rx_done),
    .debug_state(),
    .debug_bit_count(),
    .debug_done_counter()
);

// Transmissor UART
uart_tx tx_inst (
    .clk(clk),
    .rst(rst),
    .data_in(tx_data),
    .send(tx_send),
    .tick(tick),
    .uart_tx(uart_tx),
    .done_tx(tx_done)
);

// ===== CONEXÃO RX -> TX =====
// rx_done fica em 1 por vários ciclos (suficiente para iniciar o TX)
// Como o TX demora muito mais para finalizar, não precisamos de latch.
assign tx_send = rx_done;
assign tx_data = rx_data;   // Passa dados diretamente

endmodule
