---
title: "Nutrient response in high-yielding Nebraska corn"
---





This report presents the results written by `analysis/run_all.R`. It reads the
recorded quantities in `results/` rather than recomputing them, so that the
numbers here and the numbers a gate checks are the same numbers. The analysis
code lives in `R/`; this file calls into it and interprets what it produced.
The seed is 20250317.

## The experiment

The deposit holds 1483 plot observations from
34 site-years of corn trials run in Nebraska between 2002
and 2004. Nine standard treatments were applied at every site-year, giving
1211 plots in 306 design cells with
2 to 4 replicate plots each
and no cell empty. The remaining 272 plots belong to
site-specific sub-trials present at between one and seven site-years, and are
excluded from every comparison below. Every site-year was irrigated, at rates
between 152 and 559 mm.

The nine treatments vary nitrogen across five rates and, at a fixed nitrogen
rate, omit phosphorus or potassium. That structure is what makes the phosphorus
and potassium questions answerable: the omission plots differ from the complete
treatment in one nutrient and nothing else.


Table: Applied rates in kg/ha and grain yield in Mg/ha.

|treatment | plots| site-years|     N|    P|    K|   S| mean yield|   sd|    se|
|:---------|-----:|----------:|-----:|----:|----:|---:|----------:|----:|-----:|
|N0P1K1    |   134|         34|   6.4| 20.0| 42.1| 5.3|      10.67| 2.56| 0.221|
|N1P1K1    |   135|         34|  96.7| 20.0| 42.4| 5.3|      13.38| 1.77| 0.152|
|N2P0K1    |   133|         34| 189.2|  0.0| 42.4| 5.4|      14.06| 1.88| 0.163|
|N2P1K0    |   135|         34| 188.6| 20.0|  0.0| 5.3|      14.48| 1.63| 0.140|
|N2P1K1    |   134|         34| 152.0| 20.0| 41.8| 5.3|      14.25| 1.78| 0.154|
|N3P1K1    |   135|         34| 208.1| 20.0| 42.1| 5.3|      14.44| 1.72| 0.148|
|N4P1K1    |   135|         34| 310.6| 20.0| 40.0| 5.3|      14.59| 1.67| 0.144|
|N4P2K2    |   136|         34| 310.4| 40.0| 84.7| 5.3|      14.67| 1.75| 0.150|
|UNL       |   134|         34| 163.1| 12.4|  4.8| 4.7|      14.07| 1.95| 0.168|

![Grain yield by treatment](../figures/fig01_yield_by_treatment.png)

## Where the variation lies

Mean grain yield over the standard plots is 13.85 Mg/ha with a
standard deviation of 2.21 Mg/ha, ranging from 3.66
to 19.01 Mg/ha. Differences between site-years account for
41 percent of the plot-level sum of squares.
A Nebraska field in a given season is therefore the largest single influence on
what a plot yields, which is why every comparison below is made within
site-years rather than across them.

![Distribution of plot yield](../figures/fig02_yield_distribution.png)

![The 34 site-years](../figures/fig05_site_years.png)

## Correlation structure, and where it misleads

The plant measurements are strongly redundant. Nutrient uptake is a tissue
concentration multiplied by a dry-matter mass that includes grain, and the
harvest indices are ratios among those same masses.

![Correlation among plant measurements](../figures/fig03_plant_correlations.png)

Pooled across all plots, grain yield and nitrogen uptake correlate at
0.75. That coefficient survives disaggregation: the
weakest within-texture coefficient is
0.76, and within site-years the median
is 0.87 with a minimum of
0.44. No sign reverses, so the pooled
figure is not an aggregation artefact.

![Yield against nitrogen uptake by texture](../figures/fig04_yield_vs_n_uptake_by_texture.png)

Plant population behaves differently. Pooled, yield and population correlate at
0.23; within site-years the coefficient falls as
low as -0.25 and reverses sign in
5 of the
34 site-years. The pooled association largely
records that the fields planted at higher densities were the fields that yielded
more for other reasons, not that raising density within a field raised yield.
This is the one place in the data where a pooled correlation would have been
read wrongly.


