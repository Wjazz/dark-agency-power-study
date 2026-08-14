# =====================================================================
# BRAZO P · v3 — MALLA AMPLIADA CON LA SEGUNDA INTERACCION LATENTE
# ---------------------------------------------------------------------
# Motivo de esta corrida (v8 §3.2.3 h): la corrida de julio estimo un modelo
# con UNA interaccion latente (alpha:PEH sobre EA). El modelo declarado en
# v8 §2.8 tiene DOS: la ec.(2) anade alpha:FORM sobre EB (H4). Por tanto la
# tabla de julio es COTA SUPERIOR de la potencia disponible para gamma3, y
# para gamma11 no existia estimacion alguna. Esta corrida la produce.
#
# Ejecuta UNA celda (CELL_IDX) y escribe output/v3/cell_<idx>.csv.
# Disenado para paralelizar por celda (xargs -P) y para ser reanudable:
# si el CSV de la celda existe, no la recalcula.
#
# CONTINUIDAD DE SEMILLA (PROMPT_SIMULACION_v2 §8): BASESEED = 53711,
# semilla por celda = BASESEED + idx*101, con idx GLOBAL. Las celdas de
# julio ocupan 1..30; estas EXTIENDEN el esquema desde 31 y no lo reinician.
#
# METRICA DEL MODELO (identificacion por primer indicador):
#   G3M  = .70*G3 /(LA*.75)   [EA escala .70; alpha escala LA; PEH escala .75]
#   G11M = .70*G11/(LA*1  )   [EB escala .70; alpha escala LA; FORM observada, escala 1]
# Sesgo y cobertura se evaluan contra la metrica del modelo; la potencia usa
# el p-valor del test z, invariante al reescalado.
# =====================================================================
.libPaths(c("~/R/library", .libPaths()))
suppressMessages({library(lavaan); library(modsem)})

BASESEED <- 53711
NREP   <- as.integer(Sys.getenv("NREP", "300"))
METHOD <- Sys.getenv("METHOD", "qml")
IDX    <- as.integer(Sys.getenv("CELL_IDX", "31"))

# --- DGP: parametros estructurales -----------------------------------
# Ec.(1) heredada de la corrida de julio, sin cambios:
G1 <- .30; G2 <- 0; G4 <- .20; APEH <- .10
# Ec.(2) NUEVA (v8 §2.8). Valores declarados por este script, no heredados
# de ninguna corrida previa: son decisiones del simulador y se reportan como
# tales en el README, no como hechos poblacionales.
G5  <- .20   # alpha -> EB (directo)
G6  <- 0     # Aref  -> EB (nulo por la hipotesis de disociacion, igual que G2)
B1  <- .30   # EA    -> EB (mediacion; misma magnitud que G1)
G12 <- .15   # FORM  -> EB (efecto principal del moderador: principio de jerarquia)
AFORM <- as.numeric(Sys.getenv("AFORM", "0"))   # corr(FORM, PEH); 0 en la corrida primaria

# --- Malla ampliada (indices globales 31+) ----------------------------
# Bloque F anadido el 1-ago tras cerrar A-E: el escenario que manda la regla
# de decision (la=.40, g3=.10) no cruza .80 en N<=900. La rama obligatoria del
# PROMPT_SIMULACION_v2 §2 es EXTENDER hasta acotar el cruce, no extrapolar.
grid <- data.frame(
  idx = 31:49,
  N   = c(350,350,450,450, 550,700,900, 550,700,900, 450,450,700,700, 450,700, 1100,1300,1500),
  LA  = c(.40,.40,.40,.40, .40,.40,.40, .40,.40,.40, .35,.35,.35,.35, .45,.45, .40,.40,.40),
  G3  = c(.10,.15,.10,.15, .15,.15,.15, .10,.10,.10, .10,.15,.10,.15, .10,.10, .10,.10,.10),
  G11 = c(-.10,-.15,-.10,-.15, -.15,-.15,-.15, -.10,-.10,-.10, -.10,-.15,-.10,-.15, -.10,-.10, -.10,-.10,-.10),
  bloque = c(rep("A_ancla_comparacion",4), rep("B_extension_N_g3_15",3),
             rep("C_acotar_g3_10",3), rep("D_lambda_pesimista_35",4),
             rep("E_lambda_optimista_45",2), rep("F_acotar_cruce_g3_10",3)),
  stringsAsFactors = FALSE)

row <- grid[grid$idx == IDX, ]
if (nrow(row) != 1) stop("CELL_IDX fuera de la malla v3 (31..49)")
N <- row$N; LA <- row$LA; G3 <- row$G3; G11 <- row$G11

