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

**Conclusion:** No decision cell reaches .80. H3 (latent moderation α × PEH → EA)
is underpowered at N ≤ 450 for a realistic small effect (γ3 = .10). **H3 is
pre-registered as exploratory.** H1 (main effect α → EA) and H2 (mediation via EA)
are unaffected — they require substantially lower N.

Full results: `output/power_table_qml.csv`. Raw replicas excluded from the repo (187 KB);
available on request.

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
