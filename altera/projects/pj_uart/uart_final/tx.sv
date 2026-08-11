module tx (
    input logic clk, // clk do dispositivo
    input logic rst, // reset do circuito
    input logic en_tx, // transmissao habilitada
    input logic tick_rate, // tick_rate da transmissão

    input logic [7:0] data_in, // entrada dos dados a serem transmitidos

    output logic data_out, // saida dos dados transmitidos interface rs232
    output logic done_tx // concluiu transmissao
);


// 1. definir parametros
// variaveis da FSM
parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;  // Quatro estados para a transmissão
reg [1:0] estado, proximo;            // registrador para estado (2 bits)

reg [3:0] bit_counter;                // até 11 bits, usado para controlar qual é o bit de data que está sendo enviado no momento pelo wire
reg [3:0] tick_counter;               // contador de ticks para sincronização
reg [7:0] tx_data;                    // registra os dados de entrada

wire tx_parity;                        // bit de paridade

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

// 6. se tudo ok, tx_data encaminha os bits para data_out + bit_paridade
// interface rs232 para transmissão de dados em linha em um único fio
always@ (posedge clk or negedge rst) begin
    if (! rst)                          // se reset, fio fica em 1 (idle)
        data_out <= 1'b1;
    else if(estado == START && tick_counter == 4'b1111) begin
        data_out <= 1'b0;               // start bit
    end
    else if(estado == DATA && tick_counter == 4'b1111) begin
        case(bit_counter)               // atribui os bits de dados a data_out
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
    else if(estado == STOP && tick_counter == 4'b0111) begin
        data_out <= tx_parity;          // bit de paridade
    end
    else if(estado == STOP && tick_counter == 4'b1111) begin
        data_out <= 1'b1;               // stop bit
    end
    else if(estado == IDLE) begin
        data_out <= 1'b1;               // em idle o fio fica transmitindo em 1
    end
end

// 7. Cálculo do BIT PARIDADE PAR
// Se a contagem original de bits '1' na mensagem for ímpar, o bit de paridade é definido como 1 para tornar o total par;
// se a contagem original for par (ou nula), o bit de paridade é definido como 0.
// XOR : a saída é 1 se a quantidade for 1 -> O ^ 1 = 1  |  1 ^1 = 0 
// Se encadear operações XOR ele só retorna 1 se a quantidade de bits for impar
// O operador unário ^ realiza o XOR entre todos os bits do vetor
assign tx_parity = ^tx_data;  // XOR de todos os bits = 1 se número ímpar de 1s

// 8. Sinal de conclusão de transmissão
assign done_tx = (estado == IDLE && proximo == IDLE && bit_counter == 4'b0000);

endmodule