module uart #(
    parameter BAUD_RATE = 115200,           // velocidade UART
    parameter CLK_FREQ = 27_000_000,      // frequência do clock (27MHz para Tang Nano 20K)
    parameter ENABLE_RX = 1'b1,
    parameter ENABLE_TX = 1'b1
)(
    // Fios de entrada fundamentais
    input wire clk_i,                         // clock principal
    input wire rst_i,                         // reset global

    // Sinais para comunicação entre a UART e o computador
    input wire uart_rx_i,         // sinal serial RX
    output wire uart_tx_o,         // sinal serial TX

    // Sinais para dentro do CHIP
    input wire [7:0] tx_data_i,    // o byte que o hardware enviará para o PC
    input wire tx_send_i,          // O gatilho do hardware para enviar
    output wire tx_ready_o,

    output wire [7:0] rx_data_o,   // Entrega o byte que chegou do PC para o hardware
    output wire rx_valid_o          // Pulso avisando o hardware que chegou
);

// SINAIS INTERNOS
wire baud_tick;    

// GERADOR DE BAUD RATE
baud_generate #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) baud_gen (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .baud_tick(baud_tick)
);

// Transmissor, recebe os dados do CHIP e transmite
generate
    if (ENABLE_TX == 1'b1) begin: gen_tx // todo bloco begin ... end dentro de um generate é obrigado a ter um nome (alias), sendo gen_tx
        tx tx_instance (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .enable_tx(tx_send_i),     // Ligado direto na porta de entrada

            .baud_tick(baud_tick),
            .data_i(tx_data_i),        // Ligado direto na porta de entrada

            .uart_tx_o(uart_tx_o),
            .tx_valid(tx_ready_o)        // Nossa porta vital (Não esqueça de declarar ela lá em cima!)
        );
    end
    else begin: gen_not_tx  // Se o TX estiver desativado, devemos manter a linha em '1' (estado de repouso da UART)
        assign uart_tx_o = 1'b1;
        assign tx_ready_o = 1'b0;
    end
endgenerate


// Receptor, recebe os dados e manda para o CHIP
generate
    if (ENABLE_RX == 1'b1) begin: gen_rx  // todo bloco begin ... end dentro de um generate é obrigado a ter um nome (alias), sendo gen_tx
        rx rx_instance (
            .clk_i(clk_i),
            .rst_i(rst_i),
            .enable_rx(1'b1),     // sempre ativo

            .baud_tick(baud_tick),
            .uart_rx_i(uart_rx_i),

            .data_o(rx_data_o),        // Ligado direto na porta de saída
            .rx_valid(rx_valid_o)        // Ligado direto na porta de saída
        );
    end
    else begin: gen_not_rx  // Se o RX estiver desativado, mantemos as saídas zeradas
        assign rx_data_o = 8'b0;
        assign rx_valid_o = 1'b0;
    end

endgenerate

endmodule
