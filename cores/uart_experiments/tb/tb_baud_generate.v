`timescale 1ns/1ps

module tb_baud_generate();
    reg clk_i = 0;
    reg rst_i = 0;
    wire baud_tick;

    // Contadores de automação
    integer success_count = 0;
    integer fail_count = 0;
    reg [31:0] cycle_counter = 0;
    reg first_tick_seen = 0;
    
    // Arquivo de log
    integer log_file;

    // Geração do clock principal (27MHz -> Período de ~37.03ns)
    always #18.5 clk_i = ~clk_i;

    // Instanciação do Device Under Test (DUT)
    baud_generate #(
        .BAUD_RATE(115200),
        .CLK_FREQ(27_000_000)
    ) dut (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .baud_tick(baud_tick)
    );

    // Tarefa para imprimir no console e no arquivo
    task log_message;
        input string msg;
        begin
            $display("%s", msg);
            $fdisplay(log_file, "%s", msg);
        end
    endtask

    // BLOCO AUTOMATIZADO DE VALIDAÇÃO
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            cycle_counter <= 0;
            first_tick_seen <= 0;
        end else begin
            if (baud_tick) begin
                if (!first_tick_seen) begin
                    first_tick_seen <= 1'b1;
                    cycle_counter <= 0;
                end else begin
                    if (cycle_counter == 14) begin
                        success_count <= success_count + 1;
                        log_message("[SUCCESS] Tick recebido no tempo exato (15 ciclos).");
                    end else begin
                        fail_count <= fail_count + 1;
                        log_message($sformatf("[FAIL] Tick fora de hora! Intervalo medido: %0d ciclos (Esperado: 15)", cycle_counter));
                    end
                    cycle_counter <= 0;
                end
            end else begin
                cycle_counter <= cycle_counter + 1'b1;
            end
        end
    end

    // CENÁRIOS DE TESTE
    initial begin
        // Abrir arquivo de log (pasta sim irmã de tb)
        log_file = $fopen("../sim/baud_generate_test_results.txt", "w");
        if (log_file == 0) begin
            $display("ERRO: Não foi possível criar o arquivo de log.");
            $finish;
        end

        log_message("==================================================");
        log_message("   INICIO DA AUTOMACAO: tb_baud_generate          ");
        log_message("==================================================");
        
        rst_i = 1'b0;
        #200;
        rst_i = 1'b1;
        
        #20000;
        
        log_message("==================================================");
        log_message("   RELATORIO FINAL DE TESTES                      ");
        log_message("==================================================");
        log_message($sformatf(" TOTAL DE SUCCESS : %0d", success_count));
        log_message($sformatf(" TOTAL DE FAILS   : %0d", fail_count));
        log_message("==================================================");
        
        if (fail_count == 0 && success_count > 0) begin
            log_message(" RESULTADO: APROVADO COM SUCESSO!");
        end else begin
            log_message(" RESULTADO: REPROVADO!");
        end
        log_message("==================================================");
        
        $fclose(log_file);
        $finish;
    end

    // Dump para waveform
    initial begin
        $dumpfile("../sim/baud_generate_tb.vcd");
        $dumpvars(0, tb_baud_generate);
    end
endmodule