# PROMPT · SIMULACIÓN **v1 — ORIGINAL** · *Dark Agency* (S-1 + LMS)
### `[recuperado del transcript el 14-ago-2026 · aportado por el autor]`

> **Por qué se guarda.** `PROMPT_SIMULACION_v2.md` (30-jul-2026) lo cita, lo evalúa y declara que *«sigue siendo válido en su contenido y **quedó ejecutado en ~20 %**»* — **pero el texto del prompt original no estaba en disco.** Solo existía su análisis. **Es la misma operación que `MP-ADUANA30` hizo el 30-jul: recuperar del transcript un documento fuente que solo sobrevivía citado.**
>
> **Estatus: documento fuente, no norma vigente.** La norma vigente es `PROMPT_SIMULACION_v2.md`, que lo sustituye y separa el plan en dos brazos.

---

## ROL

Actúa como un metodólogo senior especializado simultáneamente en: Structural Equation Modeling (SEM) · Latent Moderated Structural Equations (LMS) · Psychometrics · Bifactor S-1 · Entrepreneurial Psychology · Monte Carlo Simulation · Open Science · Reproducible Research.

No eres un asistente de escritura. Eres un coinvestigador responsable de construir una simulación completamente reproducible que permita validar el pipeline metodológico antes de iniciar la recolección real.

No improvises. No simplifiques. Si detectas contradicciones entre documentos, detente y explica el conflicto antes de escribir código.

## DOCUMENTOS

Lee completamente, en este orden: **1.** `Dark_Agency_in_Institutional_Voids_v7.md` · **2.** `Tres_Ultimos_Informes_Compilados.md`. No asumas absolutamente nada hasta terminar ambas lecturas.

Reconstruye automáticamente: modelo conceptual · variables latentes · variables observadas · número de ítems · escalas · hipótesis · mediaciones · moderaciones · preregistro · criterios de falsación · reglas de exclusión · pipeline estadístico. **Genera primero un resumen técnico del modelo. No escribas código todavía.**

## FASE 1 · AUDITORÍA METODOLÓGICA

Antes de simular datos verifica: consistencia entre hipótesis · consistencia entre modelo conceptual y modelo estadístico · coherencia entre preregistro y análisis · identificación del modelo · posibles problemas de convergencia · riesgos de Heywood · riesgos de baja potencia · riesgos de baja fiabilidad · riesgos de baja especificidad del factor α.

Si detectas problemas, propón alternativas, **pero nunca modifiques automáticamente el diseño**.

## FASE 2 · SIMULACIÓN DE DATOS

Construye una población sintética que reproduzca únicamente relaciones psicológica y estadísticamente plausibles. **La simulación debe parecer obtenida de emprendedores reales. No debe parecer una base perfecta.**

Debe contener: heterogeneidad individual · errores de medición · asimetrías · correlaciones imperfectas · valores extremos · respuestas inconsistentes ocasionales · missing completamente plausibles · longstrings en muy baja frecuencia · attention failures compatibles con población real.

## MODELO DE MEDIDA

Respeta exactamente el modelo reconstruido desde la tesis. No sustituyas estructuras. No simplifiques escalas. Implementa el modelo S-1 exactamente como fue especificado. **El núcleo antagónico (`Aref`) debe permanecer ortogonal al factor α.** No permitas correlación distinta de cero salvo que la tesis explícitamente la especifique.

## INTERACCIÓN LATENTE

**NO utilices `lavaan` para estimar la interacción.** La interacción latente deberá implementarse exclusivamente mediante uno de estos métodos:

1. **Mplus** — `TYPE=RANDOM`, `XWITH`, LMS, MLR, `ALGORITHM=INTEGRATION`
2. **`modsem`** — `method="lms"`

**Nunca intentes aproximar la interacción mediante productos observados. Nunca utilices `semopy`. Nunca utilices `jamovi`.**

## MONTE CARLO

No quiero una única simulación. Quiero **un estudio completo de potencia**.

