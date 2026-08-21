`default_nettype none
`timescale 1ns/1ps

// ============================================================================
// Testbench: tb_top
// Descrição: Testbench para validar o UART Echo
// Testa: Recepção de dados serial, retransmissão automática
// ============================================================================

module tb_top;

    // ===== PARÂMETROS =====
    localparam CLK_FREQ = 27_000_000;      // 27 MHz
    localparam BAUD_RATE = 115200;         // 115200 bps
    localparam CLK_PERIOD = 1000.0 / (CLK_FREQ / 1_000_000);  // em ns
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;  // Must match baud_rate_generator
    localparam BIT_PERIOD = DIVISOR * CLK_PERIOD;  // Period em ns baseado no DIVISOR real
    
    // ===== SINAIS DE TESTE =====
    reg clk;
    reg rst;
    wire uart_rx;
    wire uart_tx;
    
    // Sinais auxiliares
    reg rx_bit;
    wire tx_bit;
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // ===== SINAIS DE DEBUG =====
    wire tick;
    wire [7:0] rx_data_debug;
    wire rx_done_debug;
    wire [7:0] tx_data_debug;
    wire tx_send_debug;
    wire tx_done_debug;
    wire [1:0] rx_state_debug;
    wire [3:0] rx_bit_count_debug;
    wire [3:0] rx_done_counter_debug;
    
    // ===== INSTÂNCIA DO DUV (Device Under Test) =====
    top dut (
        .clk(clk),
        .btn1(rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );
    
    // Conectar rx_bit ao uart_rx
    assign uart_rx = rx_bit;
    assign tx_bit = uart_tx;
    
    // Sinais internos para debug
    assign tick = dut.tick;
    assign rx_data_debug = dut.rx_data;
    assign rx_done_debug = dut.rx_done;
    assign tx_data_debug = dut.tx_data;
    assign tx_send_debug = dut.tx_send;
    assign tx_done_debug = dut.tx_done;
    assign rx_state_debug = dut.rx_inst.debug_state;
    assign rx_bit_count_debug = dut.rx_inst.debug_bit_count;
    assign rx_done_counter_debug = dut.rx_inst.debug_done_counter;
    
    // ===== GERADOR DE CLOCK =====
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ===== TASK: Enviar byte via UART (sincronizado com tick) =====
    task send_uart_byte_sync(input [7:0] data);
        integer i;
        begin
            $display("[SEND] Enviando byte: 0x%02X ('%c')", data, (data >= 32 && data < 127) ? data : 63);

            // Sincronizar com tick
            wait(tick == 1'b1);

            // Start bit (0) - manter por DIVISOR ciclos de clock (= 1 bit period)
            rx_bit = 1'b0;
            repeat(DIVISOR) @(posedge clk);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_bit = data[i];
                repeat(DIVISOR) @(posedge clk);
            end

            // Stop bit (1)
            rx_bit = 1'b1;
            repeat(DIVISOR) @(posedge clk);

            $display("[SEND] Byte enviado com sucesso");
        end
    endtask
    
    // Manter a versão antiga para compatibilidade
    task send_uart_byte(input [7:0] data);
        send_uart_byte_sync(data);
    endtask
    
    // ===== TASK: Receber byte via UART =====
    task receive_uart_byte(output [7:0] data);
        integer i;
        integer timeout_counter;
        begin
            $display("[RECV] Aguardando transmissão...");
            // Aguardar start bit com timeout maior
            timeout_counter = 0;
            while (tx_bit == 1'b1 && timeout_counter < 100000) begin
                #100;
                timeout_counter = timeout_counter + 1;
            end
            
            if (timeout_counter >= 100000) begin
                $display("[RECV] ERRO: Timeout aguardando start bit!");
                $display("[DEBUG] uart_tx permaneceu em 1 durante o timeout");
                $display("[DEBUG] tx_send=%b, tx_data=0x%02X, tx_done=%b", 
                    tx_send_debug, tx_data_debug, tx_done_debug);
                data = 8'hXX;
            end else begin
                $display("[RECV] Start bit detectado em %d ns (loop iterations=%d)", $time, timeout_counter);
            
            // Aguardar meio do start bit
            #(BIT_PERIOD / 2);
            
            // Amostrar data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                #(BIT_PERIOD);
                data[i] = tx_bit;
            end
            
                // Aguardar stop bit
                #(BIT_PERIOD);
                
                if (tx_bit == 1'b1) begin
                    $display("[RECV] Byte recebido: 0x%02X ('%c')", 
                        data, (data >= 32 && data < 127) ? data : 63);
                end else begin
                    $display("[RECV] ERRO: Stop bit não detectado!");
                end
            end
        end
    endtask
    
    // ===== TASK: Comparar bytes =====
    task check_byte(input [7:0] expected, input [7:0] received, input [31:0] test_name);
        begin
            test_count = test_count + 1;
            
            if (expected === received) begin
                $display("[PASS] %s: 0x%02X ('%c')", 
                    test_name, expected, (expected >= 32 && expected < 127) ? expected : 63);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s: esperado 0x%02X, recebido 0x%02X", 
                    test_name, expected, received);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // ===== PROCEDIMENTO PRINCIPAL DE TESTE =====
    initial begin
        $display("========================================");
        $display("  TESTBENCH: UART ECHO - Tang Nano 20K");
        $display("========================================");
        $display("");
        $display("Configuração:");
        $display("  Clock: %d MHz", CLK_FREQ / 1_000_000);
        $display("  Baud Rate: %d bps", BAUD_RATE);
        $display("  Período do clock: %0.2f ns", CLK_PERIOD);
        $display("  Período do bit UART: %0.0f ns", BIT_PERIOD);
        $display("");
        
        // ===== INICIALIZAÇÃO =====
        $display("========================================");
        $display("  FASE 1: INICIALIZAÇÃO");
        $display("========================================");
        $display("");
        
        rx_bit = 1'b1;  // Idle
        rst = 1'b0;     // Reset ativo (ativo baixo)
        
        // Aplicar reset por 1 microsegundo
        #(1000);
        rst = 1'b1;     // Release reset
        
        $display("Reset aplicado");
        $display("Aguardando estabilização do sistema...");
        $display("");
        
        // Aguardar estabilização (100 ciclos de clock)
        #(100 * CLK_PERIOD);
        
        // ===== TESTE 1: Caractere 'A' (0x41) =====
        $display("========================================");
        $display("  TESTE 1: Caractere 'A' (0x41)");
        $display("========================================");
        $display("");
        
        send_uart_byte(8'h41);  // 'A'
        // #(BIT_PERIOD);    // Aguardar muito tempo para RX completar
        
        $display("[DEBUG] Após envio 'A':");
        $display("  rx_done=%b, rx_data=0x%02X", rx_done_debug, rx_data_debug);
        $display("  RX state=%d, bit_count=%d, done_counter=%d", rx_state_debug, rx_bit_count_debug, rx_done_counter_debug);
        $display("  tx_send=%b, tx_data=0x%02X, uart_tx=%b",
            tx_send_debug, tx_data_debug, tx_bit);
        
        begin
            reg [7:0] rx_data;
            receive_uart_byte(rx_data);
            check_byte(8'h41, rx_data, "Echo de 'A'");
        end
        $display("");
        
        // ===== TESTE 2: Caractere 'Z' (0x5A) =====
        $display("========================================");
        $display("  TESTE 2: Caractere 'Z' (0x5A)");
        $display("========================================");
        $display("");
        
        send_uart_byte(8'h5A);  // 'Z'
        //#(500 * BIT_PERIOD);    // Aguardar muito tempo
        
        $display("[DEBUG] Após envio 'Z':");
        $display("  rx_done=%b, rx_data=0x%02X", rx_done_debug, rx_data_debug);
        $display("  tx_send=%b, tx_data=0x%02X, uart_tx=%b",
            tx_send_debug, tx_data_debug, tx_bit);
        
        begin
            reg [7:0] rx_data;
            receive_uart_byte(rx_data);
            check_byte(8'h5A, rx_data, "Echo de 'Z'");
        end
        $display("");
        
        // ===== TESTE 3: Caractere '0' (0x30) =====
        $display("========================================");
        $display("  TESTE 3: Caractere '0' (0x30)");
        $display("========================================");
        $display("");
        
        send_uart_byte(8'h30);  // '0'
        // #(500 * BIT_PERIOD);    // Aguardar muito tempo
        
        $display("[DEBUG] Após envio '0':");
        $display("  rx_done=%b, rx_data=0x%02X", rx_done_debug, rx_data_debug);
        $display("  tx_send=%b, tx_data=0x%02X, uart_tx=%b",
            tx_send_debug, tx_data_debug, tx_bit);
        
        begin
            reg [7:0] rx_data;
            receive_uart_byte(rx_data);
            check_byte(8'h30, rx_data, "Echo de '0'");
        end
        $display("");
        
        // ===== TESTE 4: Caractere '9' (0x39) =====
        $display("========================================");
        $display("  TESTE 4: Caractere '9' (0x39)");
        $display("========================================");
        $display("");
        
        send_uart_byte(8'h39);  // '9'
        //#(500 * BIT_PERIOD);    // Aguardar muito tempo
        
        begin
            reg [7:0] rx_data;
            receive_uart_byte(rx_data);
            check_byte(8'h39, rx_data, "Echo de '9'");
        end
        $display("");
        
        // Sem teste 5 por simplicidade
        
        // Sem teste 6 por simplicidade
        
        // ===== RESUMO FINAL =====
        $display("========================================");
        $display("  RESUMO FINAL");
        $display("========================================");
        $display("");
        
        $display("Total de testes: %d", test_count);
        $display("Testes aprovados: %d", pass_count);
        $display("Testes falhados: %d", fail_count);
        $display("");
        
        if (fail_count == 0 && test_count > 0) begin
            $display("RESULTADO: ✓ TODOS OS TESTES PASSARAM");
        end else if (test_count == 0) begin
            $display("RESULTADO: ✗ NENHUM TESTE FOI EXECUTADO");
        end else begin
            $display("RESULTADO: ✗ ALGUNS TESTES FALHARAM");
        end
        
        $display("========================================");
        $display("");
        
        // Finalizar simulação
        #(100 * CLK_PERIOD);
        $finish;
    end

endmodule
