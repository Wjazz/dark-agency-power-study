#!/usr/bin/env bash
# Cuenta replicas completadas por celda en output/replicas_<METHOD>.csv
METHOD=${1:-qml}
CSV="output/replicas_${METHOD}.csv"
[ -f "$CSV" ] || { echo "no existe $CSV"; exit 1; }
echo "cell,N,lambda_a,gamma3,replicas_ok"
tail -n +2 "$CSV" | cut -d, -f1-4 | sort -t, -k1,1n | uniq -c | \
  awk '{printf "%s,%s,%s,%s,%s\n",$2,$3,$4,$5,$1}'
