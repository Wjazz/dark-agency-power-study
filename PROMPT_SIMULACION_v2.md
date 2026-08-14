# PROMPT · SIMULACIÓN v2 — *Dark Agency* (S-1 + LMS)
## Cierre de brecha entre el plan original y lo que quedó corrido

> **Emisión.** 30-jul-2026. Sustituye al prompt de simulación original, que sigue siendo válido en su contenido y **quedó ejecutado en ~20 %**. Este prompt no lo repite: **declara qué está hecho, qué falta y en qué orden**, y corrige un defecto de diseño del pipeline actual.
> **Procedencia del modelo:** `Dark_Agency_in_Institutional_Voids_v7.md` (jul-2026). **No v1** — v1 («versión 2025») es **otra tesis**, con otros constructos (SAgencia, EIB, POPS, PsyCap, LPA) y no se usa aquí ni para reconstruir el modelo ni para nada.

---

# ROL

Metodólogo senior y **coinvestigador**, simultáneamente en SEM · LMS · psicometría · bifactor S-1 · psicología del emprendimiento · simulación Monte Carlo · ciencia abierta · investigación reproducible.

No eres asistente de escritura. No improvises. No simplifiques. **Si detectas contradicción entre documentos, detente y explica el conflicto antes de escribir código.** Y una regla que este prompt añade: **toda conclusión nombra qué la derrotaría.** Una conclusión sin falsador no se emite.

---

# §0 · LECTURA OBLIGATORIA, EN ESTE ORDEN

1. `Dark_Agency_in_Institutional_Voids_v7.md` — el modelo. **Reconstruye desde cero** y no asumas nada: modelo conceptual · latentes · observadas · nº de ítems · escalas · hipótesis · mediaciones · moderaciones · prerregistro · criterios de falsación · reglas de exclusión · pipeline estadístico.
2. `README.md` de este repo — lo que la corrida de julio decidió.
3. `output/power_table_qml.csv` · `output/design_matrix.csv` · `output/frontera_viabilidad.csv` · `output/banda_sensibilidad.csv` · `output/sessionInfo_qml.txt`
4. `R/power_study_modsem.R` (cabecera incluida: declara el diseño en dos etapas) · `R/run_power_cells.R` · `R/summarize_power.R` · `design_matrix.py`
5. `julio/Auditoria_Aduana_30jul2026.md` frente 8 y dictamen III.

**Entrega primero un resumen técnico del modelo reconstruido. Todavía no escribas código.**

---

# §1 · ESTADO REAL AL 30-jul-2026 — no rehagas esto

## Hecho y verificado

| | |
|---|---|
| Malla declarada | **30 celdas**: N ∈ {250, 300, 350, 450, 500} × λα ∈ {.35, .40, .45} × γ₃ ∈ {.10, .15}, en `output/design_matrix.csv` |
| Corrido de verdad | **6 celdas**, todas en **λα = .40**: N ∈ {300, 350, 450} × γ₃ ∈ {.10, .15}, **R = 300 réplicas, método QML** |
| Resultado | `conv_rate` **1.00** · `pct_heywood` **0** · sesgo relativo ≈ 0 (máx. .066) · cobertura .933–.977 · **fiable = SÍ** en las seis |
| Potencia | γ₃=.10 → **.247 / .253 / .347** · γ₃=.15 → **.487 / .550 / .680** (N = 300 / 350 / 450) |
| DGP | Manual, en `gen_data()`: latentes con A_ref ⊥ α (`APEH` = .10 solo α~PEH), cargas duales **ancladas** en correlaciones interfactoriales SD4 publicadas — **Narc = .35, Mach = .20** (Blötner 2021 T1; Bajcsi 2025 T4). **No** homogéneo .55; **no** inflar λα |
| Vía Mplus | Andamiada: `mplus/montecarlo_template.inp` + **30 `.inp`** con `TYPE=RANDOM`, `XWITH`, LMS, MLR. **Sin correr** (requiere licencia ≥ 8) |
| Semillas | `BASESEED = 53711`; por réplica `53711 + r × 101`. Réplicas crudas en `output/replicas_qml.csv` |
| Frontera de viabilidad | `frontera_viabilidad.csv` y `banda_sensibilidad.csv` = **umbral de λ_A dual para que α sobreviva**. La corrida los autorrotula **«robustez, no decisión N»** |

## No hecho — y es el 80 % del plan original

