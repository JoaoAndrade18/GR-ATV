#!/bin/bash
# Envia trap de alta temperatura

# Obtém temperatura da CPU (se disponível)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp_celsius=$((temp / 1000))
else
    # Temperatura simulada para teste
    temp_celsius=75
fi

echo "Enviando trap de alta temperatura: ${temp_celsius}°C"

# Envia trap com valor da temperatura
snmptrap -v2c -c public localhost '' \
    .1.3.6.1.4.1.99999.0.1 \
    .1.3.6.1.4.1.99999.1.5 i $temp_celsius

echo "Trap enviado!"