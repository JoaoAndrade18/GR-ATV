#!/bin/bash
# Envia trap de disco cheio

# Obtém uso do disco raiz
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo "Enviando trap de disco cheio: ${disk_usage}% usado"

# Envia trap com percentual de uso
snmptrap -v2c -c public localhost '' \
    .1.3.6.1.4.1.99999.0.2 \
    .1.3.6.1.4.1.99999.1.6 i $disk_usage

echo "Trap enviado!"