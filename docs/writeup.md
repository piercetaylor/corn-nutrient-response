# Project write-up

## Research question

A corn crop yielding fourteen megagrams per hectare removes a large quantity of
phosphorus, potassium and sulfur from the soil each season. Growers are
routinely advised to replace what the crop removes. Whether that replacement
actually raises yield is a separate question from whether the grain contains the
nutrient, and it is the question that determines whether the fertilizer is worth
buying.

This project asks two things. First, how much does grain yield gain from applied
phosphorus and potassium once nitrogen supply, plant population and irrigation
are accounted for? Second, how much of the variation in yield is attributable to
treatment at all, rather than to the field and the season in which the plot was
grown?

## Loading and cleaning the data

The data come from a Data Dryad deposit covering 34 site-years of irrigated corn
trials run across Nebraska between 2002 and 2004. A site-year is one field in one
season, and it is the experimental block throughout this analysis. The deposit
holds 1483 plot observations with 162 recorded variables each.

Three cleaning decisions shaped everything downstream. Only metric measurements
were retained, because the deposit records most quantities twice, once in metric
and once in English units, and keeping both would have created perfectly
collinear pairs. Analysis was restricted to the nine standard treatments applied
at every site-year, which excluded 272 plots belonging to site-specific
treatments numbered 10 to 12 that exist at only one or two locations. That
restriction leaves 1211 plots arranged in 306 design cells with two to four
replicates each and no cell empty, which is what makes the treatment comparisons
balanced.

The third decision corrected the deposit itself. Soil texture class is recorded
as both `lS` and `ls`, the latter at a single site-year. That site-year lies on
the Vetal soil series, which carries the `lS` label elsewhere in the same file.
The deposit capitalizes the noun and leaves the modifier lowercase, giving `siCL`
for silty clay loam and `sL` for sandy loam, so `lS` reads as loamy sand. The two
spellings were merged, affecting 37 plots.

The treatment structure is what makes the question answerable. Five treatments
step nitrogen from zero to the highest rate, two omit phosphorus or potassium at
a fixed nitrogen rate, one doubles both, and one applies the university's
recommended rates. An omission plot differs from the complete treatment in one
nutrient and in nothing else, so the difference between them isolates that
nutrient.

![Trial structure across Nebraska](../figures/fig05_site_years.png)

## Exploratory data analysis

Yield across the 1211 standard plots averaged 13.85 Mg/ha with a standard
deviation of 2.21 Mg/ha, ranging from 3.66 to 19.01 Mg/ha.

![Distribution of grain yield](../figures/fig02_yield_distribution.png)

The single most important structural fact emerged here. Differences between
site-years account for 41 percent of the plot-level sum of squares, which means
the field and the season together explain more of what a plot yields than any
treatment does. Comparing plots from different fields would therefore confound
the treatment effect with the field effect, and every comparison reported below
is instead made within site-years, as paired differences across all 34 blocks.

Correlations among the plant measurements are strong and largely structural,
since grain, cob and stover dry matter sum to total dry matter by definition.

![Correlations among plant measurements](../figures/fig03_plant_correlations.png)

Checking those correlations within subgroups rather than pooled proved
worthwhile. The pooled correlation between yield and nitrogen uptake is 0.75,
but within individual site-years it ranges from 0.44 to a median of 0.87. For
plant population the pooled correlation of 0.23 reverses sign inside five
site-years. This is Simpson's paradox, in which an association computed across
pooled groups can differ from, or oppose, the association within every group.

![Yield against nitrogen uptake by soil texture](../figures/fig04_yield_vs_n_uptake_by_texture.png)

## Feature engineering

Principal component analysis was applied to fifteen standardized plant
measurements to reduce that redundancy. Four components were retained under
Kaiser's criterion, which keeps components whose eigenvalue exceeds one, meaning
the component explains more variance than a single original variable would. Those
four account for 78 percent of total variance, and the first alone accounts for
37 percent. Inspecting its loadings shows it describes overall crop size rather
than any treatment contrast.

![Scree plot of component variances](../figures/fig07_pca_scree.png)
![Plots in the space of the first two components](../figures/fig08_pca_scores.png)

K-means clustering was run to see whether plots group by treatment. The number of
clusters was not fixed in advance but set to three by majority vote across 24
indices computed by the NbClust package, seven of which favored three. The
resulting clusters were compared against site-year and against treatment using
Cramér's V, a measure of association between two categorical variables running
from zero for independence to one for perfect correspondence. The clusters track
site-year at 0.67 and treatment at only 0.30, so the clustering recovers which
field a plot came from rather than how it was fertilized.

