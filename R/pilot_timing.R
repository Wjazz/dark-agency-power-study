# Piloto de cronometraje: 1 celda (N=350, la=.40, g3=.10), 3 replicas.
# Decide si el grid completo cabe en el presupuesto (regla 8h del protocolo Fase 2).
.libPaths("~/R/library")
suppressMessages({library(lavaan); library(modsem)})
Ns<-350; LA<-.40; G3<-.10; APEH<-.10; G1<-.30; G2<-0; G4<-.20
gen_data <- function(N, LA, G3) {
  S <- matrix(c(1,0,0, 0,1,APEH, 0,APEH,1), 3, byrow=TRUE)
  Z <- MASS::mvrnorm(N, mu=c(0,0,0), Sigma=S)
  Aref<-Z[,1]; alpha<-Z[,2]; PEH<-Z[,3]
  EA <- G1*alpha + G2*Aref + G4*PEH + G3*(alpha*PEH) +
        rnorm(N, 0, sqrt(max(1 - (G1^2+G4^2+G3^2*(1+2*APEH^2)),.05)))
  ld <- function(f,lam,k,pre) { m<-outer(f,rep(lam,k))+matrix(rnorm(N*k,0,sqrt(1-lam^2)),N);
                                colnames(m)<-paste0(pre,1:k); m }
  laN<-.35; laM<-.20
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
set.seed(53711)
for (i in 1:3) {
  dat <- gen_data(Ns, LA, G3)
  t0 <- proc.time()["elapsed"]
  f <- tryCatch(modsem::modsem(fit_model, dat, method="lms"), error=function(e) {cat("ERROR:",conditionMessage(e),"\n"); NULL})
  el <- proc.time()["elapsed"] - t0
  cat(sprintf("rep %d: %.1f s | %s\n", i, el, if(is.null(f)) "FALLO" else "OK"))
  if (!is.null(f) && i==1) {
    pe <- tryCatch(modsem::parameter_estimates(f), error=function(e) {cat("API parameter_estimates FALLO:",conditionMessage(e),"\n"); NULL})
    if (is.null(pe)) { pe2 <- tryCatch(summary(f)$parameter_estimates, error=function(e) NULL)
                       cat("accesor alternativo:", if(is.null(pe2)) "tampoco" else "summary()$parameter_estimates OK", "\n")
    } else { print(pe[pe$lhs=="EA",]) }
  }
}
