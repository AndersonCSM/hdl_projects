module uart #(
    parameter BAUD_RATE = 115200,           // velocidade UART
    parameter CLK_FREQ = 27_000_000,      // frequência do clock (27MHz para Tang Nano 20K)
    parameter ENABLE_RX = 1'b1,
    parameter ECHO = 1'b1      
)(
    // Fios de entrada fundamentais
    input wire clk_i,                         // clock principal
    input wire rst_i,                         // reset global

    // Sinais para comunicação entre a UART e o computador
    input wire uart_rx_i,         // sinal serial RX
    output wire uart_tx_o,         // sinal serial TX

    // Sinais para que outros hardwares possam utilizar o protocolo UART
    input wire [7:0] chip_tx_data_i,    // o byte que o hardware enviará para o PC
    input wire chip_tx_send_i,          // O gatilho do hardware para enviar
    output wire [7:0] chip_rx_data_o,   // Entrega o byte que chegou do PC para o hardware
    output wire chip_rx_done_o          // Pulso avisando o hardware que chegou
);

// SINAIS INTERNOS
wire baud_tick;                         // clock de sincronização do UART
wire [7:0] tx_data;                     // dados recebidos do TX                   
wire [7:0] rx_data;                     // dados recebidos do RX
wire rx_done;                           // pulso quando RX completa frame
wire tx_done;                           // pulso quando TX completa frame (não usado)
wire tx_send;                           // Controla o momento de envio

// GERADOR DE BAUD RATE
baud_generate #(
    .BAUD_RATE(BAUD_RATE),
    .CLK_FREQ(CLK_FREQ)
) baud_gen (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .baud_tick(baud_tick)
);


// Transmissor recebe dados do RX quando RX completa a leitura
tx tx_instance (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .enable_tx(tx_send),              // transmite quando RX recebe
    .baud_tick(baud_tick),
    .data_i(tx_data),         // dados recebidos
    .uart_tx_o(uart_tx_o),
    .done_tx(tx_done)
);

// Receptor sempre ativo para capturar dados
rx rx_instance (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .enable_rx(ENABLE_RX),                 // sempre ativo
    .baud_tick(baud_tick),
    .uart_rx_i(uart_rx_i),
    .data_o(rx_data),
    .done_rx(rx_done)
);

// MULTIPLEXADOR DE TRANSMISSÃO (TX)
// Se o modo ECHO estiver ativado (1): O TX retransmite exatamente o que o RX acabou de receber.
// Se o modo ECHO estiver desativado (0): O TX passa a obedecer os comandos vindos do TopLevel.
assign tx_send = (ECHO == 1'b1) ? rx_done : chip_tx_send_i;  // evita alta impedância
assign tx_data = (ECHO == 1'b1) ? rx_data : chip_tx_data_i;  // Passa dados diretamente

// SAÍDAS DE RECEPÇÃO (RX)
// O receptor (RX) escuta o computador o tempo todo de forma independente.
// Aqui nós apenas puxamos uma "extensão" dos dados para as portas de saída 
// para que o TopLevel possa ouvi-los também.
assign chip_rx_data_o = rx_data;
assign chip_rx_done_o = rx_done;

endmodule