OUTDIR <- Sys.getenv("OUTDIR", "output/v3")   # OUTDIR=output/bench para mediciones
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)
outfile <- sprintf("%s/cell_%02d.csv", OUTDIR, IDX)
if (file.exists(outfile)) { cat("YA HECHA:", outfile, "\n"); quit(save="no") }

gen_data <- function(N, LA, G3, G11) {
  S <- diag(4)
  S[2,3] <- S[3,2] <- APEH          # alpha ~ PEH  (unica correlacion exogena heredada)
  S[4,3] <- S[3,4] <- AFORM         # FORM  ~ PEH  (0 en la corrida primaria)
  Z <- MASS::mvrnorm(N, mu=rep(0,4), Sigma=S)
  Aref<-Z[,1]; alpha<-Z[,2]; PEH<-Z[,3]; FORM<-Z[,4]

  vEA <- max(1 - (G1^2 + G4^2 + G3^2*(1+2*APEH^2)), .05)
  EA  <- G1*alpha + G2*Aref + G4*PEH + G3*(alpha*PEH) + rnorm(N,0,sqrt(vEA))
  EAs <- EA/sd(EA)
  vEB <- max(1 - (G5^2 + B1^2 + G12^2 + G11^2), .05)
  EB  <- G5*alpha + G6*Aref + B1*EAs + G12*FORM + G11*(alpha*FORM) + rnorm(N,0,sqrt(vEB))

  ld <- function(f,lam,k,pre){ m<-outer(f,rep(lam,k))+matrix(rnorm(N*k,0,sqrt(1-lam^2)),N)
                               colnames(m)<-paste0(pre,1:k); m }
  laN<-.35; laM<-.20                # C2: cargas duales empiricas (Blotner 2021; Bajcsi 2025)
  P<-ld(Aref,.60,7,"p"); Sd<-ld(Aref,.60,7,"s")
  resN<-sqrt(max(1-laN^2-LA^2,.05)); resM<-sqrt(max(1-laM^2-LA^2,.05))
  Ndim<-outer(Aref,rep(laN,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resN),N); colnames(Ndim)<-paste0("n",1:7)
  Mdim<-outer(Aref,rep(laM,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resM),N); colnames(Mdim)<-paste0("m",1:7)
  PEHi<-ld(PEH,.75,3,"peh"); EAi<-ld(EAs,.70,13,"ea"); EBi<-ld(EB/sd(EB),.70,10,"eb")
  as.data.frame(cbind(Mdim,Ndim,P,Sd,EAi,PEHi,EBi,form=FORM))
}

fit_model <- '
  Aref =~ p1+p2+p3+p4+p5+p6+p7+s1+s2+s3+s4+s5+s6+s7+n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  alpha =~ n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  PEH =~ peh1+peh2+peh3
  EA  =~ ea1+ea2+ea3+ea4+ea5+ea6+ea7+ea8+ea9+ea10+ea11+ea12+ea13
  EB  =~ eb1+eb2+eb3+eb4+eb5+eb6+eb7+eb8+eb9+eb10
  FORM =~ 1*form
  form ~~ 0*form
  Aref ~~ 0*alpha
  EA ~ alpha + Aref + PEH + alpha:PEH
  EB ~ alpha + Aref + EA + FORM + alpha:FORM
'

G3M  <- .70*G3 /(LA*.75)
G11M <- .70*G11/(LA*1)

set.seed(BASESEED + IDX*101)
n <- NREP
p3<-e3<-s3<-numeric(n); c3<-logical(n)
p11<-e11<-s11<-numeric(n); c11<-logical(n)
ok<-hey<-logical(n); tt<-numeric(n)

cat(sprintf("[celda %d] N=%d la=%.2f g3=%.2f g11=%.2f | %s | %d reps\n",
            IDX, N, LA, G3, G11, METHOD, n))
