`timescale 1ns/1ps

module fpga_top (
    input  wire clk,       // Clock da placa (ex.: 27 MHz)
    input  wire rst_n,     // Reset ativo baixo (botão)
    input  wire rx,        // Pino RX (não usado em loopback, mas mantido)
    output wire tx         // Pino TX (saída serial)
);

    // Instância do uart_top com loopback interno
    uart_top #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115200),
        .ENABLE_TX(1'b1),
        .ENABLE_RX(1'b1),
        .LOOPBACK(1'b1),          // loopback habilitado
        .FIFO_DATA_WIDTH(8),
        .FIFO_ADDR_WIDTH(4)       // FIFO de 16 posições
    ) uart_inst (
        .clk_i(clk),
        .rst_i(1'b1),            // reset ativo baixo
        .uart_rx_i(rx),           // entrada serial (ignorada internamente)
        .uart_tx_o(tx),           // saída serial
        .tx_data_i(8'h00),        // não usado porque não enviamos do hardware
        .tx_send_i(1'b0),
        .tx_ready_o(),            // não usado
        .tx_full_o(),
        .rx_data_o(),             // não usado – sem hardware para ler
        .rx_valid_o(),
        .rx_rd_en_i(1'b0),
        .rx_full_o()
    );

endmodule