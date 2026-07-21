# =====================================================================
# Runner por lotes del estudio de potencia LMS (modsem). Mismo DGP y modelo
# que power_study_modsem.R (C2: Narc .35 / Mach .20), con dos adiciones
# exigidas por el protocolo Fase 2: %Heywood por celda y lotes.
#   CELLS=decision  -> 6 celdas: la=.40 x g3={.10,.15} x N={300,350,450}
#   CELLS=rest      -> las 24 restantes
#   CELLS=all       -> las 30
#   NREP=<n>        -> replicas por celda (prerregistrado: 1000)
#   CELL_IDX=<i>    -> una sola celda (indice global 1..30; ignora CELLS)
# Uso: CELLS=decision NREP=1000 Rscript R/run_power_cells.R
# Salida: output/power_table_<CELLS|cellIDX>.csv (+ sessionInfo.txt)
# NOTA METRICA: el modelo se identifica por primer indicador, de modo que la
# gamma3 poblacional en la metrica del modelo es G3M = .70*G3/(LA*.75)
# (EA escala .70; alpha escala LA; PEH escala .75). Sesgo y cobertura se
# evaluan contra G3M (sesgo relativo y cobertura son invariantes al reescalado);
# la potencia usa el p-valor del test z, invariante a la metrica.
# =====================================================================
.libPaths(c("~/R/library", .libPaths()))
suppressMessages({library(lavaan); library(modsem)})

Ns  <- c(250,300,350,450,500); LAs <- c(.35,.40,.45); G3s <- c(.10,.15)
NREP <- as.integer(Sys.getenv("NREP", "1000"))
CELLS <- Sys.getenv("CELLS", "decision")
BASESEED <- 53711
G1 <- .30; G2 <- 0; G4 <- .20; APEH <- .10

gen_data <- function(N, LA, G3) {
  S <- matrix(c(1,0,0, 0,1,APEH, 0,APEH,1), 3, byrow=TRUE)
  Z <- MASS::mvrnorm(N, mu=c(0,0,0), Sigma=S)
  Aref<-Z[,1]; alpha<-Z[,2]; PEH<-Z[,3]
  EA <- G1*alpha + G2*Aref + G4*PEH + G3*(alpha*PEH) +
        rnorm(N, 0, sqrt(max(1 - (G1^2+G4^2+G3^2*(1+2*APEH^2)),.05)))
  ld <- function(f,lam,k,pre) { m<-outer(f,rep(lam,k))+matrix(rnorm(N*k,0,sqrt(1-lam^2)),N);
                                colnames(m)<-paste0(pre,1:k); m }
  laN<-.35; laM<-.20   # C2: cargas duales empiricas sobre A_ref
  P<-ld(Aref,.60,7,"p"); Sd<-ld(Aref,.60,7,"s")
  resN<-sqrt(max(1-laN^2-LA^2,.05)); resM<-sqrt(max(1-laM^2-LA^2,.05))
  Ndim<-outer(Aref,rep(laN,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resN),N); colnames(Ndim)<-paste0("n",1:7)
  Mdim<-outer(Aref,rep(laM,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resM),N); colnames(Mdim)<-paste0("m",1:7)
  PEHi<-ld(PEH,.75,3,"peh"); EAi<-ld(EA/sd(EA),.70,13,"ea")
  as.data.frame(cbind(Mdim,Ndim,P,Sd,EAi,PEHi))
}

fit_model <- '
  Aref =~ p1+p2+p3+p4+p5+p6+p7+s1+s2+s3+s4+s5+s6+s7+n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  alpha =~ n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  PEH =~ peh1+peh2+peh3
  EA  =~ ea1+ea2+ea3+ea4+ea5+ea6+ea7+ea8+ea9+ea10+ea11+ea12+ea13
  Aref ~~ 0*alpha
  EA ~ alpha + Aref + PEH + alpha:PEH
'

grid <- expand.grid(G3=G3s, N=Ns, LA=LAs)[, c("N","LA","G3")]  # orden = output/design_matrix.csv (canonico; antes desincronizado con power_study_modsem.R)
dm <- read.csv("output/design_matrix.csv")
stopifnot(nrow(dm) == 30,
          isTRUE(all.equal(grid$N,  dm$N,        check.attributes=FALSE)),
          isTRUE(all.equal(grid$LA, dm$lambda_a, check.attributes=FALSE)),
          isTRUE(all.equal(grid$G3, dm$gamma3,   check.attributes=FALSE)))
