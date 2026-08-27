# Corn nutrient response in Nebraska

Multivariate analysis of a 34 site-year corn fertilizer trial, testing whether
applied phosphorus and potassium raised grain yield.

The analysis was completed as coursework for DATA_SCI 7020, Statistical and
Mathematical Foundations for Data Analytics, in **Spring 2025**. This repository
rebuilds that work from the original public dataset with the course scaffolding
removed, so that the methods and the reasoning behind them stand as a record in
their own right.

## The question

High yielding corn removes large quantities of phosphorus, potassium and sulfur
from the soil each season. Using data from Wortmann et al. (2022), it was
evaluated whether applied phosphorus and potassium increased yield once nitrogen
supply, plant stand and irrigation were accounted for. A second question was how
much of the variation in yield came from treatment at all, and how much from the
field and the season.

## The data

Wortmann, C. S., A. R. Dobermann, R. B. Ferguson, G. W. Hergert, C. A. Shapiro,
D. D. Tarkalson and D. T. Walters. *Data from: High-yielding corn response to
applied phosphorus, potassium, and sulfur in Nebraska.* Data Dryad,
[doi:10.5061/dryad.p30c6](https://doi.org/10.5061/dryad.p30c6). Released under
CC0.

The deposit holds 1483 plot observations from 34 site-years across Nebraska,
collected between 2002 and 2004, with 162 variables per plot. Nine standard
treatments were applied at every site-year. Five step nitrogen from zero to the
highest rate. Two omit phosphorus or potassium at a fixed nitrogen rate. One
doubles both. One applies the university recommended rates. An omission plot
differs from the complete treatment in a single nutrient, so the difference
between the two isolates that nutrient. Restricting the analysis to these nine
treatments leaves 1211 plots in 306 design cells, with two to four replicates in
each and no cell empty.

The raw data is not committed. `data/download_data.R` resolves the DOI through
the Dryad API and downloads the current version. It then verifies the extracted
workbook against the SHA-256 digest Dryad publishes in its own file metadata.
That digest, `62262f92…d2df`, is recorded in `data/checksums.txt` and checked on
every run, so the analyzed file can be shown to be the deposited file.

One correction was applied to the deposit. Soil texture class is recorded as
both `lS` and `ls`, the second at a single site-year. That site-year lies on the
Vetal soil series, which carries the `lS` label at two other site-years. The
deposit capitalizes the noun and leaves the modifier lowercase, giving `siCL` for
silty clay loam and `sL` for sandy loam, so `lS` denotes loamy sand. Loamy silt
is not a USDA texture class and would be written `lSi`. The two spellings were
merged, affecting 37 plots.

## What was found

Grain yield averaged 13.85 Mg/ha across the 1211 plots, with a standard deviation
of 2.21 Mg/ha. A site-year is one field in one season, and serves as the
experimental block. Differences between site-years account for 41 percent of the
plot-level sum of squares. Field and season therefore explain more of plot yield
than any treatment does. Comparing plots across fields would confound treatment
with field, so all comparisons were made within site-years, as paired differences
across the 34 blocks. P-values were adjusted by the Holm method, which controls
the chance of any false rejection across the family of five tests.

| Contrast | Effect on yield (Mg/ha) | 95 percent interval | p, Holm-adjusted |
|---|---:|---|---:|
| Nitrogen, none to mid rate | 3.61 | 2.85 to 4.37 | 2e-10 |
| Nitrogen, mid to high rate | 0.36 | 0.15 to 0.57 | 0.005 |
| Phosphorus applied against omitted | 0.19 | -0.10 to 0.48 | 0.39 |
| Potassium applied against omitted | -0.26 | -0.47 to -0.04 | 0.068 |
| Phosphorus and potassium doubled | 0.08 | -0.09 to 0.24 | 0.39 |

Nitrogen drove yield. The response was steep to the mid rate and small beyond it.
Neither phosphorus nor potassium produced a detectable response. No interval
admits an effect above roughly half a megagram per hectare, about one seventh of
the nitrogen response.

Two unsupervised methods were applied to fifteen plant measurements. Principal
component analysis retained four components under Kaiser's criterion, which keeps
components with an eigenvalue above one. Those four account for 78 percent of
total variance, and the first describes overall crop size. K-means clustering
used three clusters, set by majority vote across the 24 indices in the NbClust
package. The clusters correspond to site-year with a Cramér's V of 0.67 and to
treatment with 0.30, where Cramér's V measures association between two
categorical variables on a scale from zero to one. Both methods recovered the
field and not the treatment.

Yield was then predicted from pre-harvest information using
leave-one-site-year-out cross-validation. The model trains on 33 site-years and
is tested on the one held out, repeated 34 times, so every test is on an unseen
field. A random forest reached RMSE 1.95 Mg/ha and an R-squared of 0.22, against
2.24 Mg/ha for predicting the training mean. About one fifth of plot-level yield
variation is recoverable from applied rates, plant stand, irrigation and a
pre-season soil test.

These null results agree with the published analysis of the same trials.
Wortmann et al. (2009) report that phosphorus pays below about 10 ppm Bray-1 soil
test phosphorus, and that potassium response is unlikely above 125 ppm. Median
Bray-1 phosphorus in these site-years was 18 ppm and median potassium was 457
ppm, with 31 of 34 site-years above the potassium threshold. The absence of a
response is what that recommendation predicts for these fields.

Two limitations affect how far the results carry. The retained principal
components were difficult to map back onto individual measurements, so they
describe the data better than they guide a fertilizer decision. The predictors
also carry measurement error. Soil texture class is a field judgment and not a
laboratory determination, and this deposit records one class under two spellings.

`docs/writeup.md` works through the analysis step by step with the figures.
`analysis/report.md` carries the full tables. `docs/references.md` holds the
citations.

## Reproducing it

R 4.4.3. Dependencies are pinned with `renv`; `renv.lock` records 46 packages.
Neither `rmarkdown` nor pandoc is required.

```
Rscript -e 'renv::restore()'      # install the pinned packages
Rscript data/download_data.R      # fetch and verify the workbook from Dryad
Rscript analysis/run_all.R        # run the pipeline; writes figures/ and results/
Rscript -e 'knitr::knit("analysis/report.Rmd", output = "analysis/report.md")'
```

The pipeline completes in one to three minutes depending on machine load, and it
is seeded at 20250317. Every measured quantity in this README and in
`docs/writeup.md` is read out of `results/metrics.csv`, which the pipeline
writes. None of it is transcribed from an earlier analysis. Two remaining counts
describe the repository and not the results, namely the 46 packages in
`renv.lock` and the 128 quantities in `results/metrics.csv`.

## Layout

```
R/                  analysis modules, numbered by pipeline stage
analysis/run_all.R  orchestrates the pipeline and records every result
analysis/report.Rmd thin report: reads results/, presents and interprets
data/               download script, checksum, recorded schema
docs/               write-up with figures, and references
figures/            twelve generated figures
results/            generated tables and the recorded metrics
```

## How the work was checked

Each stage of the pipeline ends in a gate that exits zero or non-zero and prints
what it verified. The stages are acquisition, schema, preparation, analysis,
modeling and reproducibility, with an environment gate ahead of them.

The gates confirm that the join preserved every plot and that agronomic values
lie within physically plausible bounds. They check that the retained component
count follows Kaiser's criterion and that the cluster count follows the index
majority. They confirm that the training and test partitions share no site-year,
and that no model reported as predictive uses a harvest measurement. The final
gate reproduces all 128 recorded quantities exactly from an empty state.

Assumption tests are reported whichever way they came out. Residuals of the
plot-level analysis of variance fail a normality test, and the treatment
variances are unequal. The reported contrasts do not depend on that model. They
rest on paired differences over site-year means, whose own normality assumption
was tested and holds.

## Citation

If you use this analysis, cite the data:

> Wortmann, C. S., A. R. Dobermann, R. B. Ferguson, G. W. Hergert, C. A. Shapiro,
> D. D. Tarkalson and D. T. Walters (2022). Data from: High-yielding corn
> response to applied phosphorus, potassium, and sulfur in Nebraska. Data Dryad.
> doi:10.5061/dryad.p30c6

The trials were originally reported in Wortmann, C. S. et al. (2009).
High-yielding corn response to applied phosphorus, potassium, and sulfur in
Nebraska. *Agronomy Journal* 101(3):546-555, doi:10.2134/agronj2008.0103x.
Full citations, including the methods sources, are in `docs/references.md`.

## License

Code in this repository is released under the MIT License, in `LICENSE`. The
data is released by Data Dryad under CC0 and is not redistributed here.