Table: Pooled against within-site-year correlations with grain yield.

|x          |y           | pooled r| site-years| min within| median within| max within| sign reversals|
|:----------|:-----------|--------:|----------:|----------:|-------------:|----------:|--------------:|
|n_uptake   |grain_yield |    0.754|         34|      0.437|         0.869|      0.955|              0|
|p_uptake   |grain_yield |    0.488|         34|      0.119|         0.662|      0.881|              0|
|k_uptake   |grain_yield |    0.521|         34|      0.208|         0.788|      0.950|              0|
|population |grain_yield |    0.234|         34|     -0.251|         0.196|      0.532|              5|

## Dimension reduction

Principal components were fitted on the 15 standardised
plant measurements, using the 24 training
site-years only. Kaiser's criterion retains 4
components, accounting for 78 percent of total
variance; the first accounts for 37 percent and the
second for 23 percent.

![Component eigenvalues](../figures/fig07_pca_scree.png)


Table: Loadings on the retained components.

|variable        |    PC1|    PC2|    PC3|    PC4|
|:---------------|------:|------:|------:|------:|
|grain_yield     | -0.322|  0.281| -0.239|  0.109|
|total_dm        | -0.401| -0.022| -0.174| -0.034|
|harvest_index   |  0.148|  0.454| -0.087|  0.155|
|ears            |  0.019| -0.012| -0.676| -0.117|
|kernels_per_ear | -0.242|  0.217|  0.305| -0.320|
|kernel_weight   | -0.203|  0.177| -0.045|  0.592|
|barren_pct      | -0.009| -0.062|  0.299|  0.615|
|n_uptake        | -0.395|  0.035| -0.109|  0.023|
|p_uptake        | -0.304|  0.079|  0.261| -0.037|
|k_uptake        | -0.385| -0.118| -0.092| -0.045|
|s_uptake        | -0.388|  0.019|  0.145| -0.005|
|n_hi            |  0.146|  0.406| -0.110|  0.102|
|p_hi            | -0.131|  0.342|  0.113| -0.275|
|k_hi            |  0.153|  0.356|  0.310| -0.163|
|s_hi            |  0.073|  0.450| -0.179|  0.018|

![Plots in the first two components](../figures/fig08_pca_scores.png)

The components describe the redundancy among harvest measurements. They are not
used to predict yield, because grain yield is an algebraic component of several
of the variables they are built from.

## Clustering

The number of clusters was chosen by majority rule across the indices NbClust
computes, not fixed in advance: 7 of
24 indices selected
k = 3. The resulting partition accounts for
35 percent of the total sum of squares.


Table: Association between cluster membership and candidate explanations.

|grouping  | cramers_v|
|:---------|---------:|
|site_yr   |     0.674|
|treatment |     0.300|
|texture   |     0.283|
|tillage   |     0.087|
|prev_crop |     0.229|

Cluster membership tracks site-year (Cramer's V
0.67) far more closely than treatment
(0.30). The clusters recover which field a plot
was in, not what was applied to it.

![Clusters against field position](../figures/fig09_clusters.png)

## Treatment effects

The design is a randomised complete block with site-year as the block.


Table: Analysis of variance on grain yield, blocked on site-year.

|term      |   df| sum_sq| mean_sq|f     |p         |
|:---------|----:|------:|-------:|:-----|:---------|
|block     |   33| 2434.0|   73.76|48.7  |1.07e-193 |
|treatment |    8| 1702.2|  212.77|140.5 |3.77e-165 |
|Residuals | 1169| 1770.3|    1.51|      |          |

Treatment affects yield (F = 140.5,
p = 3.77e-165), as does site-year
(F = 48.7). A multivariate test on grain yield, total dry
matter, ear number and nitrogen uptake jointly agrees (Pillai's trace
1.015, p = 6.77e-48).