CELL_IDX <- Sys.getenv("CELL_IDX", "")
if (nzchar(CELL_IDX)) {
  sel <- seq_len(nrow(grid)) == as.integer(CELL_IDX); CELLS <- paste0("cell", CELL_IDX)
} else {
  sel <- if (CELLS=="decision") with(grid, LA==.40 & N %in% c(300,350,450)) else
         if (CELLS=="rest")     !with(grid, LA==.40 & N %in% c(300,350,450)) else rep(TRUE, nrow(grid))
}
cat(sprintf("CELLS=%s -> %d celdas x %d replicas\n", CELLS, sum(sel), NREP))

res <- data.frame()
for (r in which(sel)) {
  N<-grid$N[r]; LA<-grid$LA[r]; G3<-grid$G3[r]
  G3M <- .70*G3/(LA*.75)       # gamma3 poblacional en la metrica del modelo
  set.seed(BASESEED + r*101)   # semilla por INDICE GLOBAL de celda: reproducible entre lotes
  p<-numeric(NREP); est<-numeric(NREP); se<-numeric(NREP)
  cov95<-logical(NREP); ok<-logical(NREP); hey<-logical(NREP)
  t0 <- proc.time()["elapsed"]
  for (rep in seq_len(NREP)) {
    dat <- tryCatch(gen_data(N,LA,G3), error=function(e) NULL)
    if (is.null(dat)) { ok[rep]<-FALSE; next }
    f <- tryCatch(suppressWarnings(modsem::modsem(fit_model, dat, method="lms")),
                  error=function(e) NULL)
    if (is.null(f)) { ok[rep]<-FALSE; next }
    pe <- tryCatch(modsem::parameter_estimates(f), error=function(e) NULL)
    if (is.null(pe)) { ok[rep]<-FALSE; next }
    secol <- grep("std\\.?error|^se$", names(pe), ignore.case=TRUE, value=TRUE)[1]
    pcol  <- grep("^p\\.?value|^pvalue|Pr", names(pe), ignore.case=TRUE, value=TRUE)[1]
    if (is.na(secol) || is.na(pcol)) { ok[rep]<-FALSE; next }
    # Heywood: varianza residual negativa en cualquier item o latente
    vr <- pe[pe$op=="~~" & pe$lhs==pe$rhs, "est"]
    hey[rep] <- any(is.finite(vr) & vr < 0)
    row <- pe[pe$lhs=="EA" & pe$op=="~" & grepl("alpha.*PEH|PEH.*alpha|int", pe$rhs),]
    if (nrow(row)==0) { ok[rep]<-FALSE; next }
    est[rep]<-row$est[1]; se[rep]<-row[[secol]][1]; p[rep]<-row[[pcol]][1]
    ci <- est[rep]+c(-1,1)*1.96*se[rep]; cov95[rep]<-(G3M>=ci[1] & G3M<=ci[2]); ok[rep]<-TRUE
  }
  v <- ok & is.finite(p)
  res <- rbind(res, data.frame(
    N=N, lambda_a=LA, gamma3=G3, gamma3_metrica_modelo=round(G3M,4),
    conv_rate=mean(ok), pct_heywood=mean(hey[ok]),
    power=mean(p[v]<.05), bias_rel=mean(est[v])/G3M - 1, mean_SE=mean(se[v]),
    coverage=mean(cov95[v]), n_valid=sum(v),
    fiable=ifelse(mean(ok)>=.95 & mean(hey[ok])<=.05, "SI", "NO-CONFIABLE"),
    min_por_celda=round((proc.time()["elapsed"]-t0)/60,1)))
  cat(sprintf("N=%d la=%.2f g3=%.2f | power=%.3f conv=%.2f hey=%.2f bias_rel=%+.3f cov=%.2f | %.1f min\n",
              N,LA,G3,res$power[nrow(res)],res$conv_rate[nrow(res)],res$pct_heywood[nrow(res)],
              res$bias_rel[nrow(res)],res$coverage[nrow(res)],res$min_por_celda[nrow(res)]))
  write.csv(res, sprintf("output/power_table_%s.csv", CELLS), row.names=FALSE)  # checkpoint
}
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
cat("LOTE COMPLETO:", CELLS, "\n")
