# Relatório de Debug: O Mistério do 0xFA e o Gravador JTAG

## O Problema
Durante os testes de comunicação serial (UART) com a placa Tang Nano 20K usando o `PySerial`, os caracteres enviados (ex: `Hello FPGA!`) retornavam intercalados com o byte `0xFA`, além de alguns caracteres desaparecerem ou serem substituídos por `0xFF`. 

Exemplo de saída recebida no Python:
`b'\xfaH\xfae\xfal\xfal\xff\xfaP\xfaG\xfaA\xfa!'`

Isso gerava o erro de decodificação UTF-8: `'utf-8' codec can't decode byte 0xfa`.

## A Causa Raiz
O ruído **não estava sendo gerado pela FPGA**. O problema estava na seleção da porta serial (COM/TTY) no computador.

A placa Tang Nano 20K possui um chip controlador/gravador embutido (o BL616) que expõe **duas portas seriais simultâneas** via USB-C:
1. Uma porta para o **JTAG** (usada para gravar o bitstream na FPGA).
2. Uma porta para a **UART** (conectada aos pinos da FPGA para comunicação do usuário).

No Linux, essas portas costumam aparecer como `/dev/ttyUSB0` e `/dev/ttyUSB1` (ou ACM0/ACM1). O script Python estava se conectando à porta do JTAG (`ttyUSB0`) em vez da porta da UART (`ttyUSB1` ou superior).

## A Explicação Técnica (O Protocolo MPSSE)
A interface JTAG do BL616 emula o protocolo MPSSE (padrão de chips da FTDI). Esse protocolo possui regras rígidas de comunicação.

Se você envia dados aleatórios ou caracteres ASCII (como as letras de "Hello FPGA!") para a porta JTAG, o controlador tenta interpretá-los como comandos JTAG. 
O manual do protocolo MPSSE especifica que: **Se o controlador receber um comando inválido/desconhecido, ele deve responder com o código de erro de "Bad Command" (`0xFA`) seguido do byte que ele não entendeu.**

Foi exatamente isso que aconteceu:
* O PC enviou `'H'`. O gravador JTAG não reconheceu e respondeu: `[0xFA] [H]`.
* O PC enviou `'e'`. O gravador JTAG não reconheceu e respondeu: `[0xFA] [e]`.
* O PC enviou `'o'` (`0x6F`). Por pura coincidência, `0x6F` é um comando MPSSE válido (usado para configurar bits de dados). O gravador engoliu a letra `'o'` e os próximos bytes (`' '` e `'F'`) como parâmetros desse comando, sem ecoá-los de volta (o que explica por que essas letras sumiram e retornaram `0xFF`).

## A Solução
1. **Seleção de Porta**: Mudar a porta no script Python (ex: de `/dev/ttyUSB0` para `/dev/ttyUSB1` ou `/dev/ttyUSB2`), garantindo a conexão com a UART da FPGA e não com o gravador.
2. **Correção de Hardware (FSM)**: Aproveitamos a investigação para refinar a máquina de estados (FSM) da UART no Verilog, garantindo que o 8º bit aguarde o ciclo completo de 16 *ticks* do baud rate (`if(bit_count == 4'd7 && tick_count == 4'b1111)`) antes de transitar para o estado de repouso (`STOP`).

## Conclusão
O código Verilog e a FPGA sempre estiveram corretos em relação à lógica de eco. O comportamento anômalo foi causado pela comunicação acidental com o firmware de gravação da placa, que respondeu fielmente de acordo com a especificação do seu protocolo.