1. **20 de las 30 celdas sin correr:** λα = .35 y λα = .45 no tienen ninguna celda de potencia. `design_matrix.csv` las trae con `power = "PENDIENTE: correr LMS"`.
2. **N = 250 y N = 500 sin correr**, ni en λα = .40.
3. **R = 1000 nunca se alcanzó.** Todo está a R = 300.
4. **Etapa LMS de confirmación no ejecutada** — y la razón es un defecto de diseño, §2.
5. **Cero capa de datos realistas.** Barrido sobre los cinco scripts de `R/`: `missing` 0 · `longstring` 0 · `attention` 0 · `outlier` 0 · `careless` **0**. Nada de la FASE 2 del plan original existe.
6. **Pipeline analítico FASE 0–3 sin construir.** El estudio de potencia **no es** una demostración de pipeline.
7. **Fiabilidades por réplica sin calcular:** ω, ωH, **ωHS empírico**, H, ECV, consistencia, especificidad. ωHS existe solo **analíticamente** en `design_matrix.py` (la frontera), no estimado en cada réplica.
8. **T1–T6, figura SEM, *simple slopes*, mapa conceptual, RMarkdown: nada.**

---

# §2 · EL DEFECTO DE DISEÑO QUE HAY QUE ARREGLAR ANTES DE CORRER NADA

La cabecera de `R/power_study_modsem.R` declara el diseño en dos etapas:

> «Etapa *screening* (QML, R = 300) sobre las 6 celdas de decisión; **etapa final (LMS, R = 1000) solo en las celdas que el screening ubique en la frontera de potencia .80 (± .05)**.»

**El máximo observado fue .680.** Ninguna celda cayó en [.75, .85]. **Luego la etapa 2 no tenía condición de arranque, y el diseño no tiene rama para el caso «ninguna celda alcanza la frontera».** El estudio no falló: **su compuerta nunca disparó y se quedó sin instrucción.** Eso explica el 80 % faltante mejor que cualquier hipótesis sobre esfuerzo.

**Corrección obligatoria, y es la primera tarea de código:**

```
si  ninguna celda ∈ [.75, .85]
y   max(potencia) < .75
entonces  EXTENDER la malla hacia arriba en N hasta acotar el cruce,
          o declarar el efecto inalcanzable con N factible y prerregistrar exploratorio.
```

Sin esa rama, correr más réplicas de las mismas celdas no produce ninguna decisión: solo estrecha el intervalo alrededor de un número que ya sabemos que está por debajo del umbral.

---

# §3 · LA SEPARACIÓN EN DOS BRAZOS — y por qué el plan original no podía cumplirse tal cual

El prompt original pedía, en el mismo objeto, (a) un estudio de potencia con 1000 réplicas y (b) una base que «parezca obtenida de emprendedores reales», con *longstrings*, fallos de atención, respuestas inconsistentes, *missing* y valores extremos.

**Las dos cosas no pueden ser el mismo objeto, y ésta es la razón:** la potencia es una propiedad **del proceso generador de datos**. Si se inyecta respuesta descuidada, la potencia que se estime ya no es la del modelo prerregistrado sino la de un modelo contaminado, y **el número deja de ser el que justifica el N del prerregistro**. Mezclarlos produce una cifra que no responde a ninguna pregunta: ni «¿qué N necesito bajo el modelo?» ni «¿aguanta mi pipeline datos sucios?».

> **BRAZO P · POTENCIA.** Datos limpios generados por el modelo. Su única pregunta: **¿qué N alcanza potencia ≥ .80 para γ₃?** Es lo que va al prerregistro y a §3.2.3 de la tesis.
>
> **BRAZO R · REALISMO Y PIPELINE.** **Una** base (o pocas) con toda la contaminación del plan original. Su única pregunta: **¿el pipeline FASE 0–3 sobrevive a datos que parecen reales, y detecta lo que debe detectar?** Es validación de procedimiento, no de potencia.
>
> **Regla dura:** ninguna cifra de potencia del brazo R entra en la tesis. Y si se reporta potencia bajo contaminación, se rotula **«potencia bajo DGP contaminado, no comparable con la del prerregistro»**. *Falsador de esta separación: mostrar que la contaminación planificada deja invariante la distribución muestral de γ̂₃ — en cuyo caso los brazos se unifican y hay que decirlo.*

---

# §4 · BRAZO P · lo que hay que correr, en orden de valor decisorio

**Prioridad 1 — extender N donde el cruce es plausible.** En γ₃ = .15 la potencia va .487 → .550 → .680 en N = 300 → 350 → 450. **Hipótesis a testear, no a asumir: el cruce de .80 cae en N ≈ 550–700.** Correr **N ∈ {500, 550, 600, 700}** a λα = .40, γ₃ = .15. Si .80 se alcanza, informar el menor N y su IC.

