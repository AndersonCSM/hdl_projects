module rx (
    input wire clk_i, // entrada do clk_i
    input wire rst_i, // entrada do reset
    input wire enable_rx, // enable para recebimento
    input wire baud_tick, // tick rate
    input wire uart_rx_i, // entrada de dados que vem por um fio

    output reg [7:0] data_o, // saida de dados para um buffer de 1 byte
    output wire done_rx // saida para indicar que o recebimento foi concluido
);

// Parâmetros para FSM
parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

// Registradores
reg [1:0] atual, proximo;              // dois registradores de dois bits para cada registrador: atual e próximo
reg [3:0] bit_count;                    // contador de bits de dados (0-7)
reg [3:0] tick_counter;                 // contador de ticks (para sampling no meio do bit)

// Sincronização do sinal de entrada (debouncing)
reg rs232_t, rs232_t1, rs232_t2;
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        rs232_t <= 1'b1;
        rs232_t1 <= 1'b1;
        rs232_t2 <= 1'b1;
    end
    else begin
        rs232_t <= uart_rx_i;
        rs232_t1 <= rs232_t;
        rs232_t2 <= rs232_t1;
    end
end

// FSM
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i)
        atual <= IDLE;
    else
        atual <= proximo;
end

// Lógica combinacional - Decisão do próximo estado
// Transmissão começa com o fio serial em 0
always @(*) begin
    case(atual)
        IDLE:
            if(!rs232_t2 && enable_rx)
                proximo = START;
            else
                proximo = IDLE;
        START:
            if(tick_counter == 4'b1111)
                proximo = DATA;
            else
                proximo = START;
        DATA:
            if(bit_count == 4'b0111 && tick_counter == 4'b1111)
                proximo = STOP;
            else
                proximo = DATA;
        STOP:
            if(tick_counter == 4'b1111)
                proximo = IDLE;
            else
                proximo = STOP;
        default:
            proximo = IDLE;
    endcase
end

// Lógica de recepção - Executa a cada baud_tick
always @(posedge clk_i or negedge rst_i) begin
    if (!rst_i) begin
        tick_counter <= 4'b0000;
        bit_count <= 4'b0000;
    end
    else if (baud_tick) begin
            if (atual != IDLE) begin
                tick_counter <= tick_counter + 1;
                
                if (atual == START && tick_counter == 4'b1111) begin
                    tick_counter <= 4'b0000;
                    bit_count <= 4'b0000;
                end
                
                if (atual == DATA && tick_counter == 4'b1111) begin
                    bit_count <= bit_count + 1;
                    tick_counter <= 4'b0000;
                end
            end
            else begin
                tick_counter <= 4'b0000;
            end
        end
    end

// Dados recebidos pelo canal para o registrador
always @(posedge clk_i or negedge rst_i) begin
    if (! rst_i)                                     // se reset ativo então a saída é nível lógico 0
        data_o <= 1'd0;
    else if(atual == DATA) begin                    // se disponivel para leitura
        if(tick_counter == 4'b0111) begin           // Lê exatamente no MEIO do pulso (tick 7 ou 8)
            case(bit_count)                         // atribui os bits a data_o
                4'd0: data_o [0] <= rs232_t2;
                4'd1: data_o[1] <= rs232_t2;
                4'd2: data_o[2] <= rs232_t2;
                4'd3: data_o[3] <= rs232_t2;
                4'd4: data_o[4] <= rs232_t2;
                4'd5: data_o[5] <= rs232_t2;
                4'd6: data_o[6] <= rs232_t2;
                4'd7: data_o[7] <= rs232_t2;
                default:data_o <= data_o;
            endcase
            end
        end
    else
        data_o <= data_o;
end

// Sinal de conclusão
assign done_rx = (atual == STOP && tick_counter == 4'b1111);

endmodule
