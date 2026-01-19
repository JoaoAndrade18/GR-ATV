#!/bin/bash
# Monitora disco e envia trap se > 95%

THRESHOLD=95

while true; do
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Uso do disco: ${disk_usage}%"
    
    if [ $disk_usage -gt $THRESHOLD ]; then
        echo "⚠️  ALERTA! Disco acima de ${THRESHOLD}%!"
        snmptrap -v2c -c public localhost '' \
            .1.3.6.1.4.1.99999.0.2 \
            .1.3.6.1.4.1.99999.1.6 i $disk_usage
        echo "Trap enviado!"
    fi
    
    sleep 10
done