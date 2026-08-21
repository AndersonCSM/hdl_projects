module top #(
    // 1. Parâmetro
    parameter BAUD_RATE = 115200,           // velocidade UART
    parameter CLK_FREQ = 27_000_000,        // frequência do clock

    parameter EN_RX = 1'b1,                 // RX sempre ativo
    parameter EN_TX = 1'b0,                 // TX inativo (ativa por rx_done)
    parameter TX_VALID_DEFAULT = 1'b0,      // tx_valid padrão
    parameter TX_DATA_DEFAULT = 8'h00      // tx_data_out padrão
)(
    input wire clk,                         // clock principal da placa (50MHz)
    input wire rst,                         // reset global
    input wire rx_serial_in_from_tx,        // sinal serial do outro dispositivo (para RX)
    output wire tx_serial_out_to_rx         // sinal serial para transmissão
);

// SINAIS DE CONTROLE (convertidos para wires internos)
wire en_tx = EN_TX;                     // Parâmetro EN_TX (padrão: desabilitado)
wire en_rx = EN_RX;                     // Parâmetro EN_RX (padrão: habilitado)
wire tx_valid = TX_VALID_DEFAULT;       // Parâmetro TX_VALID_DEFAULT (padrão: desabilitado)
wire [7:0] tx_data_out = TX_DATA_DEFAULT; // Parâmetro TX_DATA_DEFAULT

// SINAIS INTERNOS DO ECHO
wire [7:0] rx_data_in;                  // Dados recebidos (saída do RX)
wire tx_done;                           // TX concluído (não conectado externamente)
wire rx_done;                           // RX concluído (controla TX no echo)
wire rx_parity_error;                   // Erro de paridade (não conectado externamente)

// Sinais entre módulos (compatibilidade com arquitetura original)
wire [7:0] tx_buffer_data;              // dados do buffer TX para TX
wire tx_buffer_empty;                   // buffer TX vazio
wire tx_buffer_read;                    // comando de leitura do buffer TX

wire [7:0] rx_buffer_data;              // dados recebidos para buffer RX
wire rx_buffer_full;                    // buffer RX cheio
wire rx_buffer_write;                   // comando de escrita no buffer RX

// 2. Sinais Internos (Wires)
wire tick_rate;                         // sinal de sincronização gerado por baud_generate

// 3. Gerador de Baud Rate
baud_generate #(
    .BAUD_RATE(BAUD_RATE),     // passa o parâmetro do top
    .CLK_FREQ(CLK_FREQ)        // passa o parâmetro do top
) baud_gen (
    .clk(clk),
    .rst(rst),
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
    else if (tx_valid && en_tx && !tx_buffer_ocupado) begin
        tx_buffer <= tx_data_out;        // carrega dados quando tx_valid é pulso
        tx_buffer_ocupado <= 1'b1;      // marca buffer como ocupado
    end
    else if (tx_done && tx_buffer_ocupado) begin
        tx_buffer_ocupado <= 1'b0;      // libera buffer após transmissão completar
    end
end

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
    .done_rx(rx_done),
    .parity_error()               // não utilizado no echo
);

endmodule
