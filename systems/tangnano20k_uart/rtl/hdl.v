module top(
    input wire clk_i,
    input wire rst_i,
    input wire uart_rx_i,
    
    output wire uart_tx_o
);
    // Fios para o ECHO
    wire [7:0] data_loopback;
    wire send_loopback;

    // UART
    uart #(.CLK_FREQ(24_000_000)) 
    inst_uart (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),

        // Fios para comunicar com outras partes do Chip
        .tx_data_i(data_loopback),
        .tx_send_i(send_loopback),

        .rx_data_o(data_loopback),     // Deixa vazio para ignorar
        .rx_done_o(send_loopback),      // Deixa vazio para ignorar

        .tx_done_o()  // Deixamos vazio pois neste projeto simples não vamos usá-lo
    );

endmodule
