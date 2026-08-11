module div_clock_hz #(
    // /  Para sobrescrever um parameter na instanciação, você usa o símbolo # antes da lista de parâmetros.
    // Frequencia do clock que entra no modulo, em Hz.
    parameter int unsigned CLK_FREQ_HZ = 27_000_000,
    // Frequencia que queremos na saida, em Hz.
    parameter int unsigned OUT_FREQ_HZ = 1
)(
    input  logic clk,
    input  logic rst,
    output logic clk_out
);

    // VERSÃO 2: gera um sinal quadrado, ou seja:
    // - fica um tempo em 0
    // - depois um tempo em 1
    // - e continua repetindo esse ciclo
    //
    // Para isso, calculamos quantos ciclos do clock de entrada cabem em
    // meio periodo do clock de saida.
    //
    // O clock de saida alterna a cada meio periodo calculado a partir
    // da frequencia de entrada e da frequencia pedida pelo usuario.
    // Diferença de versões:
    // clk / div_count dá um evento periódico, geralmente um pulso.
    //    
    // HALF_PERIOD = CLK_FREQ_HZ / (2 * OUT_FREQ_HZ) dá uma onda quadrada de frequência desejada
    
    // localparam = parâmetro que só existe no módulo div_clock
    localparam int unsigned HALF_PERIOD = CLK_FREQ_HZ / (2 * OUT_FREQ_HZ);

    // Contador interno que conta os ciclos do clock de entrada.
    logic [31:0] contador;

    // Sempre que o clock de entrada sobe, o modulo verifica o reset
    // e decide se deve reiniciar, contar ou trocar o estado da saida.
    always_ff @(posedge clk) begin
        if (!rst) begin
            // Reset ativo em nivel baixo: volta tudo para o estado inicial.
            contador <= 32'd0;
            clk_out  <= 1'b0;
        end else if (contador == HALF_PERIOD - 1) begin
            // Quando chega ao fim de meio periodo, zera o contador
            // e inverte a saida para completar a onda quadrada.
            contador <= 32'd0;
            clk_out  <= ~clk_out; // alterna entre 0 e 1 o que cria uma onda quadrada
        end else begin
            // Enquanto ainda nao chegou ao limite, continua contando.
            contador <= contador + 1'b1;
        end
    end

endmodule
