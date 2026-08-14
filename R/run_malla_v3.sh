#!/usr/bin/env bash
# =====================================================================
# Driver de la malla ampliada v3 (dos interacciones latentes), brazo P.
# Paraleliza por celda; cada celda escribe su propio CSV y es reanudable:
# relanzar el script salta las celdas ya hechas.
# Orden = valor decisorio, no orden de la malla.
# Uso: NREP=300 WORKERS=6 bash R/run_malla_v3.sh
# =====================================================================
set -u
cd "$(dirname "$0")/.."
NREP="${NREP:-300}"
WORKERS="${WORKERS:-6}"
mkdir -p output/v3 logs/v3

# ---------------------------------------------------------------------
# OBLIGATORIO: un hilo de BLAS por proceso.
# Sin esto, cada worker de R abre su propio banco de hilos BLAS y N workers
# x 8 hilos saturan la maquina. Medido el 31-jul: 4.1 s/replica con 1 hilo
# frente a ~1500 s/replica con BLAS multihilo y 6 workers (factor ~400).
# El paralelismo va POR CELDA, nunca dentro de la celda.
# ---------------------------------------------------------------------
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
       GOTO_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1

# Bloque A (ancla: comparacion directa 1int vs 2int) -> B (cruce g3=.15)
# -> C (acotar g3=.10) -> D (lambda pesimista .35) -> E (lambda optimista .45)
ORDEN="31 32 33 34 35 36 39 37 38 40 41 42 43 44 45 46"

echo "MALLA v3 | NREP=$NREP | WORKERS=$WORKERS | inicio $(date -Is)"
printf '%s\n' $ORDEN | xargs -P "$WORKERS" -I{} sh -c \
  'CELL_IDX={} NREP='"$NREP"' METHOD=qml Rscript R/run_cell_v3_2int.R > logs/v3/cell_{}.log 2>&1; \
   echo "[fin celda {}] $(date +%H:%M:%S)"'

echo "MALLA v3 COMPLETA $(date -Is)"
Rscript R/summarize_v3.R
