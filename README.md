# SNMPD Custom Control e Tabela de Processos

## requisitos

- snmpd
- snmpdtrap
- snmpwalk
- snmpget
- snmpset
- mib browser - iReasoning MIB Browser

```bash
sudo apt update
sudo apt install -y \
  snmp \
  snmpd \
  snmptrapd \
  snmp-mibs-downloader
```

### IMPORTANTE - Ajuste os monitores para que coletem a temperatura corretamente de acordo com seu sistema, ajuste tambem o snmp_control.sh caso queira visualizar via snmp.

## 1. Controle e Status do Serviço SNMPD via SNMP

### Usando pass (leitura e escrita)

1. crie ou edite o arquivo: `/usr/local/bin/snmpd_control.sh`:
   
   Cole o conteúdo de `snmpd_control.sh`.

   Torne executável:
   ```bash
   sudo chmod +x /usr/local/bin/snmpd_control.sh
   ```

2. Edite o arquivo: `/etc/snmp/snmpd.conf`:
   
   Cole o conteúdo de `snmpd.conf`

3. Reinicie o SNMPD e teste com snmpwalk:
   ```bash
   snmpwalk -v2c -c public localhost .1.3.6.1.4.1.99999.1.1
   ```

4. Colete os dados de uptime:
   ```bash
   snmpget -v2c -c public localhost .1.3.6.1.4.1.99999.1.1.3.0
   ```

5. Reinicie o snmp:
   ```bash
   snmpset -v2c -c public localhost .1.3.6.1.4.1.99999.1.1.2.0 i 2
   ```

5. Colete os dados de uptime novamente:
   ```bash
   snmpget -v2c -c public localhost .1.3.6.1.4.1.99999.1.1.3.0
   ```

## 2. Expondo Tabela de Processos via SNMP

### Objetivo
Expor uma tabela de processos do sistema operacional via SNMP, utilizando o mecanismo `extend` do Net-SNMP, permitindo que cada processo seja acessado como uma linha separada.

#### Teste a saída via SNMP:
   Para ver cada processo SNMP:
   ```bash
   snmpwalk -v2c -c public localhost .1.3.6.1.4.1.99999.2
   ```
   Cada linha terá o formato:
   ```
   PID|NOME|%CPU|%MEM|UPTIME
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
   Use `send_high_temp_trap.sh`:

   Torne executável:
   ```bash
   chmod +x send_high_temp_trap.sh
   ```
   Execute:
   ```bash
   ./send_high_temp_trap.sh
   ```

2. Envio de trap de disco cheio:
   Use `send_disk_full_trap.sh`:
   
   Torne executável:
   ```bash
   chmod +x send_disk_full_trap.sh
   ```
   Execute:
   ```bash
   ./send_disk_full_trap.sh
   ```

### Implementando o recebimento dos traps

Em outro terminal, rode:
```bash
sudo snmptrapd -f -Lo -m CUSTOM-CONTROL-MIB
```
Assim, você verá as traps recebidas em tempo real.

### Observação sobre snmptrapd e porta alternativa

Se a porta 162 estiver ocupada (por exemplo, pelo systemd), mate todos os processos e para o servico do snmptrapd.

```bash
sudo lsof -i :162
```
Se existir o processo use:

```bash
sudo systemctl stop snmptrapd
sudo systemctl disable snmptrapd
```
Se ainda n funcionar e existir o serviço usando, pare ele:
```bash
sudo systemctl stop snmptrapd.socket
sudo systemctl stop snmptrapd.service
sudo systemctl disable snmptrapd.socket
sudo systemctl disable snmptrapd.service
```

2. Adicione ao arquivo `/etc/snmp/snmptrapd.conf`:

O conteúdo de `snmptrapd.conf`
---

### Observação sobre temperatura

O trap myHighTemperatureTrap apenas sinaliza que o limite foi ultrapassado, mas não envia o valor da temperatura. Para enviar o valor, adicione um parâmetro ao comando snmptrap, por exemplo:

```bash
snmptrap -v2c -c public localhost '' .1.3.6.1.4.1.99999.0.1 .1.3.6.1.4.1.99999.1.5 i 75
```

## Monitoramento e atuação das traps.
Nessa seção usaremos um script que coleta os dados do dispositivo e envia traps para a mib caso ultrapasse um limiar.

### Temperatura
   Torne executável:
   ```bash
   chmod +x monitor_temperature.sh
   ```
   Execute:
   ```bash
   ./monitor_temperature.sh
   ```

### Disco
   Torne executável:
   ```bash
   chmod +x monitor_disk.sh
   ```
   Execute:
   ```bash
   ./monitor_disk.sh
   ```

### Observação
Utilize um teste de estresse para aumentar a temperatura, e faça algo que diminua seu espaço livre no disco...
exemplo:
```bash
sudo apt install stress-ng   
stress-ng --cpu 10 --timeout 60s   
```
