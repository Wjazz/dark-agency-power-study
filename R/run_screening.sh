#!/usr/bin/env bash
# Etapa de screening: QML, R=300, 6 celdas de decision (la=.40 x g3={.10,.15} x N={300,350,450}).
# Morris et al. 2019 (R por EMC); Klein & Muthen 2007 (QML). Reanudable: re-ejecutar salta
# replicas ya escritas en output/replicas_qml.csv.
mkdir -p output logs
METHOD=qml NREP=300 CELLS=decision nohup Rscript R/power_study_modsem.R > logs/screening.log 2>&1 &
echo "screening lanzado, PID $!"
