// MÓDULO: control (Máquina de Estados Finita - FSM)
//   Implementa uma Máquina de Estados Finita (FSM) com 4 estados que coordena
//   o treinamento do perceptron. Responsável por:
//   • Sequenciar as fases de treinamento (inicialização, propagação, atualização)
//   • Gerenciar contadores de amostras e épocas
//   • Controlar a atualização dos pesos
//   • Monitorar sinais de status e tomar decisões de transição
//
// Estados da FSM:
//   ┌─────────────────────────────────────────────────────────────────┐
//   │                       START (2'b00)                             │
//   │  Ação: Reseta todas as estruturas para começar o treinamento    │
//   │  ↓                                                              │
//   │ ┌─────────────────────────────────────────────────────────────┐
//   │ │                      WAIT (2'b01)                           │
//   │ │ Ação: Aguarda permissão para treinar (entrada período da    │
//   │ │       amostra)                                              │
//   │ │ Condição: Se epoca_disponivel=1 → Forward                   │
//   │ │ ↓                                                           │
//   │ │ ┌──────────────────────────────────────────────────────────┐
//   │ │ │               FORWARD (2'b10)                            │
//   │ │ │ Ação: Captura o erro calculado (latência de combinação)  │
//   │ │ │ ↓                                                        │
//   │ │ │ ┌─────────────────────────────────────────────────────┐  │
//   │ │ │ │          BACKPROPAGATION (2'b11)                    │  │
//   │ │ │ │ Ação: Atualiza pesos com o erro capturado           │  │
//   │ │ │ │ Decisão: Se padrao_disponivel → Forward             │  │
//   │ │ │ │          Senão → Wait                               │  │
//   │ │ │ └─────────────────────────────────────────────────────┘  │
//   │ │ └──────────────────────────────────────────────────────────┘
//   │ └─────────────────────────────────────────────────────────────┘
//   └─────────────────────────────────────────────────────────────────┘
//
// Sinais de Entrada:
//   - epoca_disponivel: Status do datapath (é possível treinar mais épocas?)
//   - amostra_disponivel: Status do datapath (há mais amostras?)

