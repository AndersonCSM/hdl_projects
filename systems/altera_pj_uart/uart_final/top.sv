module top #(
    // 1. Parâmetro
    parameter BAUD_RATE = 115200,           // velocidade UART
    parameter CLK_FREQ = 27_000_000,        // frequência do clock

    parameter EN_RX = 1'b1,                 // RX sempre ativo
    parameter EN_TX = 1'b0,                 // TX inativo (ativa por rx_done)
    parameter TX_VALID_DEFAULT = 1'b0,      // tx_valid padrão
    parameter TX_DATA_DEFAULT = 8'h00      // tx_data_out padrão
)
(
    input logic clk,                    // clock principal da placa (50MHz)
    input logic rst,                    // reset global
    
    input logic rx_serial_in_from_tx,           // sinal serial do outro dispositivo (para RX)
    output logic tx_serial_out_to_rx,         // sinal serial para transmissão
    
    output logic [7:0] rx_data_in,     // dados recebidos (debug)
    output logic tx_done,               // transmissão concluída (debug)
    output logic rx_done,               // recepção concluída (debug)
    output logic rx_parity_error        // erro de paridade no RX (debug)
);




// 2. Sinais Internos (Wires)
wire tick_rate;                         // sinal de sincronização gerado por baud_generate

// Sinais entre módulos
wire [7:0] tx_buffer_data;              // dados do buffer TX para TX
wire tx_buffer_empty;                   // buffer TX vazio
wire tx_buffer_read;                    // comando de leitura do buffer TX

wire [7:0] rx_buffer_data;              // dados recebidos para buffer RX
wire rx_buffer_full;                    // buffer RX cheio
wire rx_buffer_write;                   // comando de escrita no buffer RX

// 3. Gerador de Baud Rate
baud_generate baud_gen (
    .clk(clk),
    .rst(rst),
    .baud_rate(BAUD_RATE),
    .tick_rate(tick_rate)
);

// 4. Buffer de Entrada (TX) - FIFO Simplificado com tx_valid
reg [7:0] tx_buffer;                    // registrador para armazenar dados
reg tx_buffer_ocupado = 1'b0;           // flag de buffer ocupado

assign tx_buffer_empty = ~tx_buffer_ocupado;
assign tx_buffer_data = tx_buffer;

always @ (posedge clk or negedge rst) begin
    if (!rst) begin
        tx_buffer <= 8'b0;
        tx_buffer_ocupado <= 1'b0;
    end
    else if (TX_VALID_DEFAULT && EN_TX && !tx_buffer_ocupado) begin
        tx_buffer <= TX_DATA_DEFAULT;        // carrega dados quando tx_valid é pulso
        tx_buffer_ocupado <= 1'b1;      // marca buffer como ocupado
    end
    else if (tx_done && tx_buffer_ocupado) begin
        tx_buffer_ocupado <= 1'b0;      // libera buffer após transmissão completar
    end
end

// 5. Transmissor (TX)
/*
Foi configurado para um ECHO, onde toda entrada de RX é enviada por TX
Para usar normalmente modifique
De:
    .en_tx(rx_done),              // ativa TX quando RX termina
    .data_in(rx_data_in),         // recebe direto do RX

Para:
    .en_tx(en_tx && !tx_buffer_empty),  // habilita quando há dados
    .data_in(tx_buffer_data),  
*/
tx tx_instance (
    .clk(clk),
    .rst(rst),
    .en_tx(rx_done),              // ativa TX quando RX termina
    .tick_rate(tick_rate),
    .data_in(rx_data_in),         // recebe direto do RX
    .data_out(tx_serial_out_to_rx),           // saída serial
    .done_tx(tx_done)
);

// 6. Receptor (RX)
rx rx_instance (
    .clk(clk),
    .rst(rst),
    .en_rx(EN_RX),
    .tick_rate(tick_rate),
    .data_in(rx_serial_in_from_tx),             // entrada do fio serial
    .data_out(rx_data_in),             // dados recebidos
    .done_rx(rx_done),
    .parity_error(rx_parity_error)
);

endmodule