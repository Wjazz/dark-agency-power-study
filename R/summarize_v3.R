# =====================================================================
# Agrega las celdas de output/v3/ en una tabla unica y produce la
# comparacion 1 interaccion (julio) vs 2 interacciones (v3) sobre las
# celdas ancla. Tolera corridas parciales: resume lo que haya.
# =====================================================================
.libPaths(c("~/R/library", .libPaths()))
fs <- list.files("output/v3", pattern="^cell_[0-9]+\\.csv$", full.names=TRUE)
if (!length(fs)) { cat("Sin celdas todavia.\n"); quit(save="no") }
d <- do.call(rbind, lapply(fs, read.csv, stringsAsFactors=FALSE))
d <- d[order(d$cell), ]
write.csv(d, "output/power_table_v3_2int.csv", row.names=FALSE)

cat("\n=== MALLA v3 · DOS INTERACCIONES LATENTES (brazo P, QML) ===\n")
cat(sprintf("celdas completas: %d de 16\n\n", nrow(d)))
print(format(d[, c("cell","bloque","N","lambda_a","gamma3","gamma11",
                   "power_g3","power_g3_ic_lo","power_g3_ic_hi",
                   "power_g11","power_g11_ic_lo","power_g11_ic_hi",
                   "conv_rate","pct_heywood","n_valid")], digits=3), row.names=FALSE)

cat("\n=== VALIDEZ DEL ESTIMADOR (sesgo, cobertura, razon EE) ===\n")
print(format(d[, c("cell","N","lambda_a","bias_rel_g3","coverage_g3","razon_SE_g3",
                   "bias_rel_g11","coverage_g11","razon_SE_g11","seg_por_replica")], digits=3),
      row.names=FALSE)

# --- Comparacion con la corrida de julio (una interaccion) ------------
if (file.exists("output/power_table_qml.csv")) {
  j <- read.csv("output/power_table_qml.csv", stringsAsFactors=FALSE)
  a <- d[d$bloque=="A_ancla_comparacion", ]
  if (nrow(a)) {
    m <- merge(a[, c("N","lambda_a","gamma3","power_g3","power_g3_ic_lo","power_g3_ic_hi")],
               j[, c("N","lambda_a","gamma3","power")],
               by=c("N","lambda_a","gamma3"), suffixes=c("_2int","_1int"))
    if (nrow(m)) {
      names(m)[names(m)=="power"] <- "power_1int_julio"
      m$delta <- m$power_g3 - m$power_1int_julio
      cat("\n=== PUNTO F · ¿es cota superior la tabla de julio? ===\n")
      cat("Comparacion en celdas identicas: gamma3 con 1 interaccion (julio) vs 2 (v8 §2.8)\n\n")
      print(format(m[order(m$N, m$gamma3), ], digits=3), row.names=FALSE)
      cat(sprintf("\nCaida media de potencia para gamma3 al anadir la segunda interaccion: %+.3f\n",
                  mean(m$delta)))
      cat("Falsador de la lectura 'cota superior': delta >= 0 sistematico.\n")
    }
  }
}

# --- Cruce de .80 ------------------------------------------------------
cat("\n=== CRUCE DE .80 ===\n")
for (g in sort(unique(d$gamma3))) {
  s <- d[d$gamma3==g & d$lambda_a==.40, ]
  if (!nrow(s)) next
  s <- s[order(s$N), ]
  cat(sprintf("g3=%.2f (la=.40): ", g))
  cat(paste(sprintf("N=%d:%.3f", s$N, s$power_g3), collapse="  "))
  cru <- s$N[s$power_g3 >= .80]
  cat(if (length(cru)) sprintf("  -> cruce en N=%d\n", min(cru)) else "  -> SIN CRUCE en el rango corrido\n")
}
cat("\ng11 (H4) por lambda_a:\n")
for (la in sort(unique(d$lambda_a))) {
  s <- d[d$lambda_a==la, ]; s <- s[order(s$N), ]
  cat(sprintf("  la=%.2f: ", la))
  cat(paste(sprintf("N=%d(g11=%.2f):%.3f", s$N, s$gamma11, s$power_g11), collapse="  "), "\n")
}
cat("\nEscrito: output/power_table_v3_2int.csv\n")
