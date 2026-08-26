# Execution log

A record of each phase, the gate that closes it, the outcome, and the evidence
the gate printed. All runs on 2026-08-26 under R 4.4.3 on Windows 11. Reproduce
any line with `Rscript .checks/run_all_gates.R`, or a single gate with
`Rscript .checks/gate_NN_name.R`.

---

## Phase 0 — Environment

**Gate:** `gate_00_environment.R` — **PASS**, 20 of 20 checks.

R 4.4.3. All eight required packages installed and pinned in `renv.lock`:
readxl 1.5.0, dplyr 1.1.4, tidyr 1.3.1, ggplot2 4.0.1, corrplot 0.95,
NbClust 3.0.1, randomForest 4.7-1.2, knitr 1.51. The seed is defined once as an
integer in `R/99_utils.R`. `analysis/report.Rmd` names neither rmarkdown nor
pandoc, which the gate checks directly because neither is available.

`renv` was initialised bare and hydrated from the existing user library, which
linked 46 packages in ten seconds without downloading. `renv::status()` reports
a consistent state. `rmarkdown` is listed in `renv/settings.json` as ignored:
`renv` infers it from the presence of an `.Rmd` file, but the report renders
with `knitr::knit()` alone.

---

## Phase 1 — Acquisition

**Gate:** `gate_01_acquisition.R` — **PASS**, 8 of 8 checks.

Evidence: SHA-256 `62262f92257fa26f7927fa2ad5bbeaf9f026d7ab96fbfdb7834ad2dcf185d2df`,
51,500,032 bytes, matching the value recorded in `R/99_utils.R`, the value in
`data/checksums.txt`, and the digest Dryad publishes in its own file metadata at
`/api/v2/versions/102941/files`. The workbook opens and lists its six
worksheets; the Data worksheet reads as 1483 rows. `data/raw/` is excluded from
version control.

**Route, and one route that does not work.** The per-file download endpoint
`/api/v2/files/{id}/download` returns HTTP 401 and requires a bearer token. The
browser download path `/downloads/file_stream/{id}` returns 403 to a
non-browser client and, to a browser client, an interactive proof-of-work
challenge that a script should not be made to satisfy. The version-level
archive endpoint `/api/v2/versions/{id}/download` is public and unauthenticated,
returns a 51.5 MB zip, and is the route the download script uses. The zip is
assembled on demand and is not byte-stable, so the checksum is taken on the
extracted workbook rather than on the archive.

**A defect this gate found.** The first cold-start run failed. `resolve_version()`
extracted the version identifier by stripping every non-digit from the matched
href, which folded the "2" of `/api/v2/` into the number and produced version
2102941 instead of 102941, giving a 404 on the next call. The idempotent path
had masked it, because a workbook already present and verified returns before
the resolver is reached. Fixed by matching the digits after `versions/` only,
and re-verified by a full cold start.

**A finding worth recording.** A copy of the same file held in the original
course archive has the same size, 51,500,032 bytes, but a different SHA-256,
`17d272c7e1395848586303ecf224bc290a9f447935fb0b3db7b6a915bd937e57`. It is
therefore not byte-identical to the deposit. This repository uses the Dryad
copy only.

---

## Phase 2 — Data understanding

**Gate:** `gate_02_schema.R` — **PASS**, 26 of 26 checks.

Evidence: the Data worksheet header matches `data/expected_columns.txt` position
by position, 162 columns and 1483 rows; the site-year worksheet matches its own
recorded header, 37 columns and 34 rows. Twelve columns the analysis reads are
confirmed numeric and six confirmed present as text. All 38 mapped plot columns
and all 13 mapped site-year columns resolve. The nine standard treatment codes
are present.

Sheets are read with minimal name repair. The deposited header contains repeated
names — `HI`, `UN`, `NHI` and others appear twice — and columns are resolved by
occurrence rather than by a reader-generated suffix, so a change in `readxl`'s
repair strategy cannot silently move which column the analysis reads.

---

## Phase 3 — Preparation

**Gate:** `gate_03_preparation.R` — **PASS**, 13 of 13 checks.

Evidence: the join preserved every plot, 1483 before and 1483 after, over 34
site-year keys. The standard-treatment filter retained 1211 of 1483 plots and
excluded 272, filling all 306 design cells with two to four replicates and none
empty. No missing values in any of the 48 analysis columns. All 17 agronomic
variables lie inside their physically plausible bounds, zero values outside.
Irrigation ranges from 152.4 to 558.8 mm and no site-year is rainfed.

Two identities hold: grain, cob and stover dry matter sum to total dry matter at
a maximum relative error of 0, and harvest index equals grain dry matter over
total at 1.1e-16. These are the evidence for excluding both from the yield
models.

