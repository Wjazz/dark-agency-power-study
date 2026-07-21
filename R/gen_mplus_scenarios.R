# Genera los 30 .inp de MonteCarlo a partir de la plantilla. Reproducible.
tmpl <- readLines("mplus/montecarlo_template.inp")
Ns   <- c(250,300,350,450,500); LAs <- c(.35,.40,.45); G3s <- c(.10,.15)
set.seed(53711); dir.create("mplus/scenarios", showWarnings=FALSE)
i <- 0
for (N in Ns) for (LA in LAs) for (G3 in G3s) {
  i <- i+1; seed <- 53711 + i*97
  s <- tmpl
  s <- gsub("@N@", N, s); s <- gsub("@LA@", sprintf("%.2f",LA), s)
  s <- gsub("@G3@", sprintf("%.2f",G3), s); s <- gsub("@SEED@", seed, s)
  f <- sprintf("mplus/scenarios/mc_N%d_la%02d_g%02d.inp", N, LA*100, G3*100)
  writeLines(s, f)
}
cat(i, "escenarios .inp generados en mplus/scenarios/\n")
cat("Ejecutar en lote:  for f in mplus/scenarios/*.inp; do mplus \"$f\"; done\n")
cat("Leer potencia: columna '% Sig Coeff' de la fila 'EA ON INT' en cada .out\n")