- **N:** 250 · 300 · 350 · 450 · 500
- **Cargas α:** .35 · .40 · .45
- **γ₃:** .10 · .15
- **Réplicas:** **1000 por escenario**

Calcular: potencia · proporción `p < .05` · sesgo · error estándar · cobertura IC · tasa de convergencia · inadmisibles. Generar automáticamente la tabla **N × λα × γ₃ → Potencia**.

**La recomendación final deberá escoger el menor `N` cuyo escenario pesimista realista alcance potencia ≥ .80.**

## VALIDACIÓN DEL MODELO

Una vez generada cada base, calcular: **ω · ωH · ωHS · H · ECV · consistencia · especificidad**, y **α únicamente como referencia histórica**. **Nunca presentar α de Cronbach como evidencia principal.**

## PIPELINE ANALÍTICO — en este orden exacto

- **FASE 0** · Descriptivos · asimetría · curtosis · distribución · suelo · techo · missing
- **FASE 1** · CFA S-1 · comparar modelos · CFI, TLI, RMSEA, SRMR, χ², ECV, ωH, ωHS, H
- **FASE 1b** · Common Method Variance · Marker CFA · Baseline · C · U · R
- **FASE 1c** · Modelo completo de medida
- **FASE 2** · SEM estructural · LMS · interacción latente · estimación robusta
- **FASE 2b** · IMM · bootstrap · simple slopes · IE condicional · IC
- **FASE 2c** · Sensibilidad · liberación de rutas · restricciones · comparaciones
- **FASE 3** · Robustez · covariables · BIDR · canal de reclutamiento · controles demográficos

## TABLAS

**T1** Descriptivos · **T2** Comparación de modelos · **T3** Parámetros S-1 · **T4** Correlaciones latentes · **T5** Modelo estructural · **T6** Efectos condicionales. Además: figura SEM · simple slopes · mapa conceptual.

## INTERPRETACIÓN

No quiero únicamente resultados. Quiero interpretación científica. Cada conclusión deberá responder: ¿qué significa? · ¿qué hipótesis apoya? · ¿qué hipótesis falsaría? · ¿qué literatura dialoga con este resultado? · ¿qué amenazas de validez permanecen?

## CIENCIA ABIERTA

Todo debe producirse de manera completamente reproducible: scripts · CSV · RMarkdown · README · estructura de carpetas · semillas · versiones de paquetes · `sessionInfo()`. **Nunca ocultes decisiones metodológicas. Cada decisión deberá justificarse.**

---

## Nota de auditoría — brecha entre lo pedido y lo corrido

| Lo que el prompt v1 pidió | Lo que se corrió |
|---|---|
| **1000 réplicas** por escenario | **300** |
| N hasta **500** | **hasta 1500** (la malla v3 tuvo que extenderse porque ninguna celda del rango original alcanzaba .80) |
| Método **LMS** | **QML** en la malla ejecutada; LMS como confirmación pendiente |
| ω, ωH, ωHS, H, ECV | **no calculados** |
| Fases 0, 1, 1b, 1c, 2b, 2c, 3 | **no ejecutadas** |
| Tablas T1-T6 y figuras | **no producidas** |

> **`PROMPT_SIMULACION_v2.md` §2 da el diagnóstico y es el mejor que hay: el diseño tenía una compuerta —«pasar a la etapa 2 cuando alguna celda caiga en [.75, .85]»— y ninguna celda del rango original la alcanzó (máximo observado .680). El estudio no falló: su compuerta nunca disparó y se quedó sin instrucción.**
>
> **Y la malla v3 (31-jul / 1-ago) es la ejecución del brazo P de ese v2: extendió `N` hasta 1500 y encontró el cruce en 1300.** *El circuito se cierra: v1 pidió, v2 diagnosticó por qué no se cumplió, v3 corrió lo que faltaba del brazo de potencia.*

`[PROMPT v1 · recuperado 14-ago-2026 · documento fuente, no norma vigente]`
