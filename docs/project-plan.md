# Project plan

## Question

Nebraska corn yielding fourteen megagrams per hectare removes large quantities of
phosphorus, potassium and sulfur from the soil each season. Whether replacing
those nutrients raises yield is a separate question from whether the crop
contains them, and it is the question a grower has to answer when deciding what
to apply. This analysis asks it of a field trial built to answer it: what does
grain yield gain from applied phosphorus, potassium and sulfur once nitrogen
supply, plant stand and water are accounted for, and how much of the variation
in yield is attributable to treatment at all rather than to the field and the
season.

Three sub-questions follow, and the repository answers them in this order.

1. How is variation in plot yield partitioned between site-years and treatments?
2. What is the size, with an interval, of the yield response to nitrogen, and to
   the omission of phosphorus or potassium at a fixed nitrogen rate?
3. How much of plot yield can be predicted for a field the analysis has never
   seen, from information available before harvest?

## Data

The trial is deposited at Data Dryad under doi:10.5061/dryad.p30c6, released
under CC0. It holds 1483 plot observations from 34 site-years run across
Nebraska between 2002 and 2004, with 162 recorded variables per plot covering
applied rates, yield and its components, dry-matter partitioning, nutrient
uptake, and the soil test taken before the season.

Nine standard treatments were applied at every site-year. Five of them step
nitrogen from zero to the highest rate at fixed phosphorus and potassium; two
omit phosphorus or potassium at a fixed mid nitrogen rate; one doubles both at
the high nitrogen rate; one applies the university's recommended rates. That is
a nutrient-omission design, and it is the reason the phosphorus and potassium
questions are answerable here: the omission plots differ from the complete
treatment in one nutrient and in nothing else.

## Lifecycle and phases

The work is organised into seven phases. Each ends in a gate script under
`.checks/` that exits zero or non-zero and prints what it verified. A failing
gate stops the phase; the recorded outcome of every gate run is in
`execution-log.md`.

| Phase | Question it settles | Gate |
|---|---|---|
| Problem definition | Is there a question the design can answer, and what would count as an answer | reviewed in this document; no script |
| Acquisition | Is the file being analysed the file that was deposited | `gate_01_acquisition.R` |
| Data understanding | Does the workbook have the shape the code was written against | `gate_02_schema.R` |
| Preparation | Did the join, filter and typing change anything they should not have | `gate_03_preparation.R` |
| Analysis and modelling | Are the multivariate and inferential results internally consistent, and were they produced by the stated criteria | `gate_04_analysis.R` |
| Evaluation | Do the held-out estimates mean what they are said to mean | `gate_05_modelling.R` |
| Communication | Does the pipeline reproduce itself, and does the report render | `gate_06_reproducibility.R` |

`gate_00_environment.R` runs ahead of the others and checks that the R version,
the installed packages and the lockfile agree with what the analysis declares.

## Scope: what was kept

**Ingestion and preparation of the deposited workbook.** Three of the six
worksheets are read: the plot-level data, the site-year lookup, and the
depositors' variable dictionary. The site-year lookup is joined onto the plots
and the analysis is restricted to the nine standard treatments.

**Univariate and multivariate description.** Distributions, treatment summaries,
and the correlation structure among plant measurements.

**A subgroup-correlation check for Simpson's paradox.** Pooled correlations are
recomputed within texture class, tillage, previous crop and site-year, and sign
reversals are counted. This earns its place because most of the variation in
this data set lies between site-years, which is exactly the condition under
which a pooled correlation misdescribes a within-field relationship.

**K-means clustering with the cluster count selected by NbClust.** The count is
fixed by majority rule across the indices rather than chosen by eye, and the
resulting partition is compared against site-year and against treatment to
establish what the clusters actually recover.

**Principal components with a train-test split and Kaiser's criterion.**
Fitted on the training site-years and projected onto the held-out ones.