t00 <- proc.time()["elapsed"]
for (r in seq_len(n)) {
  t0 <- proc.time()["elapsed"]
  dat <- tryCatch(gen_data(N,LA,G3,G11), error=function(e) NULL)
  if (is.null(dat)) { ok[r]<-FALSE; next }
  f <- tryCatch(suppressWarnings(modsem::modsem(fit_model, dat, method=METHOD)),
                error=function(e) NULL)
  if (is.null(f)) { ok[r]<-FALSE; tt[r]<-proc.time()["elapsed"]-t0; next }
  pe <- tryCatch(modsem::parameter_estimates(f), error=function(e) NULL)
  if (is.null(pe)) { ok[r]<-FALSE; tt[r]<-proc.time()["elapsed"]-t0; next }
  secol <- grep("std\\.?error|^se$", names(pe), ignore.case=TRUE, value=TRUE)[1]
  pcol  <- grep("^p\\.?value|^pvalue|Pr", names(pe), ignore.case=TRUE, value=TRUE)[1]
  if (is.na(secol) || is.na(pcol)) { ok[r]<-FALSE; tt[r]<-proc.time()["elapsed"]-t0; next }
  vr <- pe[pe$op=="~~" & pe$lhs==pe$rhs, "est"]
  hey[r] <- any(is.finite(vr) & vr < 0)
  r3  <- pe[pe$op=="~" & pe$lhs=="EA" & grepl("alpha.*PEH|PEH.*alpha",  pe$rhs), ]
  r11 <- pe[pe$op=="~" & pe$lhs=="EB" & grepl("alpha.*FORM|FORM.*alpha", pe$rhs), ]
  if (nrow(r3)==0 || nrow(r11)==0) { ok[r]<-FALSE; tt[r]<-proc.time()["elapsed"]-t0; next }
  e3[r]<-r3$est[1];  s3[r]<-r3[[secol]][1];  p3[r]<-r3[[pcol]][1]
  e11[r]<-r11$est[1]; s11[r]<-r11[[secol]][1]; p11[r]<-r11[[pcol]][1]
  ci3 <- e3[r]+c(-1,1)*1.96*s3[r];   c3[r]  <- (G3M >=ci3[1]  & G3M <=ci3[2])
  ci11<- e11[r]+c(-1,1)*1.96*s11[r]; c11[r] <- (G11M>=ci11[1] & G11M<=ci11[2])
  ok[r]<-TRUE; tt[r]<-proc.time()["elapsed"]-t0
  if (r %% 25 == 0) cat(sprintf("   ... %d/%d (%.1f min)\n", r, n, (proc.time()["elapsed"]-t00)/60))
}

v <- ok & is.finite(p3) & is.finite(p11)
mc_se <- function(pw, k) sqrt(pw*(1-pw)/k)          # error Monte Carlo de la potencia
pw3 <- mean(p3[v]<.05); pw11 <- mean(p11[v]<.05); k <- sum(v)

res <- data.frame(
  cell=IDX, bloque=row$bloque, N=N, lambda_a=LA, gamma3=G3, gamma11=G11,
  n_interacciones=2, method=METHOD, n_rep=n, n_valid=k,
  conv_rate=mean(ok), pct_heywood=mean(hey[ok]),
  # --- gamma3 (alpha x PEH -> EA), H3
  g3_metrica_modelo=round(G3M,4), power_g3=pw3,
  mc_se_g3=round(mc_se(pw3,k),4),
  power_g3_ic_lo=round(max(0,pw3-1.96*mc_se(pw3,k)),4),
  power_g3_ic_hi=round(min(1,pw3+1.96*mc_se(pw3,k)),4),
  bias_abs_g3=mean(e3[v])-G3M, bias_rel_g3=mean(e3[v])/G3M-1,
  emp_SE_g3=sd(e3[v]), mean_SE_g3=mean(s3[v]),
  razon_SE_g3=round(mean(s3[v])/sd(e3[v]),3), coverage_g3=mean(c3[v]),
  # --- gamma11 (alpha x FORM -> EB), H4  [SIN ESTIMACION PREVIA EN EL REPO]
  g11_metrica_modelo=round(G11M,4), power_g11=pw11,
  mc_se_g11=round(mc_se(pw11,k),4),
  power_g11_ic_lo=round(max(0,pw11-1.96*mc_se(pw11,k)),4),
  power_g11_ic_hi=round(min(1,pw11+1.96*mc_se(pw11,k)),4),
  bias_abs_g11=mean(e11[v])-G11M, bias_rel_g11=mean(e11[v])/G11M-1,
  emp_SE_g11=sd(e11[v]), mean_SE_g11=mean(s11[v]),
  razon_SE_g11=round(mean(s11[v])/sd(e11[v]),3), coverage_g11=mean(c11[v]),
  seg_por_replica=round(mean(tt[tt>0]),2), min_por_celda=round((proc.time()["elapsed"]-t00)/60,1),
  fiable=ifelse(mean(ok)>=.95 & mean(hey[ok])<=.05, "SI", "NO-CONFIABLE"),
  corr_FORM_PEH=AFORM, stringsAsFactors=FALSE)

write.csv(res, outfile, row.names=FALSE)
saveRDS(data.frame(rep=seq_len(n), ok=ok, hey=hey, e3=e3, s3=s3, p3=p3,
                   e11=e11, s11=s11, p11=p11, seg=tt),
        sprintf("%s/replicas_cell_%02d.rds", OUTDIR, IDX))
cat(sprintf("[celda %d] LISTA | pot_g3=%.3f pot_g11=%.3f | conv=%.2f hey=%.2f | %.1f min\n",
            IDX, pw3, pw11, mean(ok), mean(hey[ok]), res$min_por_celda))
