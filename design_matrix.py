#!/usr/bin/env python3
# Matriz de diseno + omega_HS(alpha) ANALITICO. omega_HS se calcula desde las cargas
# (no es resultado LMS). C2 resuelto (Opcion 1 re-anclada): cargas duales sobre A_ref
# ANCLADAS en correlaciones interfactoriales publicadas de la SD4:
#   Narc<->nucleo r~.35 -> lambda_A(Narc)=.35 ; Mach<->nucleo r~.25 -> lambda_A(Mach)=.20
#   (Blotner 2021 Tabla 1; Bajcsi 2025 Tabla 4; Zegarra-Lopez 2024 al reportar su matriz).
# NO se adopta Opcion 2 (inflar lambda_alpha): seria razonamiento motivado.
import pandas as pd, itertools, os
Ns=[250,300,350,450,500]; LAs=[.35,.40,.45]; G3s=[.10,.15]; n=14

def omegaHS(lam_alpha, lamA_narc, lamA_mach):
    # 7 items Narc + 7 items Mach; alpha homogeneo por banda
    sum_la = n*lam_alpha
    sumA   = 7*lamA_narc + 7*lamA_mach
    sumA2  = 7*lamA_narc**2 + 7*lamA_mach**2
    theta  = n - sumA2 - n*lam_alpha**2
    return (sum_la**2)/((sum_la**2) + sumA**2 + theta)

def omegaHS_hom(lam_alpha, lamA):     # banda de sensibilidad: lamA homogeneo
    return omegaHS(lam_alpha, lamA, lamA)

def lamA_critico(lam_alpha):          # frontera: lamA_dual homogeneo donde omegaHS=.40
    return ((22*lam_alpha**2 - 1)/13)**0.5

# --- MODELO CENTRAL (empirico heterogeneo Narc .35 / Mach .20): regla de decision de N ---
rows=[]
for LA in LAs:
    w=omegaHS(LA,.35,.20)
    for N,G3 in itertools.product(Ns,G3s):
        rows.append(dict(banda="central_empirico", N=N, lambda_a=LA, gamma3=G3,
                         lamA_narc=.35, lamA_mach=.20, omegaHS_alpha=round(w,3),
                         alpha_viable="SI" if w>=.40 else "NO",
                         power="PENDIENTE: correr LMS"))
central=pd.DataFrame(rows)

# --- BANDA DE SENSIBILIDAD DE CONSTRUCTO (lamA=.45 homogeneo): NO entra en regla de N ---
sens=pd.DataFrame([dict(banda="sensibilidad_alpha_fragil", lambda_a=LA, lamA_dual=.45,
                        omegaHS_alpha=round(omegaHS_hom(LA,.45),3),
                        estatus="alpha fragil/muerto (robustez, no decision N)")
                   for LA in LAs])

# --- FRONTERA DE VIABILIDAD (analitica, independiente de la corrida) ---
front=pd.DataFrame([dict(lambda_a=LA, lamA_dual_critico=round(lamA_critico(LA),3),
                         lectura="alpha vive si lamA_dual <= critico")
                    for LA in LAs])

base=os.path.dirname(os.path.abspath(__file__)); out=os.path.join(base,"output")
os.makedirs(out,exist_ok=True)
central.to_csv(os.path.join(out,"design_matrix.csv"),index=False)
sens.to_csv(os.path.join(out,"banda_sensibilidad.csv"),index=False)
front.to_csv(os.path.join(out,"frontera_viabilidad.csv"),index=False)

print("=== MODELO CENTRAL — omegaHS(alpha) por banda (Narc .35 / Mach .20) ===")
for LA in LAs: print(f"  lambda_a={LA}: omegaHS={omegaHS(LA,.35,.20):.3f}  -> alpha VIABLE")
print("\n=== BANDA SENSIBILIDAD (lamA=.45 hom, 'alpha fragil') ===")
print(sens.to_string(index=False))
print("\n=== FRONTERA DE VIABILIDAD (lamA_dual critico donde omegaHS=.40) ===")
print(front.to_string(index=False))
print("\nRegla de N: menor N con potencia>=.80 para gamma3 en pesimista realista")
print("lambda_a=.40, gamma3=.10, cargas duales empiricas (omegaHS=.552, alpha viable).")
