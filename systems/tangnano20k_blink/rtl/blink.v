module top (
    // 'input' define uma porta de entrada. 'wire' é o tipo padrão para conexões físicas.
    input  wire clk,   // clock principal da placa (ex: 50 MHz)
    
    // 'output' define uma porta de saída. 'reg' é usado aqui porque o valor
    // será atualizado dentro de um bloco 'always' sequencial.
    output reg led     // pino conectado ao LED da placa
);

    // Registrador (variável) de 25 bits para atuar como contador.
    // 25 bits podem contar de 0 até 33.554.431, o que é suficiente para 
    // armazenar o valor 10.000.000.
    reg [24:0] cnt;
    
    // O bloco 'always' com 'posedge clk' cria lógica sequencial (Flip-Flops).
    // Todo o código aqui dentro será executado apenas na borda de subida do clock.
    always @(posedge clk) begin
        // Verifica se o contador atingiu o valor máximo desejado.
        // Se o clock for de 50 MHz, contar até 10_000_000 significa que o LED
        // vai piscar (inverter de estado) 5 vezes por segundo (a cada 200ms).
        if (cnt == 25'd9_999_999 - 1) begin
            cnt <= 1'd0;       // Zera o contador usando atribuição não-bloqueante (<=)
            led <= ~led;    // Inverte o estado atual do LED (de aceso para apagado e vice-versa)
        end else begin
            // Caso ainda não tenha atingido o valor, apenas incrementa o contador
            cnt <= cnt + 1'd1;
        end
    end
    
endmodule
