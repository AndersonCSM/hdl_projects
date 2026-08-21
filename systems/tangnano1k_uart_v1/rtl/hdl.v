module top(
    input wire clk_i,
    input wire rst_i,
    input wire uart_rx_i,
    
    output wire uart_tx_o
);

    // UART
    uart #(.ECHO(1'b1),
    .CLK_FREQ(24_000_000)) inst_uart (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),

        // Fios do Hardware (Como não temos outro circuito desenhado 
        // ainda, nós deixamos o envio em 0 e as leituras "soltas")
        .chip_tx_data_i(8'd0),
        .chip_tx_send_i(1'b0),
        .chip_rx_data_o(),     // Deixa vazio para ignorar
        .chip_rx_done_o()      // Deixa vazio para ignorar
    );

endmodule