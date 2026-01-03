# SNMPD Custom Control e Tabela de Processos

## 1. Controle e Status do Serviço SNMPD via SNMP

### Opção 1: Usando extend (apenas leitura)

1. Crie o script de status:
   Salve como `/usr/local/bin/snmpd_status.sh`:
   ```bash
   #!/bin/bash
   systemctl is-active snmpd | grep -q active && echo 2 || echo 1
   ```
   Torne executável:
   ```bash
   sudo chmod +x /usr/local/bin/snmpd_status.sh
   ```
2. Adicione ao final do `/etc/snmp/snmpd.conf`:
   ```
   extend snmpdControl /usr/local/bin/snmpd_status.sh
   ```
3. Reinicie o SNMPD:
   ```bash
   sudo systemctl restart snmpd
   ```
4. Teste:
   ```bash
   snmpwalk -v2c -c public localhost NET-SNMP-EXTEND-MIB::nsExtendOutputFull."snmpdControl"
   ```

### Opção 2: Usando pass (leitura e escrita)

1. Crie o script de controle:
   Salve como `/usr/local/bin/snmpd_control.sh`:
   ```bash
   #!/bin/bash

   # GET request
   if [ "$1" = "-g" ]; then
     read OID
     echo "$OID"
     echo "integer"
     systemctl is-active snmpd | grep -q running && echo "1" || echo "2"
     exit 0
   fi

   # SET request
   if [ "$1" = "-s" ]; then
     read OID
     read TYPE
     read VALUE
     if [ "$VALUE" = "3" ]; then
        sudo systemctl stop snmpd
       echo "$OID"
       echo "integer"
       echo "2"
     elif [ "$VALUE" = "4" ]; then
        sudo systemctl restart snmpd
       echo "$OID"
       echo "integer"
       echo "1"
      else
       echo "$OID"
       echo "integer"
       echo "1"
      fi
     exit 0
    fi
   ```
   Torne executável:
   ```bash
   sudo chmod +x /usr/local/bin/snmpd_control.sh
   ```
2. Adicione ao final do `/etc/snmp/snmpd.conf`:
   ```
   pass .1.3.6.1.4.1.99999.1 /usr/local/bin/snmpd_control.sh
   ```
3. Reinicie o SNMPD e teste com snmpget/snmpset.

## 2. Expondo Tabela de Processos via SNMP

### Objetivo
Expor uma tabela de processos do sistema operacional via SNMP, utilizando o mecanismo `extend` do Net-SNMP, permitindo que cada processo seja acessado como uma linha separada.

### Passos

1. Crie o script de tabela de processos:
   Salve como `/usr/local/bin/snmpd_proctable.sh`:
   ```bash
   #!/bin/bash
   ps -eo pid,comm,pcpu,pmem,etime --sort=-pcpu | awk 'NR>1 {print $1 "|" $2 "|" $3 "|" $4 "|" $5}'
   ```
   Torne executável:
   ```bash
   sudo chmod +x /usr/local/bin/snmpd_proctable.sh
   ```
2. Adicione ao final do `/etc/snmp/snmpd.conf`:
   ```
   extend proctable /usr/local/bin/snmpd_proctable.sh
   ```
3. Reinicie o SNMPD:
   ```bash
   sudo systemctl restart snmpd
   ```
4. Teste a saída via SNMP:
   Para ver todos os processos em uma string única:
   ```bash
   snmpwalk -v2c -c public localhost NET-SNMP-EXTEND-MIB::nsExtendOutputFull."proctable"
   ```
   Para ver cada processo em uma linha SNMP separada:
   ```bash
   snmpwalk -v2c -c public localhost NET-SNMP-EXTEND-MIB::nsExtendOutLine."proctable"
   ```
   Cada linha terá o formato:
   ```
   PID|NOME|%CPU|%MEM|TEMPO
   ```

### Observações
- Cada processo é exposto como uma linha SNMP separada, facilitando o monitoramento.
- O script pode ser customizado para incluir mais ou menos colunas conforme necessário.
- O mecanismo `extend` é apenas leitura (não permite alterar processos via SNMP).

## 3. Traps SNMP Personalizados

### Objetivo
Criar e testar traps SNMP para notificação de eventos críticos.

### Traps definidos na MIB
- myHighTemperatureTrap (.1.3.6.1.4.1.99999.0.1): Temperatura do equipamento ultrapassou limite seguro (> 70°C)
- myDiskFullTrap (.1.3.6.1.4.1.99999.0.2): Disco/partição atingiu capacidade crítica (> 95% cheio)

### Scripts de envio de traps

1. Envio de trap de alta temperatura:
   Salve como `send_high_temp_trap.sh`:
   ```bash
   #!/bin/bash
   snmptrap -v2c -c public localhost '' .1.3.6.1.4.1.99999.0.1
   ```
   Torne executável:
   ```bash
   chmod +x send_high_temp_trap.sh
   ```
   Execute:
   ```bash
   ./send_high_temp_trap.sh
   ```

2. Envio de trap de disco cheio:
   Salve como `send_disk_full_trap.sh`:
   ```bash
   #!/bin/bash
   snmptrap -v2c -c public localhost '' .1.3.6.1.4.1.99999.0.2
   ```
   Torne executável:
   ```bash
   chmod +x send_disk_full_trap.sh
   ```
   Execute:
   ```bash
   ./send_disk_full_trap.sh
   ```

### Testando o recebimento dos traps

Em outro terminal, rode:
```bash
snmptrapd -f -Lo
```
Assim, você verá as traps recebidas em tempo real.

### Observação sobre snmptrapd e porta alternativa

Se a porta 162 estiver ocupada (por exemplo, pelo systemd), rode o snmptrapd em uma porta alternativa, como 9162:

```bash
sudo snmptrapd -f -Lo -A udp:localhost:9162
```

E envie os traps especificando a porta:

```bash
snmptrap -v2c -c public localhost:9162 '' .1.3.6.1.4.1.99999.0.1
snmptrap -v2c -c public localhost:9162 '' .1.3.6.1.4.1.99999.0.2
```

Para ver detalhes legíveis dos traps, adicione ao arquivo `/etc/snmp/snmptrapd.conf`:

```
authCommunity   log,execute,net  public
```

Depois reinicie o snmptrapd.

---

### Observação sobre temperatura

O trap myHighTemperatureTrap apenas sinaliza que o limite foi ultrapassado, mas não envia o valor da temperatura. Para enviar o valor, adicione um parâmetro ao comando snmptrap, por exemplo:

```bash
snmptrap -v2c -c public localhost:9162 '' .1.3.6.1.4.1.99999.0.1 .1.3.6.1.4.1.99999.1.1 i 75
```

No exemplo acima, `.1.3.6.1.4.1.99999.1.1` seria um OID para a temperatura atual (crie esse OID na sua MIB se quiser formalizar). O `i 75` indica valor inteiro 75°C.

Se quiser, posso te ajudar a ajustar a MIB e os scripts para enviar o valor da temperatura no trap.

---

Se precisar de mais detalhes ou exemplos, peça!