The five pre-specified contrasts are estimated as paired differences of
site-year means across all 34 blocks, so that the
unit of inference is the site-year and not the plot.


Table: Paired contrasts on grain yield, Mg/ha, with 95 percent intervals.

|contrast                                                 | estimate| ci low| ci high|p        |p holm   |
|:--------------------------------------------------------|--------:|------:|-------:|:--------|:--------|
|nitrogen response (N2 against N0)                        |    3.611|  2.849|   4.374|4.06e-11 |2.03e-10 |
|nitrogen response (N4 against N2)                        |    0.362|  0.154|   0.570|1.20e-03 |4.80e-03 |
|phosphorus omission (P1 against P0 at N2)                |    0.190| -0.102|   0.482|1.94e-01 |3.88e-01 |
|potassium omission (K1 against K0 at N2)                 |   -0.257| -0.475|  -0.038|2.25e-02 |6.76e-02 |
|doubled phosphorus and potassium (N4P2K2 against N4P1K1) |    0.080| -0.085|   0.244|3.33e-01 |3.88e-01 |

![Treatment contrasts](../figures/fig10_treatment_contrasts.png)

Applying nitrogen at the mid rate raised yield by
3.61 Mg/ha
(95 percent interval 2.85 to
4.37). Raising nitrogen further to the
high rate added 0.36 Mg/ha
(0.15 to
0.57).

Omitting phosphorus at a fixed nitrogen rate cost
0.19 Mg/ha, with an interval from
-0.10 to
0.48 that includes zero. Omitting
potassium changed yield by
-0.26 Mg/ha, and doubling both phosphorus
and potassium at the high nitrogen rate changed it by
0.08 Mg/ha
(-0.09 to
0.24). At these soil test levels and
yields, none of the three intervals admits a phosphorus or potassium response
larger than about half a megagram per hectare.

### Assumptions


Table: Assumption tests for the plot-level analysis of variance.

|test                            | statistic|  p|
|:-------------------------------|---------:|--:|
|Shapiro-Wilk on residuals       |    0.9748|  0|
|Brown-Forsythe across treatment |    5.7557|  0|
|Brown-Forsythe across block     |    2.3196|  0|

Both assumptions of the plot-level analysis of variance are violated. Residuals
depart from normality (W = 0.9748,
p = 1.07e-13) and variances differ across treatments
(p = 3.23e-07), which is expected when one
treatment withholds nitrogen and yields both lower and more variably than the
rest. The F test is reported because it is robust at this sample size, but it is
not what the conclusions rest on.


Table: Normality of the block differences the paired contrasts use.

|contrast                                                 |  n| statistic|      p|
|:--------------------------------------------------------|--:|---------:|------:|
|nitrogen response (N2 against N0)                        | 34|    0.9523| 0.1434|
|nitrogen response (N4 against N2)                        | 34|    0.9638| 0.3118|
|phosphorus omission (P1 against P0 at N2)                | 34|    0.9765| 0.6589|
|potassium omission (K1 against K0 at N2)                 | 34|    0.9883| 0.9688|
|doubled phosphorus and potassium (N4P2K2 against N4P1K1) | 34|    0.9777| 0.7001|

The paired contrasts require only that the
34 block differences are approximately normal, and
they are: the smallest p across the five contrasts is
0.143.

## Predicting yield on an unfamiliar field

A predictor was admitted only if its value is set or measurable before harvest.
That leaves 18 predictors and excludes
20 harvest measurements. The exclusion is
arithmetic rather than cautious: total dry matter is the sum of grain, cob and
stover dry matter, an identity this data set satisfies to a maximum relative
error of 0.00e+00, and harvest index is grain dry matter
divided by that sum.

Partitions are formed over site-years. A model is trained on
24 site-years and tested on the
351 plots of the 10 it
has never seen.


Table: Accuracy on held-out site-years. RMSE and MAE in Mg/ha.

