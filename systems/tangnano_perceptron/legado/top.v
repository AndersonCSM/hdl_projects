// MÓDULO: top
//   Módulo top-level que integra os submódulos control.v e datapath.v.
//   Responsabilidades:
//   • Divisão de frequência (27 MHz → ~1 Hz para visualização em LEDs)
//   • Conversão de sinais de entrada (botões)
//   • Interconexão de controle e datapath
//   • Formatação de saída para LEDs
//
// Pinagem da Placa Tang Nano 1K:
//   Entradas:
//     - clk: Clock do sistema (27 MHz)
//     - btn1: Botão de reset (ativo baixo = pressionado)
//   
//   Saídas:
//     - led[5:3]: 3 bits menos significativos de w0
//     - led[2:0]: 3 bits menos significativos de w1
//
// Notas de Temporização:
//   • Frequência original: 27 MHz
//   • Período original: ~37 ns
//   • Clock reduzido: ~1 Hz
//   • Período reduzido: ~1 segundo
//   • Finalidade: Visualizar mudanças de pesos nos LEDs

module top(
    // ENTRADAS
    input clk,      // Clock de 27 MHz da placa
    input btn1,     // Botão 1 (Reset) - ativo baixo
    
    // SAÍDAS 
    output [5:0] led    // 6 LEDs: mostrando w0[2:0] e w1[2:0]
);

    // DIVISOR DE FREQUÊNCIA (Clock Reduction)
    // Objetivo: Reduzir 27 MHz para ~1 Hz para visualizar mudanças nos LEDs
    // Frequência original: 27 MHz
    // Frequência desejada: ~1 Hz (para teste/visualização)
    // Divisor necessário: 27 MHz / 1 Hz = 27.000.000 ciclos
    // Aproximação: 13.500.000 ciclos de subida + 13.500.000 descida = 27M ciclos
    
    reg [23:0] contador_clk = 24'hFFFFFF;  // Contador de divisão de frequência
    reg clk_util;                   // Clock após divisão (~1 Hz)

    always @(posedge clk) begin
        // Se botão pressionado (btn1=0): reseta o contador
        if (!btn1)
            contador_clk <= 24'd0;
        // Se contador chegou ao máximo: gera pulso e reseta
        else if (contador_clk == 24'd13500000)
            contador_clk <= 24'd0;
        // Caso normal: incrementa contador
        else
            contador_clk <= contador_clk + 1;
        
        // Gera pulso de clock reduzido
        clk_util = (contador_clk == 24'd0);
    end   

    // SINAIS INTERNOS - Interconexão entre Módulos
    
    // Sinais de Controle
    wire load_indice_amostra;         
    wire clr_indice_amostra;        
    wire load_epoch;               
    wire clr_epoch;               
    wire update_pesos;              
    wire rst_pesos;               
    wire load_erro;                
    wire clr_erro;                
    
    // Sinais de Status
    wire epoch_disponivel;          
    wire amostra_disponivel;         
    
    // Sinais de Dados
    wire signed [7:0] peso_w0;      // w0
    wire signed [7:0] peso_w1;      // w1
    
    // Reset convertido (ativo alto)
    wire reset_ativo_alto = ~btn1;  // rst = NOT btn1

    // INSTANCIAÇÃO DO MÓDULO DE CONTROLE (FSM)
    control control_instance (
        .clk(clk_util),
        .rst(reset_ativo_alto),
        .epoch_disponivel(epoch_disponivel),
        .amostra_disponivel(amostra_disponivel),
        .load_indice_amostra(load_indice_amostra),
        .clr_indice_amostra(clr_indice_amostra),
        .load_epoch(load_epoch),
        .clr_epoch(clr_epoch),
        .update_pesos(update_pesos),
        .rst_pesos(rst_pesos),
        .load_erro(load_erro),
        .clr_erro(clr_erro)
    );

    // INSTANCIAÇÃO DO MÓDULO DATAPATH (Perceptron)
    datapath datapath_instance (
        .clk(clk_util),
        .load_indice_amostra(load_indice_amostra),
        .clr_indice_amostra(clr_indice_amostra),
        .load_epoch(load_epoch),
        .clr_epoch(clr_epoch),
        .update_pesos(update_pesos),
        .rst_pesos(rst_pesos),
        .load_erro(load_erro),
        .clr_erro(clr_erro),
    // Sinais de Dados
        .max_epoch(4'd10),           // Treinar por 10 épocas máximo
        .epoch_disponivel(epoch_disponivel),
        .amostra_disponivel(amostra_disponivel),
        .peso_w0(peso_w0),
        .peso_w1(peso_w1)
    );

    // FORMATAÇÃO DE SAÍDA - Mapeamento para LEDs
    // Saída dos pesos nos LEDs (6 LEDs disponíveis na placa)
    // 
    // Formato:  led[5:3] = peso_w1[2:0]   (3 bits menos significativos de w1)
    //           led[2:0] = peso_w0[2:0]   (3 bits menos significativos de w0)
    //
    // Exemplo: Se w0=5 (binário 101) e w1=3 (binário 011)
    //   → led = {011, 101} = 6'b011101
    //   → LED5 LED4 LED3 LED2 LED1 LED0
    //       0    1    1    1    0    1
    
    assign led = {peso_w1[2:0], peso_w0[2:0]};

endmodule