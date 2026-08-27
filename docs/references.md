# References

## Data

Wortmann, C. S., A. R. Dobermann, R. B. Ferguson, G. W. Hergert, C. A. Shapiro,
D. D. Tarkalson and D. T. Walters (2022). *Data from: High-yielding corn response
to applied phosphorus, potassium, and sulfur in Nebraska* [Dataset]. Dryad.
https://doi.org/10.5061/dryad.p30c6

Released under CC0. The deposit was first published in 2017 and last updated in
September 2022; the citation year follows Dryad's own recommended form.

## Source publication

Wortmann, C. S., A. R. Dobermann, R. B. Ferguson, G. W. Hergert, C. A. Shapiro,
D. D. Tarkalson and D. T. Walters (2009). High-yielding corn response to applied
phosphorus, potassium, and sulfur in Nebraska. *Agronomy Journal* 101(3):546–555.
https://doi.org/10.2134/agronj2008.0103x

This is the analysis the trials were originally conducted to support. It reports
that phosphorus application is profitable when Bray-1 soil test phosphorus is
below roughly 10 ppm, or Olsen phosphorus below roughly 7 ppm, and that corn
response to applied potassium is unlikely above 125 ppm soil test potassium.
Those thresholds are the reference point against which the null results in this
project are interpreted. The paper is under journal copyright and is cited here
rather than redistributed.

## Methods

Kaiser, H. F. (1960). The application of electronic computers to factor analysis.
*Educational and Psychological Measurement* 20(1):141–151.
https://doi.org/10.1177/001316446002000116
Source of the eigenvalue-greater-than-one rule used to decide how many principal
components to retain.

Holm, S. (1979). A simple sequentially rejective multiple test procedure.
*Scandinavian Journal of Statistics* 6(2):65–70.
https://www.jstor.org/stable/4615733
Source of the multiple-comparison adjustment applied to the five treatment
contrasts.

Charrad, M., N. Ghazzali, V. Boiteau and A. Niknafs (2014). NbClust: an R package
for determining the relevant number of clusters in a data set. *Journal of
Statistical Software* 61(6):1–36. https://doi.org/10.18637/jss.v061.i06
Source of the 24 indices used to select the number of k-means clusters by
majority vote.

Breiman, L. (2001). Random forests. *Machine Learning* 45(1):5–32.
https://doi.org/10.1023/A:1010933404324
Source of the ensemble method used for yield prediction.

Cramér, H. (1946). *Mathematical Methods of Statistics*. Princeton University
Press.
Source of the measure of association between categorical variables used to
compare cluster assignment against site-year and treatment.

Simpson, E. H. (1951). The interpretation of interaction in contingency tables.
*Journal of the Royal Statistical Society, Series B* 13(2):238–241.
https://www.jstor.org/stable/2984065
Describes the reversal of association between pooled and subgroup analysis that
motivated checking correlations within site-years.

## Software

R Core Team (2025). *R: A Language and Environment for Statistical Computing*.
R Foundation for Statistical Computing, Vienna. Version 4.4.3.
https://www.R-project.org/

Package versions are pinned in `renv.lock` at the repository root.
