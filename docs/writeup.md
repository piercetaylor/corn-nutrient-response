# Findings

Corn in this trial averaged 13.85 Mg/ha across 1211 plots in 34 Nebraska
site-years, with a standard deviation of 2.21 Mg/ha. Differences between
site-years account for 41 percent of the plot-level sum of squares, making
field and season the largest single influence on yield. Comparisons are
therefore made within site-years, as paired differences across all 34.

Applied nitrogen produced a large response. Moving from no nitrogen to the mid
rate raised yield by 3.61 Mg/ha (95 percent interval 2.85 to 4.37,
Holm-adjusted p = 2.0e-10), and raising it further to the highest rate added
0.36 Mg/ha (0.15 to 0.57, p = 0.005). The response was steep to the mid rate
and nearly exhausted beyond it.

Applied phosphorus and potassium produced no detectable response. Omitting
phosphorus at a fixed nitrogen rate cost 0.19 Mg/ha, over an interval from
-0.10 to 0.48 that includes zero. Omitting potassium changed yield by
-0.26 Mg/ha (-0.47 to -0.04), which does not survive adjustment for the five
contrasts tested (p = 0.068) and runs opposite to a fertiliser response.
Doubling both at the highest nitrogen rate changed yield by 0.08 Mg/ha
(-0.09 to 0.24). No interval admits an effect larger than about half a
megagram per hectare, roughly a seventh of the nitrogen response. At the soil
test levels of this trial, replacing the phosphorus and potassium removed in
grain did not pay within a season.

Sulfur cannot be assessed, because the nine standard treatments all received a
similar low rate and the sulfur sub-treatments exist at only one or two
site-years each, confounding treatment with site.

The multivariate analyses agree. Principal components on fifteen plant
measurements retain four under Kaiser's criterion, accounting for 78 percent
of total variance, and the dominant axis describes crop size rather than
treatment. K-means clustering, with the count set at three by majority rule
across 24 NbClust indices, produces clusters that track site-year (Cramer's V
0.67) far more closely than treatment (0.30).

Prediction reaches the same ceiling. Using only pre-harvest information, and
leaving out one site-year at a time, a random forest reaches RMSE 1.95 Mg/ha
and an R-squared of 0.22, against 2.24 Mg/ha for predicting the training mean.
Applied nitrogen dominates the importance ranking, and the phosphorus and
potassium rates fall below every soil-test variable, confirming the
experimental result.

Two leakage traps are quantified. Admitting harvest measurements raises the
held-out R-squared from 0.21 to 0.97, almost all of it the identity that total
dry matter contains grain. Splitting over plots rather than site-years raises
it to 0.73, because replicate plots from one field are near-duplicates.

Two limitations bear on generality. The retained principal components are
difficult to map back onto individual measurements, so they describe the data
better than they guide a fertiliser decision. The predictors also carry
measurement error: soil texture class is a field judgement rather than a
laboratory determination, and this deposit records one class under two
spellings. A model fitted to such inputs will transfer imperfectly to a field
it has not seen.
