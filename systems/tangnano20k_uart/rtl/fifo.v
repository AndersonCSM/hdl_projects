module fifo #(
    parameter DATA_WIDTH = 8,       // Largura do dado (ex: 8 bits para um byte)
    parameter ADDR_WIDTH = 4        // Profundidade logarítmica (2^4 = 16 posições na fila)
)(
    input wire clk_i,               
    input wire rst_i,               // Reset global (ativo em nível baixo)
    
    // Porta de Escrita (Entrada de dados na Fila)
    input wire wr_en_i,             // Sinal de habilitação de escrita (Push)
    input wire [DATA_WIDTH-1:0] data_in_i, // Dado que será inserido na fila
    output wire full_o,             // Nível alto ('1') se a fila estiver totalmente cheia
    
    // Porta de Leitura (Saída de dados da Fila)
    input wire rd_en_i,             // Sinal de habilitação de leitura (Pop)
    output reg [DATA_WIDTH-1:0] data_out_o, // Dado retirado da fila
    output wire empty_o,            // Nível alto ('1') se a fila estiver vazia
    
    // Monitoramento
    output wire [ADDR_WIDTH:0] count_o  // Número atual de elementos dentro da fila
);

    // Calcula a profundidade máxima real da FIFO baseada no ADDR_WIDTH (ex: 2^4 = 16)
    localparam DEPTH = 1 << ADDR_WIDTH;  // deslocar o número 1 para a esquerda em ADDR_WIDTH posições - deslocado 4 vezes = 16 em decimal

    // Memória Interna (Buffer Circular)
    // Cria um vetor de registradores que age como a nossa "matriz" de armazenamento
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Ponteiros e Contadores
    reg [ADDR_WIDTH-1:0] wr_ptr = 0;  // Ponteiro de escrita (aponta para onde o próximo dado será salvo) - endereços de escrita
    reg [ADDR_WIDTH-1:0] rd_ptr = 0;  // Ponteiro de leitura (aponta para onde o próximo dado será lido) - endereços de leitura
    reg [ADDR_WIDTH:0] count = 0;     // Contador de elementos presentes na fila - precisa contar até 16(0-15)

    // Sinais de Status (Flags)
    assign full_o  = (count == DEPTH);  // Fila cheia quando o contador atinge a capacidade máxima
    assign empty_o = (count == 0);      // Fila vazia quando o contador é zero
    assign count_o = count;             // Expõe a contagem atual para uso externo (se necessário)

    // Lógica de Escrita (Push)
    // Salva o dado na posição apontada por wr_ptr e incrementa o ponteiro circularmente
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            wr_ptr <= 0;
        end 
        else if (wr_en_i && !full_o) begin
            mem[wr_ptr] <= data_in_i;     // Escreve o dado na memória
            wr_ptr <= wr_ptr + 1'b1;      // Avança o ponteiro de escrita
        end
    end

    // Lógica de Leitura (Pop)
    // Retira o dado da posição apontada por rd_ptr e incrementa o ponteiro circularmente
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            rd_ptr <= 0;
            data_out_o <= {DATA_WIDTH{1'b0}};
        end 
        else if (rd_en_i && !empty_o) begin
            data_out_o <= mem[rd_ptr];    // Lê o dado da memória
            rd_ptr <= rd_ptr + 1'b1;      // Avança o ponteiro de leitura
        end
    end

    // Gerenciamento do Contador de Itens
    // Controla se a fila está ganhando, perdendo ou mantendo a quantidade de dados
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            count <= 0;
        end 
        else begin
            case ({wr_en_i && !full_o, rd_en_i && !empty_o})
                2'b10: count <= count + 1'b1; // Apenas escrevendo (Soma 1)
                2'b01: count <= count - 1'b1; // Apenas lendo (Subtrai 1)
                default: count <= count;      // Nenhum ou ambos ocorrem ao mesmo tempo (Mantém)
            endcase
        end
    end

endmodule
