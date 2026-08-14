# Dark Agency — Monte Carlo Power Study (Bifactor S-1 + LMS)

Pre-registration power analysis for *Dark Agency in Institutional Voids* (Lalupu, in prep.).
Determines the minimum sample size to detect a latent moderation effect (α × PEH → EA)
under a Bifactor S-1 measurement model, before any data collection.

---

## Design

| Factor | Levels |
|---|---|
| N | 250, 300, 350, 450, 500 |
| λα (specificity of dark agency factor) | .35, .40, .45 |
| γ3 (latent interaction effect) | .10, .15 |
| **Total cells** | **30 × 300 screening reps (QML)** |

**Decision rule:** smallest N with power ≥ .80 in the pessimistic-realistic cell (λα = .40, γ3 = .10).

**Method:** Latent interaction estimated via `modsem` (method = `"qml"` for screening,
`"lms"` for frontier confirmation). Never product indicators; never lavaan for the
interaction path. See Klein & Moosbrugger (2000); Klein & Muthén (2007); Morris et al. (2019).

**Model:** Bifactor S-1 on the SD4 (Paulhus et al., 2021) — Aref ⊥ α by construction.
Dual-loading anchors: λ(Narc→Aref) ≈ .35, λ(Mach→Aref) ≈ .20 (Blötner et al., 2021;
Bajcsi et al., 2025). ωHS(α) viability frontier computed analytically in `design_matrix.py`.

---

## Results (6 decision cells, QML screening, 300 reps each)

| N | γ3 | Power | Bias (rel.) | Coverage | Conv. rate |
|---|---|---|---|---|---|
| 300 | .10 | .247 | .066 | .977 | 1.00 |
| 300 | .15 | .487 | .020 | .963 | 1.00 |
| 350 | .10 | .253 | −.071 | .943 | 1.00 |
| 350 | .15 | .550 | .024 | .943 | 1.00 |
| 450 | .10 | .347 | .001 | .950 | 1.00 |
| 450 | .15 | .680 | −.010 | .933 | 1.00 |

**Conclusion (superseded by the v3 run below, which estimates the declared two-interaction model):** No decision cell reaches .80. H3 (latent moderation α × PEH → EA)
is underpowered at N ≤ 450 for a realistic small effect (γ3 = .10). **H3 is
pre-registered as exploratory.** H1 (main effect α → EA) and H2 (mediation via EA)
are unaffected — they require substantially lower N.

Full results: `output/power_table_qml.csv`. Raw replicas excluded from the repo (187 KB);
available on request.

---

## Results — v3 run (19 cells, **full two-interaction model**, 1-Aug-2026)

The July screening estimated eq. (1) only (one latent interaction). The manuscript
(v8 §2.8) declares **two**: `alpha:PEH -> EA` (H3) and `alpha:FORM -> EB` (H4).
This run estimates the declared model. Grid: N in {350,450,550,700,900,1100,1300,1500}
x lambda_a in {.35,.40,.45} x (g3,g11) in {(.10,-.10),(.15,-.15)}, 300 QML reps/cell.
Seeds extend the July scheme (`BASESEED + idx*101`, idx from 31).

Pessimistic-realistic scenario (lambda_a = .40):

| N | power g3=.10 | power g3=.15 | power g11=-.10 | power g11=-.15 |
|---|---|---|---|---|
| 350 | .257 | .507 | .330 | .647 |
| 450 | .323 | .673 | .390 | .770 |
| 550 | .397 | .703 | .467 | **.830** |
| 700 | .570 | **.827** | .640 | .927 |
| 900 | .637 | .943 | .733 | .960 |
| 1100 | .693 | — | **.820** | — |
| 1300 | **.807** | — | .870 | — |
| 1500 | .857 | — | .913 | — |

**.80 crossings:** g3=.10 at **N=1300**; g3=.15 at N=700; g11=-.15 at N=550; g11=-.10 at N=1100.

**Three findings:**