**A data-quality correction.** The deposit records the loamy sand texture class
as both `lS` (five site-years) and `ls` (one, Spurgin 2004, 37 plots). The
Spurgin site is on the Vetal soil series, which also carries the `lS` label at
Paxton in 2002 and 2003, so the two spellings denote one class. They are merged
onto the dominant spelling, the count is recorded, and the gate confirms the
merge left four texture classes. Before the merge, the single-site-year class
forced the train-test split to be redrawn to keep that level in training; after
it, no site-level factor level is carried by a single site-year.

---

## Phase 4 — Analysis and modelling

**Gate:** `gate_04_analysis.R` — **PASS**, 19 of 19 checks.

Evidence: component variance proportions sum to 1.000000000000001, eigenvalues
sum to 15 for 15 standardised variables, cumulative proportions are
non-decreasing and end at one. Four eigenvalues exceed one and four components
are recorded as retained, the gate re-deriving the count from the eigenvalues
rather than reading the recorded value. The cluster count is likewise
re-derived: three, with 7 of 24 indices voting for it, and six distinct counts
receiving votes. The analysis of variance is blocked on site-year and its
degrees of freedom account for all 1211 plots. Every contrast used all 34
blocks, every interval brackets its estimate, and multiplicity is Holm-adjusted.

**Assumptions, reported as they came out.** The gate requires that assumptions
be tested and recorded, not that they hold. The residuals of the plot-level
analysis of variance fail Shapiro-Wilk (W = 0.9748, p = 1.1e-13) and the
treatment variances are unequal by Brown-Forsythe (p = 3.2e-07), as are the
block variances (p = 4.0e-05). The gate printed its NOTE requiring the write-up
to say so. It does. The primary analysis is the paired contrasts, which require
only that the 34 block differences be approximately normal; the smallest
Shapiro-Wilk p across the five contrasts is 0.143.

---

## Phase 5 — Evaluation

**Gate:** `gate_05_modelling.R` — **PASS**, 19 of 19 checks.

Evidence: 24 training and 10 held-out site-years, none shared, together covering
all 34 exactly once. The recorded partition is reproduced from seed 20250317 in
one draw. No plot appears in both partitions; 860 training plots and 351
held-out plots account for all 1211. The allowed and blocked predictor lists do
not intersect, 18 against 20, and the response is not among the predictors. All
three models reported as predictive draw only on the allowed set and use no
harvest measurement. The two models that knowingly leak are labelled as
illustrations. No admitted predictor is a near-duplicate of the response: the
largest absolute correlation is 0.482, for the applied nitrogen rate. Every
reported metric was computed on the 351 held-out plots. Cross-validation ran 34
folds over 1211 plots and beat the training mean, RMSE 1.950 against 2.236 Mg/ha.

**A design change this phase forced.** The first site-year split placed the sole
loamy sand site-year in the test partition, and `predict.lm` failed on a factor
level it had never seen. Rather than dropping the categorical predictors, the
split was constrained to redraw, with a deterministic sequence of seeds, until
every level of texture, tillage and previous crop appears in training. The
constraint is retained after the texture merge even though it no longer binds,
and the number of draws is recorded so that it is visible when it does.

**A result the single split gave unreliably.** Before the texture merge, the
same models on a different split returned a held-out R-squared of -5.10 for the
linear model on all admitted predictors, against 0.19 after. A single ten
site-year test set is a weak basis for a claim about generalisation, which is
why leave-one-site-year-out cross-validation over all 34 folds was added and is
the figure quoted in the README and the write-up.

---

## Phase 6 — Communication and reproducibility

**Gate:** `gate_06_reproducibility.R` — **PASS**, 6 of 6 checks in the routine
run and 9 of 9 in the cold start.

Routine run: `figures/` and `results/` cleared, pipeline rerun in 45 seconds,
12 figures and 25 tables regenerated, and all 128 recorded quantities reproduced
exactly line for line. The report renders with `knitr::knit()` to
GitHub-flavoured markdown without pandoc.

Cold start with `FULL_RESET=1`: the 51 MB workbook deleted as well, downloaded
again from Dryad, verified against the recorded digest, and the whole pipeline
rerun, reproducing all 128 quantities exactly. Total 77 seconds.

---

## Summary

| Gate | Checks | Outcome | Seconds |
|---|---:|---|---:|
| `gate_00_environment.R` | 20 | PASS | 2.0 |
| `gate_01_acquisition.R` | 8 | PASS | 2.5 |
| `gate_02_schema.R` | 26 | PASS | 2.0 |
| `gate_03_preparation.R` | 13 | PASS | 2.1 |
| `gate_04_analysis.R` | 19 | PASS | 1.3 |
| `gate_05_modelling.R` | 19 | PASS | 2.5 |
| `gate_06_reproducibility.R` | 6 | PASS | 45.6 |

Three failures occurred during development and were fixed rather than worked
around: the version-identifier defect in the download script, the unseen factor
level in the test partition, and a deprecated ggplot2 call that silently
reinterpreted a figure argument. Each is recorded above under the phase whose
gate caught it.
