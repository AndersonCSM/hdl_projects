module testbench();

    // 1. Declaração de Sinais
    // Entradas do módulo viram 'reg' (para poder manipular os valores)
    reg clk_i = 0;
    reg rst_i = 0;
    // ... adicione as outras entradas específicas do seu módulo aqui ...

    // Saídas do módulo viram 'wire' (para receber os valores)
    // ... adicione as saídas aqui ...

    // 2. Geração de Clock Principal (Ex: Clock de 27MHz da Tang Nano)
    // Período de ~37.03ns -> Metade do período (toggle) a cada ~18.5ns
    always #18.5 clk_i = ~clk_i;

    // 3. Instância do Módulo sob Teste (DUT - Device Under Test)
    // Substitua 'nome_do_modulo' pelo componente que quer testar (ex: rx, tx, fifo)
    nome_do_modulo dut (
        .clk_i(clk_i),
        .rst_i(rst_i)
        // Conecte as demais portas aqui usando mapeamento por nome (.porta(sinal))
    );

    // 4. Estímulos e Casos de Teste (Injeção de sinais e comandos)
    initial begin
        // Sequência inicial de Reset (Ativo em nível baixo, conforme seu projeto)
        rst_i = 1'b0; 
        #200;         // Espera alguns ciclos
        rst_i = 1'b1; // Libera o reset
        
        // --- SEU CENÁRIO DE TESTE ENTRA AQUI ---
        #10000;       // Tempo de simulação para o teste rodar
        
        $finish;      // Encerra a simulação automaticamente
    end 

    // 5. Configuração de Dump para Visualização de Ondas no GTKWave
    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

endmodule