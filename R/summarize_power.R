# =====================================================================
# Agrega output/replicas_<METHOD>.csv -> output/power_table_<METHOD>.csv
# potencia (p<.05), sesgo relativo vs gamma3 en metrica del modelo, EE medio,
# cobertura IC95, tasa de convergencia y %Heywood, por celda.
# Uso: METHOD=qml Rscript R/summarize_power.R
# =====================================================================
METHOD <- Sys.getenv("METHOD", "qml")
d <- read.csv(sprintf("output/replicas_%s.csv", METHOD))

agg <- do.call(rbind, lapply(split(d, d$cell), function(g) {
  ok <- g$converged; v <- ok & is.finite(g$p)
  ci_lo <- g$gamma3_hat - 1.96*g$se; ci_hi <- g$gamma3_hat + 1.96*g$se
  cov95 <- v & (g$gamma3_metrica_modelo >= ci_lo) & (g$gamma3_metrica_modelo <= ci_hi)
  data.frame(cell=g$cell[1], N=g$N[1], lambda_a=g$lambda_a[1], gamma3=g$gamma3[1],
             gamma3_metrica_modelo=g$gamma3_metrica_modelo[1], method=METHOD, n_rep=nrow(g),
             conv_rate=mean(ok), pct_heywood=mean(g$heywood[ok]),
             power=mean(g$p[v]<.05), bias_rel=mean(g$gamma3_hat[v])/g$gamma3_metrica_modelo[1]-1,
             mean_SE=mean(g$se[v]), coverage=mean(cov95[v]),
             fiable=ifelse(mean(ok)>=.95 & mean(g$heywood[ok])<=.05,"SI","NO-CONFIABLE"))
}))
agg <- agg[order(agg$cell),]
out <- sprintf("output/power_table_%s.csv", METHOD)
write.csv(agg, out, row.names=FALSE)
cat("Escrito:", out, "\n"); print(agg)
