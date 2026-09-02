module fpga_top (
    input  wire clk,       // Clock da placa (27 MHz)
    input  wire rst_n,     // Reset ativo baixo (botão)
    input  wire rx,        // Pino RX (Recebe do PC)
    output wire tx         // Pino TX (Envia para o PC)
);

    // Fios de interconexão
    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_full;

    // Registradores da nossa Ponte (Echo)
    reg [7:0] tx_data;
    reg tx_send;
    reg rx_rd_en;
    
    reg [2:0] state;

    wire reset_ativo_baixo = ~rst_n;
    // wire reset_ativo_baixo = 1;

    localparam  S_IDLE  = 3'd0,
                S_FETCH = 3'd1,   // Aguarda a RAM da FIFO entregar o dado
                S_SEND  = 3'd2,   // Captura o dado válido e pulsa tx_send
                S_WAIT1 = 3'd3,   // Aguarda a FIFO atualizar a flag empty
                S_WAIT2 = 3'd4;

    // Instância do uart_top com pinos FÍSICOS ativos (LOOPBACK=0)
    top #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(9600),
        .ENABLE_TX(1'b1),
        .ENABLE_RX(1'b1),
        .LOOPBACK(1'b0),          // IMPORTANTE: Tem que ser 0 para usar o pino rx externo!
        .FIFO_DATA_WIDTH(8),
        .FIFO_ADDR_WIDTH(4)
    ) uart_inst (
        .clk_i(clk),
        .rst_i(reset_ativo_baixo),
        .uart_rx_i(rx),           
        .uart_tx_o(tx),           
        .tx_data_i(tx_data),      // Alimentado pela nossa FSM
        .tx_send_i(tx_send),      // Gatilho da nossa FSM
        .tx_ready_o(),            // Ignorado, a FIFO gerencia
        .tx_full_o(tx_full),
        .rx_data_o(rx_data),
        .rx_valid_o(rx_valid),
        .rx_rd_en_i(rx_rd_en),
        .rx_full_o()
    );

    // FSM DE ECHO: Lê do RX -> Grava no TX
    always @(posedge clk or negedge reset_ativo_baixo) begin
        if (!reset_ativo_baixo) begin
            state <= S_IDLE;
            rx_rd_en <= 1'b0;
            tx_send <= 1'b0;
            tx_data <= 8'h00;
        end else begin
            // defaults
            rx_rd_en <= 1'b0;
            tx_send <= 1'b0;

            case (state)
                S_IDLE: begin
                    // Se a FIFO RX tem dado (rx_valid) e a TX tem espaço
                    if (rx_valid && !tx_full) begin
                        rx_rd_en <= 1'b1;   // Pede o dado para a FIFO
                        state <= S_FETCH;
                    end
                end

                S_FETCH: begin
                    // Neste ciclo, a FIFO está lendo a memória RAM.
                    // O dado só estará pronto e estável no PRÓXIMO ciclo.
                    state <= S_SEND;
                end

                S_SEND: begin
                    // AGORA SIM! O dado real saiu da FIFO. Podemos capturar!
                    tx_data <= rx_data;
                    tx_send <= 1'b1;        // Manda o TX transmitir
                    state <= S_WAIT1;
                end

                S_WAIT1: begin
                    // Dá tempo para a FIFO RX processar a leitura 
                    // e abaixar o pino rx_valid (empty)
                    state <= S_WAIT2;
                end

                S_WAIT2: begin
                    // Segurança extra antes de voltar a olhar o rx_valid
                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