module control (
    // ENTRADAS
    input clk,
    input rst,
    input epoch_disponivel,         // epoch_disponivel (datapath: época < máximo?)
    input amostra_disponivel,       // amostra_disponivel (datapath: amostra < 4?)
    
    // SAÍDAS
    output reg load_indice_amostra,       
    output reg clr_indice_amostra,        
    output reg load_epoch,            
    output reg clr_epoch,             
    output reg update_pesos,          
    output reg rst_pesos,             
    output reg load_erro,             
    output reg clr_erro              
);

    // REGISTRADORES E CONSTANTES
    // Estado atual e próximo estado da máquina
    reg [1:0] estado_atual, estado_proximo;

    // Definição dos Estados (codificação binária)
    parameter ESTADO_INICIAR    = 2'b00,  // Start
              ESTADO_AGUARDAR   = 2'b01,  // Wait
              ESTADO_PROPAGACAO = 2'b10,  // Forward
              ESTADO_RETRO      = 2'b11;  // Backpropagation

    // LÓGICA SEQUENCIAL - Transição de Estados (Sincronizado com CLK)
    always @(posedge clk or posedge rst) begin
        if (rst)
            // Reset: volta sempre para o estado inicial
            estado_atual <= ESTADO_INICIAR;
        else
            // Transição normal: assume o próximo estado
            estado_atual <= estado_proximo;
    end

    // LÓGICA COMBINACIONAL - FSM (Cálculo de Transições e Saídas)
    // Esta seção determina:
    // 1. Qual será o próximo estado (estado_proximo)
    // 2. Quais sinais de controle ativar em cada estado
    always @(*) begin
        
        // INICIALIZAÇÃO DE SINAIS
        // Todos os sinais começam desativados para evitar latches
        estado_proximo = estado_atual;
        load_indice_amostra = 1'b0;
        clr_indice_amostra = 1'b0;
        load_epoch = 1'b0;
        clr_epoch = 1'b0;
        update_pesos = 1'b0;
        rst_pesos = 1'b0;
        load_erro = 1'b0;
        clr_erro = 1'b0;

        // MÁQUINA DE ESTADOS - CASE DE TRANSIÇÕES
        case (estado_atual)

            // ESTADO: INICIAR (Start)
            // Objetivo: Preparar o sistema para iniciar o treinamento
            // Ações:
            //   • Limpar todas as contagens
            //   • Resetar os pesos para 0
            //   • Limpar o registrador de erro
            ESTADO_INICIAR: begin
                clr_epoch = 1'b1;       
                rst_pesos = 1'b1;       
                clr_erro = 1'b1;       
                
                // Próximo estado: Ir para AGUARDAR
                estado_proximo = ESTADO_AGUARDAR;
            end

            // ESTADO: AGUARDAR (Wait)
            // Objetivo: Aguardar e verificar se ainda há épocas para treinar
            // Ações:
            //   • Manter N (padrão) zerado enquanto aguarda
            //   • Incrementar época a cada ciclo de aguarda
            // Transição:
            //   • Se epoca_disponivel = 1: próximo estado é PROPAGACAO
            //   • Se epoca_disponivel = 0: permanecer em AGUARDAR
            ESTADO_AGUARDAR: begin
                clr_indice_amostra = 1'b1;  // N = 0 (manter em 0)
                load_epoch = 1'b1;          // EP = EP + 1
                
                if (epoch_disponivel)
                    // Há épocas disponíveis, começar a treinar
                    estado_proximo = ESTADO_PROPAGACAO;
                else
                    // Treino concluído (todas as épocas terminaram)
                    estado_proximo = ESTADO_AGUARDAR;
            end

            // ESTADO: PROPAGAÇÃO (Forward)
            // Objetivo: Capturar o erro calculado pelo datapath
            // Ações:
            //   • Carrega o erro_calculado (combinacional) no registrador
            // Detalhes Técnicos:
            //   A propagação é um cálculo combinacional no datapath:
            //   • soma = entrada * peso
            //   • y_pred = (soma >= threshold) ? 1 : 0
            //   • erro_calculado = y_esperado - y_pred
            //   
            //   No estado PROPAGACAO, apenas capturamos esse erro:
            //   • registrador_erro <= erro_calculado
            ESTADO_PROPAGACAO: begin
                load_erro = 1'b1;           // Erro = erro_calculado
                
                // Próximo estado: Ir para RETROPROPAGACAO
                estado_proximo = ESTADO_RETRO;
            end

            // ESTADO: RETROPROPAGAÇÃO (Backpropagation)
            // Objetivo: Atualizar pesos e passar para próxima amostra
            // Ações:
            //   • Atualiza pesos: w = w + erro * entrada
            //   • Incrementa contador de amostras (N)
            // Decisão (Transição):
            //   • Se amostra_disponivel = 1 (há mais amostras):
            //     → Próximo estado é PROPAGACAO (processa próxima amostra)
            //   • Se amostra_disponivel = 0 (todas as amostras processadas):
            //     → Próximo estado é AGUARDAR (próxima época)
            ESTADO_RETRO: begin
                update_pesos = 1'b1;        // w0, w1 = w + erro * x
                load_indice_amostra = 1'b1; // N = N + 1
                
                if (amostra_disponivel)
                    // Há mais amostras, voltar para PROPAGACAO
                    estado_proximo = ESTADO_PROPAGACAO;
                else
                    // Todas as amostras foram processadas, voltar para AGUARDAR
                    estado_proximo = ESTADO_AGUARDAR;
            end

            // ESTADO: DEFAULT
            default: begin
                estado_proximo = ESTADO_INICIAR;
            end
            
        endcase
    end

endmodule