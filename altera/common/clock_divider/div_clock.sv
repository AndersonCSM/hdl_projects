module div_clock(
    input logic clk,
    input logic rst,
    input logic [23:0] DIV_COUNT,
    output logic clk_out
);

    // VERSAO 1: Divisor que gera um PULSO curto a cada DIV_COUNT ciclos.
    // 
    // Este modulo nao gera uma onda quadrada, mas um evento discreto (pulso).
    // Sempre que o contador chega ao limite, clk_out fica em 1 por exatamente 1 ciclo.
    //
    // Exemplo pratico:
    // - Se CLK_ENTRADA = 27 MHz e DIV_COUNT = 13_500_000
    // - Resultado: um pulso a cada 13.5M ciclos = a cada 0.5 segundos (~2 Hz)
    //
    // Diferenca com div_clock_hz:
    // - div_clock: gera PULSOS (util para sinais de enable/trigger)
    // - div_clock_hz: gera ONDA QUADRADA (util para clock de outras logicas)

    // Contador interno que faz a contagem dos ciclos do clock de entrada.
    logic [23:0] contador;

    // Logica sequencial acionada a cada borda de subida do clock.
    // Reset ativo em nivel baixo (if !rst).
    always_ff @(posedge clk) begin
        if (!rst) begin
            // Reset sincrono: volta tudo ao estado inicial.
            contador <= 24'd0;
            clk_out  <= 1'b0;
        end else if (contador == DIV_COUNT - 1'b1) begin
            // Ao atingir o fim de um ciclo de divisao:
            // - zera o contador para reiniciar a contagem
            // - gera um pulso alto por 1 ciclo de clock
            contador <= 24'd0;
            clk_out  <= 1'b1;
        end else begin
            // Enquanto ainda nao chegou ao limite:
            // - incrementa o contador
            // - mantém a saida em nivel baixo
            contador <= contador + 1'b1;
            clk_out  <= 1'b0;
        end
    end

endmodule