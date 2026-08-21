module tx (
    input wire clk, // clk do dispositivo
    input wire rst, // reset do circuito
    input wire en_tx, // transmissao habilitada
    input wire tick_rate, // tick_rate da transmissão

    input wire [7:0] data_in, // entrada dos dados a serem transmitidos

    output reg data_out, // saida dos dados transmitidos interface rs232
    output wire done_tx // concluiu transmissao
);


// 1. definir parametros
// variaveis da FSM
parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;  // Quatro estados para a transmissão
reg [1:0] estado, proximo;            // registrador para estado (2 bits)

reg [3:0] bit_counter;                // até 8 bits de dados
reg [3:0] tick_counter;               // contador de ticks para sincronização
reg [7:0] tx_data;                    // registra os dados de entrada

// 2. Definindo a FSM - cada bloco possui uma FSM própria, logo aqui é a FSM TX
always @ (posedge clk or negedge rst)			//Boa prática considera o reset
    begin
        if (!rst)	
            estado <= IDLE;				// Se botão de reset ativo, vai para idle
        else 		
            estado <= proximo;			// Senão, vai para o próximo estado
    end

// 3. Lógica combinatorial - Decisão do próximo estado
always @ (estado or en_tx or bit_counter or tick_counter) begin
    case(estado)
        IDLE:
            if(en_tx)
                proximo = START;        // Habilita transmissão
            else
                proximo = IDLE;
        START:
            if(tick_counter == 4'b1111)
                proximo = DATA;         // Após start bit, vai para dados
            else
                proximo = START;
        DATA:
            if(bit_counter == 4'b1000 && tick_counter == 4'b1111)  // 8 bits transmitidos
                proximo = STOP;         // Vai para paridade + stop
            else
                proximo = DATA;
        STOP:
            if(tick_counter == 4'b1111)
                proximo = IDLE;         // Transmissão completa
            else
                proximo = STOP;
        default:
            proximo = IDLE;
    endcase
end

// 4. Registra dados de entrada quando habilita transmissão
always @ (posedge clk or negedge rst) begin
    if (!rst) begin
        tx_data <= 8'b00000000;
    end
    else if(estado == IDLE && en_tx) begin
        tx_data <= data_in;
    end
end

// 5. Lógica de sincronização com tick_rate
always @ (posedge tick_rate) begin
    if (estado != IDLE) begin
        tick_counter <= tick_counter + 1;
        
        if (estado == START && tick_counter == 4'b1111) begin
            tick_counter <= 4'b0000;
            bit_counter <= 4'b0000;
        end
        
        if (estado == DATA && tick_counter == 4'b1111) begin
            bit_counter <= bit_counter + 1;
            tick_counter <= 4'b0000;
        end
    end
    else begin
        tick_counter <= 4'b0000;
        bit_counter <= 4'b0000;
    end
end

// 6. Transmissão dos dados: START → 8 bits DATA → STOP (sem parity)
// Interface RS232 para transmissão em linha única
always@ (posedge clk or negedge rst) begin
    if (! rst)                          // se reset, fio fica em 1 (idle)
        data_out <= 1'b1;
    else if(estado == START && tick_counter == 4'b1111) begin
        data_out <= 1'b0;               // start bit
    end
    else if(estado == DATA && tick_counter == 4'b1111) begin
        case(bit_counter)               // envia os 8 bits de dados
            4'd0: data_out <= tx_data[0];
            4'd1: data_out <= tx_data[1];
            4'd2: data_out <= tx_data[2];
            4'd3: data_out <= tx_data[3];
            4'd4: data_out <= tx_data[4];
            4'd5: data_out <= tx_data[5];
            4'd6: data_out <= tx_data[6];
            4'd7: data_out <= tx_data[7];
            default: data_out <= 1'b1;
        endcase
    end
    else if(estado == STOP && tick_counter == 4'b1111) begin
        data_out <= 1'b1;               // stop bit (sem parity)
    end
    else if(estado == IDLE) begin
        data_out <= 1'b1;               // em idle o fio fica transmitindo em 1
    end
end

// 7. Removido: Cálculo de paridade (compatibilidade com Lushay)
// Frame format: START(0) + 8 DATA bits + STOP(1) = 10 bits total

// 8. Sinal de conclusão de transmissão
assign done_tx = (estado == IDLE && proximo == IDLE && bit_counter == 4'b0000);

endmodule
