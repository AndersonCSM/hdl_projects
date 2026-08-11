module top (
    input logic clk,                    // clock principal da placa (50MHz)
    input logic rst,                    // reset global
    input logic en_tx,                  // habilita transmissão
    input logic en_rx,                  // habilita recepção
    input logic tx_valid,               // pulso para indicar novo dado a transmitir
    
    input logic [7:0] tx_data_out,       // dados para transmitir
    output logic [7:0] rx_data_in,     // dados recebidos
    
    input logic rx_serial_in_from_tx,           // sinal serial do outro dispositivo (para RX)
    output logic tx_serial_out_to_rx,         // sinal serial para transmissão
    
    output logic tx_done,               // transmissão concluída
    output logic rx_done,               // recepção concluída
    output logic rx_parity_error        // erro de paridade no RX
);

// 1. Parâmetros
parameter BAUD_RATE = 115200;           // velocidade UART
parameter CLK_FREQ = 50_000_000;        // frequência do clock (50MHz)


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

// Controlado pelo echo_instance
/*
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
*/

// 5. Transmissor (TX)
tx tx_instance (
    .clk(clk),
    .rst(rst),
    .en_tx(en_tx && !tx_buffer_empty),  // habilita quando há dados
    .tick_rate(tick_rate),
    .data_in(tx_buffer_data),           // dados do buffer
    .data_out(tx_serial_out_to_rx),           // saída serial
    .done_tx(tx_done)
);

// 6. Receptor (RX)
rx rx_instance (
    .clk(clk),
    .rst(rst),
    .en_rx(en_rx),
    .tick_rate(tick_rate),
    .data_in(rx_serial_in_from_tx),             // entrada do fio serial
    .data_out(rx_data_in),             // dados recebidos
    .done_rx(rx_done),
    .parity_error(rx_parity_error)
);


// 7. Echo - Gerencia loopback externo + entrada manual
//
// 1. Se rx_done ativo → Echo (RX→TX)
// 2. Se tx_valid ativo → Entrada manual
// 3. Libera quando tx_done
echo echo_instance (
    .clk(clk),
    .rst(rst),
    .rx_data_in(rx_data_in),            // dados do RX (echo)
    .rx_done(rx_done),                  // conclusão do RX (echo)
    .tx_data_out(tx_data_out),          // entrada manual
    .tx_valid(tx_valid),                // pulso manual
    .en_tx(en_tx),                      // TX habilitado
    .tx_buffer(tx_buffer),              // saída: para TX
    .tx_buffer_ocupado(tx_buffer_ocupado),
    .tx_done(tx_done)                   // conclusão do TX
);

endmodule