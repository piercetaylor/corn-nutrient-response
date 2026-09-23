# Corn nutrient response in Nebraska

This analysis uses 34 Nebraska corn trial site-years from Wortmann et al. (2022) to estimate yield responses to applied nitrogen, phosphorus, and potassium. It also tests how well pre-harvest measurements predict yield in a field excluded from model training. The work originated in DATA_SCI 7020 in Spring 2025.

## Data and findings

The [Dryad deposit](https://doi.org/10.5061/dryad.p30c6) contains 1,483 plot records from 2002–2004 and is released under CC0. The analysis uses 1,211 plots receiving the nine treatments shared by every site-year. The raw workbook is downloaded during reproduction and verified against Dryad's published SHA-256 digest.

Paired comparisons across site-years found a 3.61 Mg/ha yield increase from no nitrogen to the mid rate (95% interval 2.85–4.37). The further increase to the high rate was 0.36 Mg/ha (0.15–0.57). Applied phosphorus had an estimated effect of 0.19 Mg/ha (−0.10–0.48; Holm-adjusted p = 0.39). The potassium contrast was −0.26 Mg/ha (−0.47 to −0.04; Holm-adjusted p = 0.068). The intervals are unadjusted; neither nutrient met the adjusted significance criterion in these fields.

Site-year accounted for 41% of plot-level yield variation. In leave-one-site-year-out validation, a random forest predicted yield with RMSE 1.95 Mg/ha and R² 0.22. These results describe the sampled Nebraska fields; the trials had relatively high measured soil phosphorus and potassium, so they do not establish responses on deficient soils.

The estimates come from [`results/metrics.csv`](results/metrics.csv). The [analysis write-up](docs/writeup.md) explains the cleaning decisions, contrasts, figures, and assumptions. The [original detailed README](docs/legacy-readme.md) remains available as a record of the earlier presentation.

## Reproduce

The pipeline was run with R 4.4.3. Package versions are recorded in `renv.lock`. Run these commands from the repository root:

```sh
Rscript -e 'renv::restore()'
Rscript data/download_data.R
Rscript analysis/run_all.R
Rscript -e 'knitr::knit("analysis/report.Rmd", output = "analysis/report.md")'
```

The pipeline writes tables to `results/` and figures to `figures/`. Its stage gates check the workbook, plot joins, treatment design, analysis assumptions, and separation of training and test site-years. The full checks are described in the [write-up](docs/writeup.md).

## Citation and license

The data citation is Wortmann, C. S., et al. (2022), *Data from: High-yielding corn response to applied phosphorus, potassium, and sulfur in Nebraska*, Data Dryad, [doi:10.5061/dryad.p30c6](https://doi.org/10.5061/dryad.p30c6). [Full references](docs/references.md) include the 2009 trial report. The code is licensed under [MIT](LICENSE); the data remains CC0 and is not redistributed here.