**Blocked analysis of variance, planned contrasts, and multivariate analysis of
variance.** The design is a randomised complete block with site-year as the
block, and it is analysed as one. The five contrasts the design was built to
estimate are tested as paired differences of site-year means. Assumptions are
tested and reported whichever way they come out.

**Predictive modelling of grain yield with held-out evaluation.** Linear and
random-forest models on a predictor set fixed by a rule, evaluated on site-years
the models never saw, and cross-validated by leaving out one site-year at a time.

## Scope: what was dropped, and why

**Factor analysis.** The plant measurements are redundant because of arithmetic
relationships among them, not because of latent constructs. Principal components
describe that redundancy adequately; a rotated factor solution on the same
variables would restate it in a vocabulary the data does not warrant.

**Chi-squared tests of tillage against texture and previous crop against
texture.** Tillage, texture and previous crop are properties of a site-year, not
of a plot. A contingency table built from 1211 plots treats the 34 site-years as
though they were 1211 independent observations, which inflates the test
statistic by roughly the replication factor and makes the p-value meaningless. A
test at the site-year level would have 34 observations spread over fifteen or
more cells and no useful power. The relationships are real features of how the
trial was sited, and they are reported descriptively, but they are not tested.

**Random forest and decision tree classifiers for tillage and soil texture.**
These predicted a site-year attribute from plot measurements taken at that
site-year, with latitude and longitude among the predictors. High accuracy
follows from the fact that position identifies the field and the field
determines the label; the classifier recovers the experiment's own layout. The
same modelling capacity is used here for a question where held-out evaluation
means something, namely predicting grain yield on unseen site-years.

**Total dry matter and harvest index as predictors of grain yield.** Total dry
matter is the sum of grain, cob and stover dry matter, and this data set
satisfies that identity to a maximum relative error of zero. Harvest index is
grain dry matter divided by that sum. A yield model given either is reporting an
identity. The effect is quantified in the report as an illustration and excluded
from every result.

**The English-unit duplicates, the micronutrient soil tests, and the per-organ
nutrient concentrations.** Each is either a unit conversion of a retained
variable or a component of a retained total.

**Sulfur response.** The nine standard treatments all received a similar low
rate of sulfur, so the balanced design contains no sulfur contrast. The sulfur
sub-treatments exist only at one or two site-years each, which confounds any
comparison with site. Sulfur uptake is described; sulfur response is not
estimated, and the reason is stated in the write-up rather than left implicit.

## Decisions that shape the results

**Site-year is the block and the unit of inference.** Plots within a site-year
share a field, a hybrid, a planting date and a season. Every contrast is
estimated as a paired difference of site-year means, and every train-test split
is formed over site-years rather than plots.

**Predictors are admitted by a rule, not by search.** A variable enters the
yield models only if its value is set or measurable before harvest. The rule is
written down in `R/06_models.R` as two explicit lists, and the modelling gate
checks the models against them rather than against a claim.

**Treatments 10 to 12 are excluded from inference.** They are site-specific
sub-trials present at between one and seven site-years, so any contrast drawn
from them confounds treatment with site. They remain in the full frame for
description.

## Dependencies

Pinned with `renv`. `renv.lock` records 46 packages and R 4.4.3 and is
committed; `renv/library/` is not. `renv` was chosen over a hand-written
manifest because it installed cleanly here, because it pins transitive
dependencies as well as direct ones, and because `renv::status()` gives a
mechanical answer to whether the declared environment is the environment in use.
`rmarkdown` is listed in `renv/settings.json` as ignored: `renv` infers it from
the presence of an `.Rmd` file, but the report is rendered with `knitr::knit()`
alone, and neither `rmarkdown` nor pandoc is required.

## Licence

MIT for the code, documentation and generated outputs. It is the conventional
choice for analysis code, it imposes no conditions on reuse beyond attribution,
and it is compatible with the CC0 terms of the data. The data itself is not
redistributed here and is covered separately; `LICENSE` states both.
