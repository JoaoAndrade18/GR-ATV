#!/bin/bash

OID_BASE=".1.3.6.1.4.1.99999.1.1"

if [ "$1" = "-g" ]; then
    case "$2" in
        "${OID_BASE}.1.0") echo "${OID_BASE}.1.0"; echo "integer"; systemctl is-active --quiet snmpd && echo "1" || echo "2" ;;
        "${OID_BASE}.2.0") echo "${OID_BASE}.2.0"; echo "integer"; echo "0" ;;
        "${OID_BASE}.3.0") echo "${OID_BASE}.3.0"; echo "string"; systemctl show snmpd --property=ActiveEnterTimestamp --value 2>/dev/null | head -1 ;;
        "${OID_BASE}.4.0") echo "${OID_BASE}.4.0"; echo "string"; snmpd -v 2>&1 | head -1 | awk '{print $3}' ;;
    esac
elif [ "$1" = "-n" ]; then
    case "$2" in
        ".1.3.6.1.4.1.99999.1"|"${OID_BASE}") echo "${OID_BASE}.1.0"; echo "integer"; systemctl is-active --quiet snmpd && echo "1" || echo "2" ;;
        "${OID_BASE}.1.0") echo "${OID_BASE}.2.0"; echo "integer"; echo "0" ;;
        "${OID_BASE}.2.0") echo "${OID_BASE}.3.0"; echo "string"; systemctl show snmpd --property=ActiveEnterTimestamp --value 2>/dev/null | head -1 ;;
        "${OID_BASE}.3.0") echo "${OID_BASE}.4.0"; echo "string"; snmpd -v 2>&1 | head -1 | awk '{print $3}' ;;
    esac
elif [ "$1" = "-s" ]; then
    OID="$2"; VALUE="$4"
    echo "$(date): SET OID=$OID VALUE=$VALUE" >> /tmp/snmp_set.log
    if [ "$OID" = "${OID_BASE}.2.0" ]; then
        case "$VALUE" in
            1) (sleep 1; sudo systemctl stop snmpd) & ;;
            2) (sleep 1; sudo systemctl restart snmpd) & ;;
            3) (sleep 1; sudo systemctl start snmpd) & ;;
        esac
    fi
elif [ "$1" = "get_table" ]; then
    # Saída para a Tarefa #02
    ps -eo pid,comm,%cpu,rss,etime --sort=-%cpu | head -n 11 | tail -n +2 | while read pid name cpu mem uptime; do
        mem_mb=$(echo "$mem / 1024" | bc)
        echo "$pid|$name|$cpu|$mem_mb|$uptime"
    done
fi