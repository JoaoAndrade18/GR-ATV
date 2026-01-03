#!/bin/bash
# Envia trap de alta temperatura
snmptrap -v2c -c public localhost '' .1.3.6.1.4.1.99999.0.1