**Prioridad 2 — decidir si γ₃ = .10 es alcanzable.** La serie .247 → .253 → .347 crece muy poco. Correr **N ∈ {600, 800, 1000}** solo para acotar. **Si .80 exige N inviable, se declara así y H3 queda exploratoria — que es lo que el `README` ya concluyó y la tesis todavía no dice.** No se reencuadra: un diseño insesgado y sub-potente se arregla con N, no con narrativa.

**Prioridad 3 — abrir λα.** Correr λα ∈ {.35, .45} en las celdas de decisión que la prioridad 1 identifique. **λα = .35 es el escenario pesimista** y es el que manda la regla de decisión.

**Prioridad 4 — R = 1000 solo en las celdas de decisión.** No en las 30. Motivo cuantitativo, que debe quedar escrito: el error Monte Carlo de una potencia estimada es √(p(1−p)/R); en p ≈ .80 eso es **.023 con R = 300** y **.0126 con R = 1000**. Pasar de 300 a 1000 vale la pena **solo donde la decisión está en juego**; en una celda que da .25 no cambia nada.

**Prioridad 5 — confirmación LMS.** Sobre la celda elegida, `modsem(method = "lms")` o la vía Mplus (`TYPE = RANDOM`, `XWITH`, `ALGORITHM = INTEGRATION`, `MLR`). Reportar la discrepancia QML↔LMS como dato, no como error.

**Regla de decisión, sin cambios respecto de la firmada:** el **menor N** cuyo escenario **pesimista realista** (λα = .40, γ₃ = .10, cargas duales empíricas Narc .35 / Mach .20) alcance potencia ≥ .80. **Si ese escenario resulta inalcanzable, la regla se reformula por escrito y se declara el cambio** — no se sustituye en silencio por una celda más benévola.

**Métricas por celda, todas:** potencia (proporción p < .05) · sesgo absoluto y relativo · **EE empírico y EE medio estimado** (y su razón) · cobertura del IC 95 % · tasa de convergencia · soluciones inadmisibles y **Heywood** · tiempo por réplica.

**Tabla obligatoria:** `N × λα × γ₃ → potencia`, con IC Monte Carlo por celda.

---

# §5 · BRAZO P · modelo de medida e interacción — prohibiciones que no se negocian

- Modelo **S-1 exactamente como v7 lo especifica**. No sustituyas estructuras, no simplifiques escalas.
- **A_ref ⊥ α por construcción.** Correlación distinta de cero **solo** si v7 la especifica explícitamente. Hoy la única correlación exógena es **α ~ PEH = .10**.
- Cargas duales **ancladas en literatura**: Narc → A_ref ≈ **.35**, Mach → A_ref ≈ **.20**. **Prohibido** el contrafáctico homogéneo .55 y **prohibido** inflar λα a .50–.55 (opción rechazada por razonamiento motivado, decisión C1+C2 firmada).
- **La interacción latente NUNCA con lavaan.** Solo `modsem(method = "lms")` / `"qml"`, o Mplus con `XWITH`. `lavaan` se usa únicamente para generar datos poblacionales.
- **Nunca** productos de indicadores observados. **Nunca** semopy. **Nunca** jamovi. **Nunca** Sobel.
- **α de Cronbach solo como referencia histórica.** Jamás como evidencia principal de fiabilidad.

---

# §6 · BRAZO R · la base que parece real, y el pipeline

## §6.1 · Contaminación — cada componente con su tasa declarada y su fuente

La base debe **no** parecer perfecta: heterogeneidad individual · error de medición · asimetrías · correlaciones imperfectas · valores extremos · respuestas inconsistentes ocasionales · *missing* plausible · *longstrings* en baja frecuencia · fallos de atención compatibles con población real.

> **Exigencia que el plan original no tenía y hace falta: cada mecanismo se implementa con su tasa numérica declarada y su justificación.** «*Longstrings* en muy baja frecuencia» no es implementable; «*longstring* ≥ 8 respuestas idénticas consecutivas en el 2 % de los casos `[FUENTE: tasa a fijar contra literatura de *careless responding* — Meade & Craig, o el propio piloto]`» sí lo es. Toda tasa sin fuente se marca `[FUENTE: …]` y se reporta como decisión del simulador, no como hecho poblacional.
>
> **Y el *missing* lleva su mecanismo declarado:** MCAR, MAR o MNAR. «Plausible» no es un mecanismo. La elección cambia qué puede recuperar FIML y es exactamente lo que este brazo existe para poner a prueba.

