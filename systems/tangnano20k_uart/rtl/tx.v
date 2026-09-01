module tx (
    input wire clk_i, // clk_i do dispositivo
    input wire rst_i, // reset do circuito
    input wire enable_tx, // transmissao habilitada
    input wire baud_tick, // baud_tick da transmissão
    input wire [7:0] data_i, // entrada dos dados a serem transmitidos

    output reg uart_tx_o, // saida dos dados transmitidos interface rs232
    output wire tx_valid // concluiu transmissao
);

// variaveis da FSM
parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;  // Quatro atuals para a transmissão

// Registradores
reg [1:0] atual, proximo;             // registrador para estado (2 bits)
reg [3:0] bit_count;                // até 8 bits de dados
reg [3:0] tick_count;               // contador de ticks para sincronização
reg [7:0] tx_data;                    // registra os dados de entrada

// FSM - cada bloco (TX,RX) possui uma FSM própria
always @ (posedge clk_i or negedge rst_i)			//Boa prática considera o reset
    begin
        if (!rst_i)	
            atual <= IDLE;				// Se botão de reset ativo, vai para idle
        else if (baud_tick || atual == IDLE)		
            atual <= proximo;			// Senão, vai para o próximo atual
    end

// Lógica combinacional - Decisão do próximo atual
always @(*) begin
    case(atual)
        IDLE:
            if(enable_tx)
                proximo = START;        // Habilita transmissão
            else
                proximo = IDLE;
        START:
            if(tick_count == 4'b1111)
                proximo = DATA;         // Após start bit, vai para dados
            else
                proximo = START;
        DATA:
            if(bit_count == 4'b0111 && tick_count == 4'b1111)  // 8 bits transmitidos
                proximo = STOP;         // Vai para paridade + stop
            else
                proximo = DATA;
        STOP:
            if(tick_count == 4'b1111)
                proximo = IDLE;         // Transmissão completa
            else
                proximo = STOP;
        default:
            proximo = IDLE;
    endcase
end

// Registra dados de entrada quando habilitado para transmissão
always @ (posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        tx_data <= 8'b00000000;
    end
    else if(atual == IDLE && enable_tx) begin
        tx_data <= data_i;
    end
end

// Lógica de sincronização com baud_tick
// Lógica de sincronização (Sincronizado com clk_i)
always @ (posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        tick_count <= 4'b0000;
        bit_count <= 4'b0000;
    end
    else if (baud_tick) begin
        if (atual != IDLE) begin
            tick_count <= tick_count + 1;
            
            if (atual == START && tick_count == 4'b1111) begin
                tick_count <= 4'b0000;
                bit_count <= 4'b0000;
            end
            
            if (atual == DATA && tick_count == 4'b1111) begin
                bit_count <= bit_count + 1;
                tick_count <= 4'b0000;
            end
        end
        else begin
            tick_count <= 4'b0000;
            bit_count <= 4'b0000;
        end
    end
end

// Transmissão dos dados: START → 8 bits DATA → STOP (sem parity)
// Interface RS232 para transmissão em linha única
always@ (posedge clk_i or negedge rst_i) begin
    if (!rst_i)
        uart_tx_o <= 1'b1;               // se reset, fio fica em 1 (idle)
    else if(atual == START) begin
        uart_tx_o <= 1'b0;               // start bit sai imediatamente!
    end
    else if(atual == DATA) begin
        case(bit_count)               // envia os 8 bits
            4'd0: uart_tx_o <= tx_data[0];
            4'd1: uart_tx_o <= tx_data[1];
            4'd2: uart_tx_o <= tx_data[2];
            4'd3: uart_tx_o <= tx_data[3];
            4'd4: uart_tx_o <= tx_data[4];
            4'd5: uart_tx_o <= tx_data[5];
            4'd6: uart_tx_o <= tx_data[6];
            4'd7: uart_tx_o <= tx_data[7];
            default: uart_tx_o <= 1'b1;
        endcase
    end
    else if (atual == STOP) begin
        uart_tx_o <= 1'b1;               // stop bit
    end
    else if (atual == IDLE) begin
        uart_tx_o <= 1'b1;               // stop bit e idle ficam em 1
    end
end

// Sinal de conclusão de transmissão
assign tx_valid = (atual == IDLE);

endmodule
