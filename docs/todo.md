# Task list

Status as of 2026-08-26. Tasks are grouped by lifecycle phase and each carries
the gate that closes it.

## Problem definition — complete

- [x] State the question the design can answer and what would count as an answer
- [x] Identify the nutrient-omission structure in the nine standard treatments
- [x] Decide which analyses from the original coursework to keep and which to
      drop, with a reason for each (`project-plan.md`)

## Acquisition — complete, `gate_01_acquisition.R` PASS

- [x] Resolve doi:10.5061/dryad.p30c6 through the Dryad API
- [x] Establish an automatable download route. The per-file API endpoint requires
      a bearer token and the browser download path is behind an interactive
      challenge; the version-level archive endpoint is public and is used
- [x] Record SHA-256 and verify against the digest Dryad publishes
- [x] Exclude `data/raw/` from version control; ship the script and the checksum

## Data understanding — complete, `gate_02_schema.R` PASS

- [x] Record the deposited header of both worksheets used
      (`data/expected_columns.txt`, `data/expected_columns_siteyear.txt`)
- [x] Read sheets with minimal name repair so repeated column names stay visible
- [x] Extract the depositors' variable dictionary to `results/`
- [x] Profile missingness across the analysis columns

## Preparation — complete, `gate_03_preparation.R` PASS

- [x] Join the site-year lookup onto the plots, asserting row conservation
- [x] Check that both worksheets agree on texture, tillage and previous crop
- [x] Merge the duplicate spelling of the loamy sand texture class, with the
      soil-series evidence recorded in the code comment
- [x] Range-check seventeen agronomic variables against physical bounds
- [x] Verify the dry-matter and harvest-index identities
- [x] Restrict inference to the nine standard treatments and confirm no design
      cell is empty

## Analysis and modelling — complete, `gate_04_analysis.R` PASS

- [x] Descriptive statistics and treatment summaries
- [x] Correlation structure among plant measurements
- [x] Subgroup-correlation check for Simpson's paradox across four groupings
- [x] Principal components on training site-years, retention by Kaiser's criterion
- [x] Cluster count by NbClust majority rule; cluster correspondence measured
- [x] Randomised complete block analysis of variance
- [x] Five pre-specified paired contrasts with Holm adjustment
- [x] Assumption tests, reported as they came out
- [x] Multivariate analysis of variance on four responses

## Evaluation — complete, `gate_05_modelling.R` PASS

- [x] Fix the predictor set by a rule and write the allowed and blocked lists
- [x] Split over site-years, constrained so every categorical level appears in
      training
- [x] Linear and random-forest models evaluated on held-out site-years
- [x] Leave-one-site-year-out cross-validation over all 34 folds
- [x] Quantify the two ways the estimate could have been inflated, labelled as
      illustrations

## Communication — complete, `gate_06_reproducibility.R` PASS

- [x] Twelve figures, each justified in `figure-plan.md`
- [x] Report rendered with `knitr::knit()` to GitHub-flavoured markdown
- [x] Write-up and README, every number read from `results/metrics.csv`
- [x] Cold start verified: raw data deleted, re-downloaded, pipeline rerun, all
      128 recorded quantities reproduced exactly

## Open items

- [ ] The sulfur sub-treatments are described but not analysed. A mixed model
      treating site-year as a random effect could use them, at the cost of
      leaning on a distributional assumption the current analysis avoids. Left
      undone deliberately; noted here so the omission is not mistaken for an
      oversight.
- [ ] The soil test is a single pre-season measurement per site-year, so
      soil-test effects are estimated on 34 points regardless of the 1211 plots.
      Nothing in the deposit can improve that.
