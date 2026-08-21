module top #(
    parameter BAUD_RATE = 115200,           // velocidade UART
    parameter CLK_FREQ = 27_000_000        // frequência do clock (27MHz para Tang Nano 20K)
)(
    input wire clk,                         // clock principal
    input wire rst,                         // reset global
    input wire rx_serial_in_from_tx,        // sinal serial RX
    output wire tx_serial_out_to_rx         // sinal serial TX
);

// ===== SINAIS INTERNOS =====
wire tick_rate;                         // clock de sincronização do UART
wire [7:0] rx_data_in;                  // dados recebidos do RX
wire rx_done;                           // pulso quando RX completa frame
wire tx_done;                           // pulso quando TX completa frame (não usado)

// ===== GERADOR DE BAUD RATE =====
baud_generate #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) baud_gen (
    .clk(clk),
    .rst(rst),
    .tick_rate(tick_rate)
);

// ===== MODO ECHO: RX → TX =====
// Transmissor recebe dados do RX quando RX completa a leitura
tx tx_instance (
    .clk(clk),
    .rst(rst),
    .en_tx(rx_done),              // transmite quando RX recebe
    .tick_rate(tick_rate),
    .data_in(rx_data_in),         // dados recebidos
    .data_out(tx_serial_out_to_rx),
    .done_tx(tx_done)
);

// Receptor sempre ativo para capturar dados
rx rx_instance (
    .clk(clk),
    .rst(rst),
    .en_rx(1'b1),                 // sempre ativo
    .tick_rate(tick_rate),
    .data_in(rx_serial_in_from_tx),
    .data_out(rx_data_in),
    .done_rx(rx_done)
);

endmodule