## §6.2 · Pipeline analítico, en este orden exacto

- **FASE 0 ·** descriptivos · asimetría · curtosis · distribución · **suelo y techo** (con el criterio de no-interpretabilidad de v7 §3.3.4 aplicado de verdad) · *missing*.
- **FASE 1 ·** CFA S-1 · comparación de modelos · CFI, TLI, RMSEA, SRMR, χ² · **ECV, ωH, ωHS, H**.
- **FASE 1b ·** varianza de método común: *marker* CFA, modelos **baseline / C / U / R**.
- **FASE 1c ·** modelo completo de medida.
- **FASE 2 ·** SEM estructural con **LMS**, interacción latente, estimación robusta.
- **FASE 2b ·** IMM · *bootstrap* · *simple slopes* · efecto indirecto condicional con IC.
- **FASE 2c ·** sensibilidad: liberación de rutas, restricciones, comparaciones. **Incluir las dos que v7 ya prerregistró en sus notas al pie:** test de Δχ² sobre γ₂ = 0, y la liberación de EA → UVB-O (fijada a cero en el modelo primario).
- **FASE 3 ·** robustez: covariables, BIDR, canal de reclutamiento, controles demográficos.

## §6.3 · Fiabilidad por base

ω · ωH · **ωHS** · H · ECV · consistencia · especificidad. **α solo como referencia histórica.** Y el contraste que interesa: **ωHS estimado vs. ωHS analítico** de `design_matrix.py` — si divergen, el diseño tiene un supuesto que no se sostiene, y eso es un hallazgo, no un bug.

## §6.4 · Salidas

**T1** descriptivos · **T2** comparación de modelos · **T3** parámetros S-1 · **T4** correlaciones latentes · **T5** modelo estructural · **T6** efectos condicionales. Más **figura SEM**, **simple slopes** y **mapa conceptual**.

---

# §7 · INTERPRETACIÓN — no solo resultados

Cada conclusión responde cinco preguntas, y la cuarta y la quinta no son opcionales:

1. ¿Qué significa?
2. ¿Qué hipótesis apoya?
3. **¿Qué hipótesis falsaría?**
4. ¿Con qué literatura dialoga?
5. ¿Qué amenazas de validez permanecen?

**Y una regla de vocabulario, porque el linaje de esta tesis tiene historial en esto:** el diseño es **transversal**. Cada «efecto», «impacto», «predice» o «explica la varianza» se acota a **asociación concurrente** o se degrada. v7 §3.7 ya lo hace bien (Maxwell y Cole, 2007) y es el estándar interno: no se baja de ahí.

**Prohibido reificar.** Ningún puntaje simulado se reporta como atributo del caso. Test: ¿sobrevive la frase si «es [puntaje]» se reemplaza por «se ubica, en esta medición, en la región [puntaje] de una escala cuya aditividad no está probada»? Si no, se reescribe.

---

# §8 · CIENCIA ABIERTA

Todo reproducible: scripts · CSV · RMarkdown · README · estructura de carpetas · **semillas** · versiones de paquetes · `sessionInfo()`.

- **Continuidad de semilla obligatoria:** `BASESEED = 53711`, por réplica `53711 + r × 101`. Las celdas nuevas **extienden** el esquema; no lo reinician, o las corridas dejan de ser comparables con las seis existentes.
- Las réplicas crudas de julio (`output/replicas_qml.csv`, 187 KB) **se conservan**. Las nuevas se acumulan, no las sobrescriben.
- **Ninguna decisión metodológica se oculta.** Cada una se justifica en el `README`, incluida la de no correr algo.
- **El `README` se actualiza con la frase correcta sobre potencia.** Hoy dice lo cierto («H3 pre-registered as exploratory») y **la tesis §3.2.3 dice lo contrario** («N ≈ 300−450 exige potencia ≥ .80»). Esa contradicción entre repo y manuscrito es del manuscrito, y su corrección está prescrita en `PROMPT_v8_Dark_Agency.md` §4.

---

### Falsador de este prompt
Que aparezca en el repo una corrida con λα ≠ .40, con N ∈ {250, 500}, con R = 1000, con etapa LMS ejecutada, o con cualquier mecanismo de *careless responding* implementado. Verificado el 30-jul-2026 sobre `output/` y los cinco scripts de `R/`: **ninguna de las cinco existe.** Si alguna aparece, el §1 de este prompt está mal y hay que recontar antes de correr.
