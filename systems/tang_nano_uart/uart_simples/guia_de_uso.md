# Guia de Uso: Projeto UART Simples (Echo) na Tang Nano 20K

Este guia mostra o passo a passo de como simular, compilar, gravar e testar o projeto de UART em hardware real utilizando a placa FPGA Tang Nano 20K.

## 1. Simulação e Teste Local

Antes de ir para a placa física, você pode rodar as simulações para garantir que a lógica está correta.

1. Abra o terminal na pasta do projeto.
2. Execute o comando Make para rodar a simulação:
   ```bash
   make run_test
   ```
3. O comando irá compilar os arquivos e exibir o resultado no terminal. O resumo informará se os testes do `tb_top.sv` passaram ou falharam. 
4. Os detalhes completos do teste ficam salvos no arquivo `simulation_log.txt`.

## 2. Gravar o Projeto na Placa (Hardware)

Após sintetizar o projeto na sua ferramenta (ex: Gowin EDA) ou utilizar o bitstream gerado previamente (`uart.fs`), você precisa enviar isso para a placa.

1. Conecte a sua Tang Nano 20K no computador via cabo USB-C.
2. Com o arquivo `uart.fs` gerado na pasta do projeto, utilize a ferramenta de gravação de sua preferência. No Linux, utilizando o **openFPGALoader**, rode:
   ```bash
   openFPGALoader -b tangnano20k uart.fs
   ```

## 3. Descobrir a Porta Serial (Linux)

A Tang Nano 20K cria automaticamente portas seriais virtuais ao ser conectada no computador.

1. No terminal, liste os dispositivos seriais conectados:
   ```bash
   ls /dev/ttyUSB*
   ```
2. Geralmente aparecerão duas portas (ex: `/dev/ttyUSB0` e `/dev/ttyUSB1`). A UART ligada à FPGA geralmente é a de **número mais alto** (ex: `/dev/ttyUSB1`).

## 4. Comunicação Serial (Testando o Echo)

Com a placa gravada e a porta descoberta, agora vamos nos comunicar usando o computador.

### Usando o `screen` (Linux)

1. Para abrir a comunicação na velocidade correta configurada no projeto (115200 bps), utilize o comando:
   ```bash
   sudo screen /dev/ttyUSB1 115200
   ```
   *(Substitua `ttyUSB1` pela sua porta, caso necessário).*

2. **Testando:** Digite qualquer letra no seu teclado. O terminal enviará a letra para o pino `uart_rx`, o projeto devolverá a letra no pino `uart_tx`, e ela aparecerá refletida na sua tela.
3. **Comprovando:** Segure o botão de Reset físico da placa (`btn1`) e digite. O projeto será resetado e parará de ecoar, então nada aparecerá na tela enquanto você digita.
4. **Sair do `screen`:** Aperte `Ctrl + A`, depois solte, e em seguida aperte `K` (para dar "kill"). Confirme com `Y`.

### Outras Ferramentas (Windows / Linux)
Caso não queira usar o `screen`, você pode configurar as mesmas opções (Baud: 115200, Data bits: 8, Parity: None, Stop bits: 1) em:
- **Putty**
- **Minicom**
- **Monitor Serial da Arduino IDE**
