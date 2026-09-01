
Em Verilog, o código dentro de um bloco initial ou always é executado sequencialmente (linha após linha). No entanto, às vezes precisamos executar duas ou mais ações ao mesmo tempo – por exemplo, monitorar um sinal enquanto um temporizador conta um tempo limite (timeout). É aí que entram as construções fork e join.

```verilog
fork
    // Bloco 1 (thread 1)
    begin
        // instruções que serão executadas em paralelo
    end

    // Bloco 2 (thread 2)
    begin
        // instruções que serão executadas em paralelo
    end

    // ... mais blocos ...
join
```

- O fork inicia a execução de todos os blocos begin...end simultaneamente.
- Cada bloco é chamado de thread.
- A instrução join (ou suas variantes) define quando o processo principal (aquele que contém o fork) continua sua execução após lançar as threads.

Variantes do join:
Comando	Comportamento
join	O processo principal espera todas as threads terminarem.
join_any	O processo principal espera qualquer uma das threads terminar.
join_none	O processo principal não espera nenhuma thread; continua imediatamente.

Exemplo:
```verilog
fork
    begin
        check_tx_sequence(8'h33, BAUD_TICKS_PER_BIT);   // Thread A
    end
    begin
        #1000000;                                       // Thread B (timeout)
        $display("[ERRO] Timeout na verificação da sequência");
        errors = errors + 1;
    end
join_any
wait(tx_valid == 1'b1);
$display("[OK] Transmissão não foi afetada pela mudança de data_i");
```

O fork lança duas threads em paralelo:

Thread A: chama a tarefa check_tx_sequence. Essa tarefa monitora uart_tx_o esperando a sequência de bits (start, 8 dados, stop). Ela pode levar um tempo considerável, pois contém vários @(posedge baud_tick).

Thread B: é um simples atraso de #1000000 unidades de tempo (no seu timescale, isso pode representar 1 ms, por exemplo). Após esse atraso, ela imprime uma mensagem de erro e incrementa o contador errors.

join_any: o processo principal fica bloqueado até que pelo menos uma das threads termine.

Se a Thread A terminar primeiro (ou seja, a verificação da sequência foi concluída antes do timeout), o join_any libera o processo principal. A Thread B continua rodando em segundo plano, mas eventualmente será descartada ou pode imprimir a mensagem de erro se a simulação ainda estiver ativa, mas isso não afetará o fluxo principal. Para evitar efeitos indesejados, é comum usar um disable para cancelar a thread de timeout quando não for mais necessária, mas neste código simples pode ser aceitável.

Se a Thread B terminar primeiro (timeout estourou), isso significa que a verificação não terminou a tempo. O join_any libera o processo principal e a Thread A fica em execução ainda. O código então segue para wait(tx_valid == 1'b1);, que pode travar se a transmissão realmente estiver com problema. Porém, a intenção é apenas sinalizar o erro e deixar o testbench continuar com outras verificações.

Após o join_any, o código principal continua com wait(tx_valid == 1'b1); e depois imprime [OK]. Nota: esse wait é executado independentemente de qual thread terminou primeiro, o que pode causar travamento se a transmissão não tiver terminado de fato. Em um testbench real, talvez fosse melhor verificar se a Thread A terminou antes de prosseguir ou usar um fork com disable para cancelar a thread de timeout.