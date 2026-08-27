# Xilinx Virtual Cable Server for ESP32

Este projeto é uma implementação do protocolo `XVC - Xilinx Virtual Cable`, que permite programar e depurar FPGAs da Xilinx utilizando um ESP32 através de uma rede Wi-Fi.

## Créditos e Repositórios Originais

Este código foi desacoplado e adaptado para este repositório, mas todo o crédito do desenvolvimento original pertence aos seus criadores:
- **Autor Principal:** Kenta IDA (https://github.com/ciniml) - [Repositório Original (ciniml/xvc-esp32)](https://github.com/ciniml/xvc-esp32)
- **Autor 2:** Dhiru Kholia - [Repositório Fork (kholia/xvc-esp32)](https://github.com/kholia/xvc-esp32.git) (Ajustes de portabilidade e otimizações)
- Baseado na implementação original para Raspberry Pi por Derek Mulcahy ([xvcpi](https://github.com/derekmulcahy/xvcpi)).

## Passo a Passo Fácil de Como Usar

Siga os passos abaixo para usar o seu ESP32 como um cabo virtual JTAG no Vivado:

### 1. Configuração do Código
1. Abra o arquivo `xvc-esp32.ino` (na pasta `xvc-esp32/`) usando a **Arduino IDE**.
2. Abra a aba do arquivo `credentials.h`.
3. Altere as credenciais de Wi-Fi (`ssid` e `password`) para o nome e senha da sua rede local.

### 2. Conexão Física (Hardware)
Conecte os pinos do ESP32 aos pinos JTAG da sua FPGA. Para a placa comum **ESP32 WROOM DevKit v1**, o mapeamento padrão é:

| Pino JTAG (FPGA) | Pino ESP32 |
|------------------|------------|
| **TDI**          | 25 (D25)   |
| **TDO**          | 21 (D21)   |
| **TCK**          | 19 (D19)   |
| **TMS**          | 22 (D22)   |
| **GND**          | GND        |

### 3. Compilação e Upload
1. Na Arduino IDE, vá em `Ferramentas > Placa` e selecione o seu modelo de ESP32 (ex: "ESP32 Dev Module").
2. Conecte o ESP32 via USB e selecione a porta correta em `Ferramentas > Porta`.
3. Clique em **Carregar (Upload)** para compilar e gravar o código no microcontrolador.
4. Abra o **Monitor Serial** (configure para 115200 baud). Quando o ESP32 conectar ao Wi-Fi, anote o **endereço IP** exibido na tela.

### 4. Uso no Vivado
1. Com a FPGA ligada e os fios do ESP32 conectados, abra o **Vivado**.
2. Acesse o **Hardware Manager** e abra uma nova sessão de hardware (Open Hardware Manager > Open Target > Auto Connect ou Open New Target).
3. Na janela do hardware, clique com o botão direito no seu Localhost (ou vá nas opções) e selecione **Add Virtual Cable**.
4. Insira o **endereço IP** do seu ESP32 que você anotou no passo anterior e clique em OK.
5. Pronto! O Vivado deve reconhecer a FPGA. Agora você pode programá-la com seu Bitstream ou usar o ILA exatamente como faria com um cabo JTAG físico.

## Licença
CC0 1.0 Universal (CC0 1.0) - Dedicação ao Domínio Público.
