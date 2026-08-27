
# Corn nutrient response in Nebraska

A multivariate re-analysis of a 34 site-year field trial on the response of
high-yielding corn to applied phosphorus, potassium and sulfur.

The analysis was completed as coursework for DATA_SCI 7020, Statistical and
Mathematical Foundations for Data Analytics, in **Spring 2025**. This repository
rebuilds that work from the original public dataset with the course scaffolding
removed, so that the methods and the reasoning behind them stand as a record in
their own right.

## The question

A corn crop yielding fourteen megagrams per hectare removes a substantial
quantity of phosphorus, potassium and sulfur from the soil each season. Whether
replacing those nutrients raises yield is a separate question from whether the
crop contains them, and it is the question a grower actually has to answer.
This analysis estimates how much yield gains from applied phosphorus and
potassium once nitrogen supply, plant stand and water are accounted for, and it
asks how much of the variation in yield is attributable to treatment at all
rather than to the field and the season.

## The data

Wortmann, C. S., A. R. Dobermann, R. B. Ferguson, G. W. Hergert, C. A. Shapiro,
D. D. Tarkalson and D. T. Walters. *Data from: High-yielding corn response to
applied phosphorus, potassium, and sulfur in Nebraska.* Data Dryad,
[doi:10.5061/dryad.p30c6](https://doi.org/10.5061/dryad.p30c6). Released under
CC0.

The deposit holds 1483 plot observations from 34 site-years run across Nebraska
between 2002 and 2004, with 162 recorded variables per plot. Nine standard
treatments were applied at every site-year, giving 1211 plots in 306 design cells
with two to four replicates each and no cell empty. Five treatments step nitrogen
from zero to the highest rate; two omit phosphorus or potassium at a fixed
nitrogen rate; one doubles both at the high rate; one applies the university's
recommended rates. That nutrient-omission structure is what makes the phosphorus
and potassium questions answerable, because an omission plot differs from the
complete treatment in one nutrient and in nothing else.

The raw data is not committed. `data/download_data.R` resolves the DOI through
the Dryad API, downloads the current version, and verifies the extracted
workbook against the SHA-256 digest that Dryad publishes in its own file
metadata. That digest, `62262f92…d2df`, is recorded in `data/checksums.txt` and
re-verified on every run, so the file being analyzed can be shown to be the file
that was deposited rather than a local copy of unknown history.

One correction is applied to the deposit as recorded. The soil texture class is
spelled both `lS` and `ls`, the latter at a single site-year. That site-year,
Spurgin in 2004, lies on the Vetal soil series, which carries the `lS` label at
Paxton in 2002 and 2003. The deposit also capitalizes the noun and leaves the
modifier in lower case, giving `siCL`, `siL` and `sL` for silty clay loam, silt
loam and sandy loam, so `lS` reads as loamy sand and `ls` departs from the
convention in case alone. Loamy silt is not a USDA texture class and would in
any case be written `lSi`. The two spellings are therefore treated as one class,
affecting 37 plots, and the count is carried through the pipeline as an
attribute so that the correction appears in the record rather than passing
silently.

## What was found

Grain yield averaged 13.85 Mg/ha across the 1211 standard plots, with a standard
deviation of 2.21 Mg/ha. A site-year means one field in one season, and it serves
as the experimental block here. Differences between site-years account for 41
percent of the plot-level sum of squares, which is to say the field and the
season explain more of what a plot yields than any treatment does. Comparing
plots from different fields would therefore confound the treatment effect with
the field effect, so every comparison below is made within site-years, as paired
differences across all 34 blocks. Reported p-values are adjusted by the Holm
method, which controls the chance of any false rejection across the family of
five tests rather than treating each one alone.

| Contrast | Effect on yield (Mg/ha) | 95 percent interval | p, Holm-adjusted |
|---|---:|---|---:|
| Nitrogen, none to mid rate | 3.61 | 2.85 to 4.37 | 2e-10 |
| Nitrogen, mid to high rate | 0.36 | 0.15 to 0.57 | 0.005 |
| Phosphorus applied against omitted | 0.19 | -0.10 to 0.48 | 0.39 |
| Potassium applied against omitted | -0.26 | -0.47 to -0.04 | 0.068 |
| Phosphorus and potassium doubled | 0.08 | -0.09 to 0.24 | 0.39 |

Nitrogen drives yield, steeply to the mid rate and little beyond it. Applied
phosphorus and potassium produce no detectable response, and the intervals bound
what could have been missed: none admits an effect larger than about half a
megagram per hectare, roughly a seventh of the nitrogen response.

Two unsupervised methods were applied to the plant measurements, and both
recovered the field rather than the treatment. Principal component analysis
retained four of fifteen components under Kaiser's criterion, which keeps a
component whose eigenvalue exceeds one and so explains more variance than a
single original variable would; those four account for 78 percent of total
variance, and the dominant axis describes overall crop size. K-means clustering
was run with the number of clusters set to three by majority vote across the 24
indices computed by the NbClust package, rather than fixed in advance. Those
clusters correspond to site-year with a Cramér's V of 0.67 and to treatment with
only 0.30, where Cramér's V measures association between two categorical
variables on a scale from zero to one.

Yield was then predicted from information available before harvest, using
leave-one-site-year-out cross-validation, in which the model trains on 33
site-years and is tested on the one held out, repeated 34 times so that every
test is on a field the model has not seen. A random forest reached RMSE 1.95
Mg/ha and an R-squared of 0.22, against 2.24 Mg/ha for predicting the training
mean. About a fifth of plot-level yield variation is therefore recoverable from
applied rates, plant stand, irrigation and a pre-season soil test, and the
remainder belongs to the field and the season.

These null results agree with the published analysis of the same trials.
Wortmann et al. (2009) found that phosphorus pays when Bray-1 soil test
phosphorus is below about 10 ppm, and that potassium response is unlikely above
125 ppm. These site-years sat mostly above both thresholds, with median Bray-1
phosphorus of 18 ppm and median potassium of 457 ppm, so the absence of a
response is what the existing recommendation predicts for these particular
fields rather than evidence against fertilizing in general.

Two limitations affect how far the results carry. The retained principal
components proved difficult to map back onto individual measurements, so they
describe the data better than they guide a fertilizer decision. The predictors
also carry measurement error of their own, since soil texture class is a field
judgment rather than a laboratory determination, and this deposit records one
texture class under two spellings.

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

The pipeline completes in one to three minutes depending on machine load, and
it is seeded at 20250317. Every measured quantity reported in this README and in `docs/writeup.md` is read out of
`results/metrics.csv`, which the pipeline writes, and none of it is transcribed
from an earlier analysis. The few remaining figures are counts of the repository
itself rather than results, namely the 46 packages recorded in `renv.lock` and
the 128 quantities held in `results/metrics.csv`.

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

Each phase of the lifecycle ends in a gate that exits zero or non-zero and
prints what it verified: acquisition, schema, preparation, analysis, modeling
and reproducibility, with an environment gate ahead of them. The gates check
that the join preserved every plot, that agronomic values lie within physically
plausible bounds, that the retained component count follows Kaiser's criterion
and the cluster count follows the index majority, that the train and test
partitions are disjoint over site-years, that no model reported as predictive
uses a harvest measurement, and that the pipeline reproduces all 128 recorded
quantities exactly from an empty state. `docs/execution-log.md` records every
gate run with its outcome and evidence.

Assumption tests are reported whichever way they come out. The residuals of the
plot-level analysis of variance fail a normality test and the treatment
variances are unequal; the analysis relies instead on paired contrasts over
site-year means, whose own normality assumption is tested and holds.

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

MIT for the code and generated outputs; see `LICENSE`. The data is not
redistributed here and is separately released under CC0 by its depositors.
