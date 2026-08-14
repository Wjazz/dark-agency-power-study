# =====================================================================
# PILOTO DE TIEMPO — modelo de DOS interacciones latentes (brazo P v3)
# Objetivo: medir coste por replica antes de comprometer la malla ampliada.
# No produce potencia. Solo tiempo, convergencia y recuperacion de parametros.
# =====================================================================
.libPaths(c("~/R/library", .libPaths()))
suppressMessages({library(lavaan); library(modsem)})

# --- Parametros del DGP -----------------------------------------------
# Ec.(1) EA ~ alpha + Aref + PEH + alpha:PEH   [heredado de la corrida de julio]
G1 <- .30; G2 <- 0; G4 <- .20; APEH <- .10
# Ec.(2) EB ~ alpha + Aref + EA + FORM + alpha:FORM   [NUEVO — v8 §2.8 ec. 2]
G5 <- .20   # alpha -> EB   (directo)
G6 <- 0     # Aref  -> EB   (nulo por hipotesis de disociacion, como G2)
B1 <- .30   # EA    -> EB   (mediacion)
G12 <- .15  # FORM  -> EB   (efecto principal del moderador; jerarquia)
AFORM <- 0  # corr(FORM, resto) = 0 en la corrida primaria

gen_data <- function(N, LA, G3, G11) {
  # latentes: Aref, alpha, PEH, FORM
  S <- diag(4)
  S[2,3] <- S[3,2] <- APEH          # alpha ~ PEH
  S[4,3] <- S[3,4] <- AFORM         # FORM ~ PEH
  Z <- MASS::mvrnorm(N, mu=rep(0,4), Sigma=S)
  Aref<-Z[,1]; alpha<-Z[,2]; PEH<-Z[,3]; FORM<-Z[,4]

  vEA <- max(1 - (G1^2 + G4^2 + G3^2*(1+2*APEH^2)), .05)
  EA <- G1*alpha + G2*Aref + G4*PEH + G3*(alpha*PEH) + rnorm(N,0,sqrt(vEA))
  EAs <- EA/sd(EA)
  vEB <- max(1 - (G5^2 + B1^2 + G12^2 + G11^2), .05)
  EB <- G5*alpha + G6*Aref + B1*EAs + G12*FORM + G11*(alpha*FORM) + rnorm(N,0,sqrt(vEB))

  ld <- function(f,lam,k,pre){ m<-outer(f,rep(lam,k))+matrix(rnorm(N*k,0,sqrt(1-lam^2)),N)
                               colnames(m)<-paste0(pre,1:k); m }
  laN<-.35; laM<-.20
  P<-ld(Aref,.60,7,"p"); Sd<-ld(Aref,.60,7,"s")
  resN<-sqrt(max(1-laN^2-LA^2,.05)); resM<-sqrt(max(1-laM^2-LA^2,.05))
  Ndim<-outer(Aref,rep(laN,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resN),N); colnames(Ndim)<-paste0("n",1:7)
  Mdim<-outer(Aref,rep(laM,7))+outer(alpha,rep(LA,7))+matrix(rnorm(N*7,0,resM),N); colnames(Mdim)<-paste0("m",1:7)
  PEHi<-ld(PEH,.75,3,"peh"); EAi<-ld(EAs,.70,13,"ea")
  EBi<-ld(EB/sd(EB),.70,10,"eb")           # IEO, 10 items (v8 §3.3.3)
  form <- FORM                              # indice registral estandarizado (v8 §3.3.7): observado
  as.data.frame(cbind(Mdim,Ndim,P,Sd,EAi,PEHi,EBi,form=form))
}

fit_1int <- '
  Aref =~ p1+p2+p3+p4+p5+p6+p7+s1+s2+s3+s4+s5+s6+s7+n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  alpha =~ n1+n2+n3+n4+n5+n6+n7+m1+m2+m3+m4+m5+m6+m7
  PEH =~ peh1+peh2+peh3
  EA  =~ ea1+ea2+ea3+ea4+ea5+ea6+ea7+ea8+ea9+ea10+ea11+ea12+ea13
  Aref ~~ 0*alpha
  EA ~ alpha + Aref + PEH + alpha:PEH
'

fit_2int <- '
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

METHOD <- Sys.getenv("METHOD", "qml")
NPIL   <- as.integer(Sys.getenv("NPIL", "3"))
set.seed(53711)
for (N in c(350, 700)) {
  for (lab in c("1int","2int")) {
    mod <- if (lab=="1int") fit_1int else fit_2int
    cat(sprintf("\n--- N=%d | %s | metodo=%s ---\n", N, lab, METHOD))
    for (i in seq_len(NPIL)) {
      d <- gen_data(N, .40, .15, -.15)
      t0 <- proc.time()["elapsed"]
      f <- tryCatch(suppressWarnings(modsem::modsem(mod, d, method=METHOD)),
                    error=function(e) {cat("   ERROR:", conditionMessage(e), "\n"); NULL})
      el <- proc.time()["elapsed"] - t0
      if (is.null(f)) { cat(sprintf("  rep %d: %.1f s | FALLO\n", i, el)); next }
      pe <- modsem::parameter_estimates(f)
      r3  <- pe[pe$op=="~" & grepl("alpha.*PEH|PEH.*alpha", pe$rhs), ]
      r11 <- pe[pe$op=="~" & grepl("alpha.*FORM|FORM.*alpha", pe$rhs), ]
      cat(sprintf("  rep %d: %.1f s | g3=%s | g11=%s\n", i, el,
                  if(nrow(r3)) sprintf("%.3f", r3$est[1]) else "NA",
                  if(nrow(r11)) sprintf("%.3f", r11$est[1]) else "NA"))
    }
  }
}
cat("\nPILOTO COMPLETO\n")