1. **The July table was an upper bound in sign but not in magnitude.** Same cells,
   one vs two interactions: deltas +.003, -.043, -.023, -.007; mean **-.018**, inside
   the Monte Carlo error of +/-.029. Adding the second latent interaction costs no
   appreciable power for g3.
2. **g11 (H4) is better powered than g3 (H3) in all 19 cells**, despite g3 being the
   *larger* effect in model metric (.35 vs -.26). Cause is measurement, not effect size:
   FORM is an observed registry index (no measurement error); PEH is latent with three
   .75 indicators. **The objectively measured moderator outperforms the perceptual one.**
3. **The signed decision rule cannot be met.** It fixed N at the smallest value reaching
   .80 in the pessimistic-realistic cell. That N exists and is 1300 — ~3.7x the feasible
   target of 350. The rule is therefore **reformulated in writing**: N >= 350 by
   feasibility, with confirmatory inference on the interactions expressly renounced.
   The benign scenario that would have rescued the target (g3=.15, crossing at 700)
   **is not adopted**.

Validity across all 19 cells: convergence 1.00, Heywood 0, relative bias in
[-.04, +.03], coverage .927-.967, mean-SE/empirical-SE ratio .947-1.036.
**A power problem, not a validity problem.**

Full results: `output/power_table_v3_2int.csv`; per-cell replicas in `output/v3/*.rds`.

### Reproduce the v3 run

```bash
NREP=300 WORKERS=6 bash R/run_malla_v3.sh    # cells 31-46
for i in 47 48 49; do CELL_IDX=$i NREP=300 Rscript R/run_cell_v3_2int.R; done
Rscript R/summarize_v3.R
```

> **MANDATORY — one BLAS thread per worker.** `run_malla_v3.sh` exports
> `OPENBLAS_NUM_THREADS=1` (and OMP/MKL equivalents). Without it each R worker opens
> its own BLAS thread pool and N workers x 8 threads thrash the machine. Measured
> 31-Jul-2026 on this box: **4.1 s/replication single-threaded vs ~1500 s/replication
> with multithreaded BLAS and 6 workers — a factor of ~400.** Parallelism goes
> **across cells, never inside a cell.**

---

## Repository structure

```
├── design_matrix.py          # 30-cell grid + analytical ωHS(α) frontier
├── R/
│   ├── power_study_modsem.R  # main simulation (QML screening + LMS confirmation)
│   ├── summarize_power.R     # aggregates replicas → power_table_qml.csv
│   ├── gen_mplus_scenarios.R # generates mplus/scenarios/*.inp (alternative Mplus path)
│   └── status.sh             # progress monitor
├── mplus/
│   ├── montecarlo_template.inp
│   └── scenarios/            # 30 .inp files (XWITH/LMS/MLR, TYPE=RANDOM)
├── output/
│   ├── power_table_qml.csv   # ← main result
│   ├── design_matrix.csv
│   ├── frontera_viabilidad.csv
│   ├── banda_sensibilidad.csv
│   └── sessionInfo_qml.txt
└── logs/
```

---

## Reproduce

```bash
# Analytical design matrix (no heavy dependencies)
python3 design_matrix.py

# R/modsem path (free, slower)
Rscript R/power_study_modsem.R        # writes output/power_table_qml.csv

# Mplus path (requires Mplus ≥ 8 licence)
Rscript R/gen_mplus_scenarios.R
for f in mplus/scenarios/*.inp; do mplus "$f"; done
# Power = '% Sig Coeff' for 'EA ON INT' in each .out file
```

**Seeds:** `BASESEED = 53711`; per-replica seed = `53711 + r × 101`.
**Dependencies:** R ≥ 4.2, `lavaan`, `modsem`, `MASS`, `parallel`.
Install with `install.packages(c("lavaan", "modsem", "MASS"))` — not dnf/apt.

---

## What this repo does NOT do

- Product indicators for the latent interaction
- α (Cronbach) as primary reliability evidence
- Sobel test
- Formal multigroup invariance (formal vs. informal sector)
- semopy / jamovi
