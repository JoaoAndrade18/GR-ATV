#!/bin/bash
# Monitora temperatura e envia trap se > 70°C

THRESHOLD=70

while true; do
    if command -v sensors &> /dev/null; then
        temp=$(sensors k10temp-pci-00c3 2>/dev/null | grep 'Tctl:' | awk '{print $2}' | sed 's/+//;s/°C//' | cut -d. -f1)
        temp_celsius=$((temp))
    else
        # Simula temperatura variável para teste
       temp_celsius=$((0))
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Temperatura: ${temp_celsius}°C"
    
    if [ $temp_celsius -gt $THRESHOLD ]; then
        echo "⚠️  ALERTA! Temperatura acima de ${THRESHOLD}°C!"
        snmptrap -v2c -c public localhost '' \
            .1.3.6.1.4.1.99999.0.1 \
            .1.3.6.1.4.1.99999.1.5 i $temp_celsius
        echo "Trap enviado!"
    fi
    
    sleep 1
done