# Findings

Corn in this trial averaged 13.85 Mg/ha across 1211 plots in 34 Nebraska
site-years, with a standard deviation of 2.21 Mg/ha. Differences between
site-years account for 41 percent of the plot-level sum of squares, so the
field and the season are the largest single influence on what a plot yields.
Every comparison below is therefore made within site-years.

Applied nitrogen produced a large response. Moving from no nitrogen to the mid
rate raised yield by 3.61 Mg/ha (95 percent interval 2.85 to 4.37, Holm-adjusted
p = 2.0e-10). Raising nitrogen further to the highest rate added 0.36 Mg/ha
(0.15 to 0.57, p = 0.005), so the response was steep to the mid rate and nearly
exhausted beyond it.

Applied phosphorus and potassium produced no detectable response. Omitting
phosphorus at a fixed nitrogen rate cost 0.19 Mg/ha, with an interval from
-0.10 to 0.48 that includes zero. Omitting potassium changed yield by
-0.26 Mg/ha (-0.47 to -0.04), which does not survive adjustment for the five
contrasts tested (p = 0.068) and is in the direction opposite to a fertiliser
response. Doubling both phosphorus and potassium at the highest nitrogen rate
changed yield by 0.08 Mg/ha (-0.09 to 0.24). The intervals are the useful
reading: none admits a phosphorus or potassium effect larger than about half a
megagram per hectare, roughly a seventh of the nitrogen response. At the soil
test levels and yields of this trial, replacing phosphorus and potassium removed
in grain did not pay in yield within a season.

Sulfur cannot be assessed here: the nine standard treatments all received a
similar low sulfur rate, and the sulfur sub-treatments exist at only one or two
site-years each, confounding treatment with site.

The multivariate structure agrees. Principal components on fifteen plant
measurements retain four under Kaiser's criterion, accounting for 78 percent of
total variance, and the dominant axis describes crop size rather than treatment.
K-means clustering, with the count fixed at three by majority rule across 24
NbClust indices, yields clusters tracking site-year (Cramer's V 0.67) far more
closely than treatment (0.30). Both methods recover which field a plot was in.

Prediction meets the same limit from the other direction. Using only information
available before harvest, and leaving out one site-year at a time, a random
forest reaches RMSE 1.95 Mg/ha and an R-squared of 0.22, against 2.24 Mg/ha for
predicting the training mean. Roughly a fifth of plot-level yield variation is
recoverable from applied rates, plant stand, irrigation and a pre-season soil
test. Applied nitrogen dominates the importance ranking; the phosphorus and
potassium rates fall below every soil-test variable, which is the experimental
result reached again by a different route.

Two cautions are quantified rather than asserted. Admitting harvest measurements
as predictors raises the held-out R-squared from 0.21 to 0.97, almost all of it
the identity that total dry matter contains grain dry matter. Splitting over
plots rather than site-years raises it from 0.21 to 0.73, because replicate
plots from one field in one season are near-duplicates.