|model                                  |role         | n_predictors| n_test|  rmse|   mae|     r2|
|:--------------------------------------|:------------|------------:|------:|-----:|-----:|------:|
|training mean                          |baseline     |            0|    351| 2.154| 1.733| -0.148|
|linear model, agronomic predictors     |predictive   |           12|    351| 2.008| 1.681|  0.002|
|linear model, all admitted predictors  |predictive   |           18|    351| 1.808| 1.404|  0.190|
|random forest                          |predictive   |           18|    351| 1.782| 1.490|  0.214|
|linear model with harvest measurements |illustration |           20|    351| 0.358| 0.259|  0.968|
|random forest, plot-level split        |illustration |           18|    363| 1.151| 0.855|  0.727|

Because a single ten-site-year test set is a noisy basis for that claim, the
comparison is repeated leaving out one site-year at a time, so that every
site-year serves as an unfamiliar field exactly once.


Table: Leave-one-site-year-out cross-validation over all 34 site-years.

|model                               | n_folds|    n|  rmse|   mae|     r2|
|:-----------------------------------|-------:|----:|-----:|-----:|------:|
|training mean                       |      34| 1211| 2.236| 1.750| -0.025|
|linear model, agronomic predictors  |      34| 1211| 2.116| 1.678|  0.082|
|random forest, agronomic predictors |      34| 1211| 1.950| 1.553|  0.221|

The random forest reaches RMSE 1.950 Mg/ha and an R-squared of
0.221, against 2.236 Mg/ha for predicting the
training mean. Roughly a fifth of plot-level yield variation is recoverable from
applied rates, plant stand, irrigation and a pre-season soil test. The rest
belongs to the field and the season.

![Predicted against observed](../figures/fig11_observed_vs_predicted.png)

![Variable importance](../figures/fig12_variable_importance.png)

### Two ways this number could have been inflated

Admitting harvest measurements as predictors raises the held-out R-squared from
0.214 to 0.968. Almost all of that is the
identity above, reported back as accuracy.

Splitting over plots rather than site-years raises the held-out R-squared of the
same random forest from 0.214 to
0.727. Replicate plots from one field in one season
are near-duplicates, and a plot-level split leaves copies of the test plots in
the training set. Both figures are reported in the table above as illustrations,
not as results.

## Session


```
run date: 2026-08-26

R version 4.4.3 (2025-02-28 ucrt)
Platform: x86_64-w64-mingw32/x64
Running under: Windows 11 x64 (build 26200)

Matrix products: default


locale:
[1] LC_COLLATE=English_United States.utf8 
[2] LC_CTYPE=English_United States.utf8   
[3] LC_MONETARY=English_United States.utf8
[4] LC_NUMERIC=C                          
[5] LC_TIME=English_United States.utf8    

time zone: America/Chicago
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices datasets  utils     methods   base     

other attached packages:
[1] tidyr_1.3.1          randomForest_4.7-1.2 NbClust_3.0.1       
[4] ggplot2_4.0.1        dplyr_1.1.4          readxl_1.5.0        

loaded via a namespace (and not attached):
 [1] vctrs_0.6.5        nlme_3.1-168       cli_3.6.5          rlang_1.1.6       
 [5] purrr_1.2.0        renv_1.1.5         generics_0.1.4     S7_0.2.1          
 [9] labeling_0.4.3     glue_1.8.0         corrplot_0.95      scales_1.4.0      
[13] grid_4.4.3         cellranger_1.1.0   tibble_3.2.1       yaml_2.3.11       
[17] lifecycle_1.0.4    compiler_4.4.3     RColorBrewer_1.1-3 pkgconfig_2.0.3   
[21] mgcv_1.9-3         lattice_0.22-6     farver_2.1.2       viridisLite_0.4.2 
[25] R6_2.6.1           tidyselect_1.2.1   splines_4.4.3      pillar_1.11.1     
[29] magrittr_2.0.3     Matrix_1.7-2       tools_4.4.3        withr_3.0.2       
[33] gtable_0.3.6      
```
