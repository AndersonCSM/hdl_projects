projeto do protocolo uart com transmissão e recepção.
O projeto funciona em modo echo, tudo que é recebido é retransmitido

os arquivos do projeto são:
baud_rate_generator
top
uart_echo_controller
uart_rx
uart_tx

arquivo de teste:
teste_simples.ipynb

arquivo a ser gerado:
tb_top.sv

arquivo para modificar:
makefile
-> adicionar make run_test que irá gerar um .txt da simulação ou algo que possa ser lido facilmente