![Cluster assignment against site-year](../figures/fig09_clusters.png)

## Modeling and hypothesis testing

Five treatment contrasts were tested, each as a paired difference of site-year
means across all 34 blocks. P-values were adjusted by the Holm method, which
controls the probability of making any false rejection across the whole family of
five tests rather than treating each in isolation.

| Contrast | Effect (Mg/ha) | 95 percent interval | p, Holm-adjusted |
|---|---:|---|---:|
| Nitrogen, none to mid rate | 3.61 | 2.85 to 4.37 | 2e-10 |
| Nitrogen, mid to high rate | 0.36 | 0.15 to 0.57 | 0.005 |
| Phosphorus applied against omitted | 0.19 | -0.10 to 0.48 | 0.39 |
| Potassium applied against omitted | -0.26 | -0.47 to -0.04 | 0.068 |
| Phosphorus and potassium doubled | 0.08 | -0.09 to 0.24 | 0.39 |

![Treatment contrasts with confidence intervals](../figures/fig10_treatment_contrasts.png)

Nitrogen drove yield, steeply to the mid rate and very little beyond it. Neither
phosphorus nor potassium produced a detectable response. The potassium estimate
is negative and does not survive adjustment for the family of five tests, and a
negative estimate runs opposite to the direction a fertilizer response would
take.

![Yield response to applied nitrogen](../figures/fig06_nitrogen_response.png)
![Yield by treatment](../figures/fig01_yield_by_treatment.png)

The assumption checks are reported whichever way they came out. Residuals from
the plot-level analysis of variance fail a Shapiro-Wilk normality test at
p = 1.1e-13, and treatment variances are unequal by the Brown-Forsythe test at
p = 3.2e-07. Both violations argue against relying on that model. The paired
contrasts above do not depend on it, and the 34 block differences underlying each
contrast do satisfy normality, the smallest p-value across the five being 0.14.

Yield was then predicted from information available before harvest, using
leave-one-site-year-out cross-validation, in which the model is trained on 33
site-years and tested on the one held out, repeated 34 times. This measures
performance on a field the model has never seen. A random forest reached RMSE
1.95 Mg/ha and an R-squared of 0.22, against 2.24 Mg/ha for simply predicting the
training mean. Nitrogen dominated the importance ranking, and the phosphorus and
potassium rates fell below every soil test variable, which reaches the
experimental conclusion by an independent route.

![Observed against predicted yield](../figures/fig11_observed_vs_predicted.png)
![Variable importance](../figures/fig12_variable_importance.png)

Two ways of inflating that result were measured rather than merely warned about.
Allowing harvest measurements among the predictors raises the held-out R-squared
from 0.21 to 0.97, almost all of which is the arithmetic identity that total dry
matter contains grain dry matter. Splitting the data over plots instead of
site-years raises it to 0.73, because replicate plots from the same field in the
same season are near-duplicates of one another.

## Insights

Applied phosphorus and potassium did not pay in yield within a season at this
trial's soil test levels. The confidence intervals make that a useful statement
rather than an inconclusive one, because none of them admits an effect larger
than about half a megagram per hectare, roughly a seventh of the nitrogen
response.

That null result agrees with the published analysis of the same trials. Wortmann
et al. (2009) concluded that phosphorus pays when Bray-1 soil test phosphorus
falls below about 10 ppm, and that potassium response is unlikely above 125 ppm.
These site-years were mostly well above both thresholds. Median Bray-1 phosphorus
was 18 ppm, with only 5 of 34 site-years below 10 ppm, and median potassium was
457 ppm, with 31 of 34 site-years above 125 ppm. The absence of a response is
therefore what the existing recommendation predicts for these fields, and the
result should not be read as evidence that phosphorus and potassium never pay.

Sulfur could not be assessed at all. The nine standard treatments all received a
similar low sulfur rate, and the sulfur sub-treatments exist at only one or two
site-years each, which confounds the sulfur treatment with the site.

Two limitations affect how far these results carry. The retained principal
components proved difficult to map back onto individual measurements in a way
that would support a fertilizer decision, so they describe the data better than
they guide practice. The predictors also carry measurement error of their own.
Soil texture class is a field judgment rather than a laboratory determination,
and this deposit records one texture class under two spellings, which is that
subjectivity appearing directly in the record. A model fitted to such inputs
should be expected to transfer imperfectly to a field it has not seen.

Full citations are in [references.md](references.md).
