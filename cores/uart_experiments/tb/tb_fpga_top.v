`timescale 1ns/1ps

module tb_fpga_top();

    parameter CLK_PERIOD = 37.037;  // 27 MHz
    parameter BIT_PERIOD = 8680.55; // 115200 bps

    reg clk;
    reg rst_n;
    reg rx;
    wire tx;

    integer errors = 0;
    integer test_id = 0;
    integer log_file;

    // Instancia o módulo principal
    fpga_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .tx(tx)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD / 2.0) clk = ~clk;

    // ==========================================
    // TASKS DE INFRAESTRUTURA E LOGGING
    // ==========================================
    task log_message;
        input string msg;
        begin
            $display("%s", msg);
            $fdisplay(log_file, "%s", msg);
        end
    endtask

    task check_value;
        input [7:0] expected;
        input [7:0] actual;
        input string description;
    begin
        if (expected !== actual) begin
            log_message($sformatf("[ERRO] %s: esperado %h, obtido %h (tempo %0t)", description, expected, actual, $time));
            errors = errors + 1;
        end else begin
            log_message($sformatf("[OK]   %s (tempo %0t)", description, $time));
        end
    end
    endtask

    task apply_reset;
        input integer duration;
    begin
        rst_n = 1'b1; // Pressiona o botão (inativo = 0, então 1 ativa o reset)
        repeat(duration) @(posedge clk);
        rst_n = 1'b0; // Solta o botão
    end
    endtask

    // ==========================================
    // TASKS DE COMUNICAÇÃO UART (RX / TX)
    // ==========================================
    task send_byte_to_rx;
        input [7:0] data;
        integer i;
    begin
        rx = 1'b0; // Start bit
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #(BIT_PERIOD);
        end
        rx = 1'b1; // Stop bit
        #(BIT_PERIOD);
    end
    endtask

    task receive_byte_from_tx;
        output [7:0] data;
        integer i;
    begin
        fork
            begin
                wait(tx == 1'b0);    // Espera a borda de descida do Start bit
                #(BIT_PERIOD / 2.0); // Move para o centro do Start bit
                #(BIT_PERIOD);       // Move para o centro do Bit 0
                for (i = 0; i < 8; i = i + 1) begin
                    data[i] = tx;
                    #(BIT_PERIOD);
                end
                // Aqui estamos no centro do Stop bit, podemos sair
            end
            begin
                #500000; // Timeout de segurança (~5 bytes)
                log_message($sformatf("[ERRO] Timeout aguardando TX enviar byte! (tempo %0t)", $time));
                errors = errors + 1;
            end
        join_any
        disable fork; // Mata o timeout se já recebeu, ou mata o receive se deu timeout
    end
    endtask

    task send_string;
        input string str;
        integer i;
    begin
        for (i = 0; i < str.len(); i = i + 1) begin
            send_byte_to_rx(str[i]);
        end
    end
    endtask

    task expect_string;
        input string str;
        integer i;
        reg [7:0] rcv;
    begin
        for (i = 0; i < str.len(); i = i + 1) begin
            receive_byte_from_tx(rcv);
            check_value(str[i], rcv, $sformatf("Eco do char '%s' (%h)", str.substr(i, i), str[i]));
        end
    end
    endtask

    // ==========================================
    // CASOS DE TESTE PRINCIPAIS
    // ==========================================
    initial begin
        log_file = $fopen("../sim/fpga_top_test_results.txt", "w");
        if (log_file == 0) begin
            $display("ERRO: Não foi possível criar o arquivo de log em ../sim/");
            $finish;
        end

        // Setup inicial
        rx = 1'b1;
        rst_n = 1'b0;
        #100;

        log_message("=============================================");
        log_message(" Testes do Módulo Principal (fpga_top)");
        log_message("=============================================");

        // -----------------------------------------------------
        test_id = 1;
        log_message($sformatf("\nTC-%0d: Estado inicial após reset", test_id));
        apply_reset(10);
        #1000;
        if (tx !== 1'b1) begin
            log_message("[ERRO] TX não está em repouso (1) após reset!");
            errors = errors + 1;
        end else begin
            log_message("[OK]   TX em repouso após reset");
        end

        // -----------------------------------------------------
        test_id = 2;
        log_message($sformatf("\nTC-%0d: Eco de um único caractere ('A' - 0x41)", test_id));
        apply_reset(5);
        #1000;
        fork
            send_byte_to_rx(8'h41);
            begin
                reg [7:0] received;
                receive_byte_from_tx(received);
                check_value(8'h41, received, "Eco do caractere 'A'");
            end
        join

        // -----------------------------------------------------
        test_id = 3;
        log_message($sformatf("\nTC-%0d: Eco da string 'Hello FPGA!' (Back-to-back)", test_id));
        apply_reset(5);
        #1000;
        // Envia a string inteira de um lado, e escuta tudo do outro lado simultaneamente!
        fork
            send_string("Hello FPGA!");
            expect_string("Hello FPGA!");
        join

        log_message("\n=============================================");
        if (errors == 0)
            log_message("TODOS OS TESTES PASSARAM!");
        else
            log_message($sformatf("FALHAS: %0d erros encontrados", errors));
        log_message("=============================================");

        $fclose(log_file);
        $finish;
    end

    // Geração das Ondas (VCD)
    initial begin
        $dumpfile("../sim/fpga_top_tb.vcd");
        $dumpvars(0, tb_fpga_top);
    end

endmodule
