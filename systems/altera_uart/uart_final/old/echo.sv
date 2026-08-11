/*
 * MÓDULO ECHO - Loopback Externo + Entrada Manual
 * 
 * Prioridade:
 * 1. Echo: quando RX recebe (rx_done) → TX transmite de volta
 * 2. Entrada Manual: quando tx_valid ativo → TX transmite dados
 */

module echo (
    input logic clk,                    // clock
    input logic rst,                    // reset
    
    // Interface com RX (Echo)
    input logic [7:0] rx_data_in,       // dados recebidos do RX
    input logic rx_done,                // sinal de conclusão do RX
    
    // Interface com Entrada Manual
    input logic [7:0] tx_data_out,      // dados entrada manual
    input logic tx_valid,               // pulso para enviar manual
    input logic en_tx,                  // TX habilitado
    
    // Interface com TX Buffer
    output reg [7:0] tx_buffer,         // dados para transmitir
    output reg tx_buffer_ocupado,       // flag: buffer tem dados
    input logic tx_done                 // sinal de conclusão do TX
);

    always @ (posedge clk or negedge rst) begin
        if (!rst) begin
            tx_buffer <= 8'b0;
            tx_buffer_ocupado <= 1'b0;
        end
        else if (rx_done && !tx_buffer_ocupado) begin
            // ECHO: RX finaliza → TX transmite de volta
            tx_buffer <= rx_data_in;
            tx_buffer_ocupado <= 1'b1;
        end
        else if (tx_valid && en_tx && !tx_buffer_ocupado) begin
            // ENTRADA MANUAL: tx_valid ativo → TX transmite
            tx_buffer <= tx_data_out;
            tx_buffer_ocupado <= 1'b1;
        end
        else if (tx_done && tx_buffer_ocupado) begin
            // TX finaliza → libera buffer
            tx_buffer_ocupado <= 1'b0;
        end
    end

endmodule