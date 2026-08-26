# Stage 6: predicting grain yield from what is known before harvest.
#
# The predictor set is fixed by a rule rather than by search: a variable is
# admitted only if its value is set or measurable before the crop is harvested.
# That admits the applied nutrient rates, the plant stand, the irrigation
# applied, the pre-season soil test, the field's position and its management
# history. It excludes every plant measurement taken at harvest.
#
# The exclusion is not conservatism. Total dry matter is the sum of grain, cob
# and stover dry matter, so it contains the quantity being predicted. Harvest
# index is grain dry matter divided by total dry matter. Kernel number per
# square metre multiplied by kernel weight reconstructs yield directly. Nutrient
# uptake is a tissue concentration multiplied by a dry-matter mass that includes
# grain. A model given any of these reports the accuracy of an identity.
#
# Partitions are formed over site-years, never over plots, for the reason given
# in R/04_multivariate.R.

suppressPackageStartupMessages({
  library(dplyr)
  library(randomForest)
})

# Known or set before harvest.
ALLOWED_PREDICTORS <- c(
  "n_rate", "p_rate", "k_rate", "s_rate",       # applied nutrient rates
  "population",                                  # established plant stand
  "irrigation_mm",                               # water applied over the season
  "latitude", "longitude", "year",               # position and season
  "som_pct", "soil_ph", "bray_p_ppm", "olsen_p_ppm",
  "soil_k_ppm", "soil_no3n_ppm",                 # pre-season soil test
  "texture", "tillage", "prev_crop"              # site and management
)

# A deliberately smaller set, holding only quantities with a direct agronomic
# bearing on yield: what was applied, how many plants established, how much water
# was applied, and what the soil test measured. It omits position, season and the
# management categories, all of which are close to labels for the field itself.
# The comparison between this set and the full one measures what those labels buy
# on fields the model has not seen.
AGRONOMIC_PREDICTORS <- c(
  "n_rate", "p_rate", "k_rate", "s_rate", "population", "irrigation_mm",
  "som_pct", "soil_ph", "bray_p_ppm", "olsen_p_ppm", "soil_k_ppm",
  "soil_no3n_ppm"
)

# Measured at or after harvest, and algebraically entangled with grain yield.
BLOCKED_PREDICTORS <- c(
  "grain_dm", "cob_dm", "stover_dm", "total_dm", "harvest_index", "cob_hi",
  "ears", "barren_pct", "prolific_pct", "kernels_per_ear", "kernels_per_m2",
  "kernel_weight", "n_uptake", "p_uptake", "k_uptake", "s_uptake",
  "n_hi", "p_hi", "k_hi", "s_hi"
)

RESPONSE <- "grain_yield"

rmse <- function(actual, predicted) sqrt(mean((actual - predicted)^2))
mae  <- function(actual, predicted) mean(abs(actual - predicted))

# Coefficient of determination against the held-out mean, so that a model no
# better than predicting the test mean scores zero and a worse one scores below
# zero. This is the honest reading on a partition the model has not seen.
r_squared <- function(actual, predicted) {
  1 - sum((actual - predicted)^2) / sum((actual - mean(actual))^2)
}

evaluate <- function(name, role, predictors, actual, predicted) {
  data.frame(model = name, role = role,
             n_predictors = length(predictors),
             predictors = paste(predictors, collapse = " "),
             n_test = length(actual),
             rmse = rmse(actual, predicted),
             mae = mae(actual, predicted),
             r2 = r_squared(actual, predicted),
             row.names = NULL)
}

# The reference every model must beat: predict the training mean for every plot.
fit_baseline <- function(split) {
  m <- mean(split$train[[RESPONSE]])
  evaluate("training mean", "baseline", character(0),
           split$test[[RESPONSE]], rep(m, nrow(split$test)))
}

fit_linear <- function(split, predictors = ALLOWED_PREDICTORS,
                       name = "linear model", role = "predictive") {
  f <- stats::reformulate(predictors, RESPONSE)
  fit <- stats::lm(f, data = split$train)
  pred <- stats::predict(fit, newdata = split$test)
  list(fit = fit,
       metrics = evaluate(name, role, predictors,
                          split$test[[RESPONSE]], pred),
       train_r2 = summary(fit)$r.squared,
       coefficients = {
         co <- summary(fit)$coefficients
         data.frame(term = rownames(co), estimate = co[, 1],
                    std_error = co[, 2], t = co[, 3], p = co[, 4],
                    row.names = NULL)
       })
}

fit_forest <- function(split, predictors = ALLOWED_PREDICTORS,
                       name = "random forest", role = "predictive",
                       ntree = 500, seed = SEED) {
  f <- stats::reformulate(predictors, RESPONSE)
  set.seed(seed)
  fit <- randomForest::randomForest(f, data = split$train, ntree = ntree,
                                    importance = TRUE)
  pred <- stats::predict(fit, newdata = split$test)
  imp <- randomForest::importance(fit)
  list(fit = fit,
       metrics = evaluate(name, role, predictors,
                          split$test[[RESPONSE]], pred),
       importance = data.frame(variable = rownames(imp),
                               pct_inc_mse = imp[, "%IncMSE"],
                               inc_node_purity = imp[, "IncNodePurity"],
                               row.names = NULL))
}

# A single 24-against-10 split of 34 site-years gives a noisy estimate of how a
# model behaves on an unfamiliar field. Leaving out one site-year at a time uses
# every site-year as a test field exactly once and pools the predictions, at the
# cost of 34 fits. Only the numeric agronomic predictors are used, so that no
# fold can encounter a categorical level it was not trained on and the two model
# families are compared on identical information.
cv_by_site_year <- function(d, learner, predictors = AGRONOMIC_PREDICTORS,
                            seed = SEED) {
  blocks <- sort(unique(as.integer(as.character(d$block))))
  block_of <- as.integer(as.character(d$block))
  pred <- numeric(nrow(d))
  for (b in blocks) {
    tr <- d[block_of != b, ]
    te <- d[block_of == b, ]
    pred[block_of == b] <- learner(tr, te, predictors, seed)
  }
  list(observed = d[[RESPONSE]], predicted = pred, n_folds = length(blocks))
}

learner_lm <- function(train, test, predictors, seed) {
  fit <- stats::lm(stats::reformulate(predictors, RESPONSE), data = train)
  as.numeric(stats::predict(fit, newdata = test))
}

learner_rf <- function(train, test, predictors, seed) {
  set.seed(seed)
  fit <- randomForest::randomForest(stats::reformulate(predictors, RESPONSE),
                                    data = train, ntree = 300)
  as.numeric(stats::predict(fit, newdata = test))
}

learner_mean <- function(train, test, predictors, seed) {
  rep(mean(train[[RESPONSE]]), nrow(test))
}

cv_metrics <- function(name, cv) {
  data.frame(model = name, n_folds = cv$n_folds, n = length(cv$observed),
             rmse = rmse(cv$observed, cv$predicted),
             mae = mae(cv$observed, cv$predicted),
             r2 = r_squared(cv$observed, cv$predicted),
             row.names = NULL)
}

# A deliberate demonstration, not a result. Adding total dry matter to the
# linear model reproduces the kind of fit reported when harvest measurements are
# used as predictors, and shows how much of it is an identity rather than a
# prediction. It is labelled "illustration" so that no gate or table can mistake
# it for a model of the crop.
fit_leakage_illustration <- function(split) {
  fit_linear(split, predictors = c(ALLOWED_PREDICTORS, "total_dm",
                                   "harvest_index"),
             name = "linear model with harvest measurements",
             role = "illustration")
}

# How much of a plot-level split's apparent accuracy comes from having seen the
# same field in training. Same model, same seed, only the partitioning rule
# differs.
split_by_plot <- function(d, train_fraction = 0.7, seed = SEED) {
  set.seed(seed)
  idx <- sample(nrow(d), round(train_fraction * nrow(d)))
  list(train_blocks = NA, test_blocks = NA,
       train = d[idx, ], test = d[-idx, ])
}

# --- figures ----------------------------------------------------------------

fig_observed_predicted <- function(split, predicted, subtitle) {
  df <- data.frame(observed = split$test[[RESPONSE]], predicted = predicted,
                   block = split$test$block)
  lims <- range(c(df$observed, df$predicted))
  ggplot2::ggplot(df, ggplot2::aes(x = observed, y = predicted)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "firebrick",
                         linewidth = 0.5) +
    ggplot2::geom_point(alpha = 0.4, size = 1.1, colour = "grey30") +
    ggplot2::coord_equal(xlim = lims, ylim = lims) +
    ggplot2::labs(title = "Predicted against observed grain yield on held-out site-years",
                  subtitle = subtitle,
                  x = "Observed grain yield (Mg/ha)",
                  y = "Predicted grain yield (Mg/ha)",
                  caption = "The line is equality, not a fit.") +
    theme_report()
}

fig_importance <- function(imp, n = 12) {
  imp <- imp[order(-imp$pct_inc_mse), ][seq_len(min(n, nrow(imp))), ]
  imp$variable <- factor(imp$variable, levels = rev(imp$variable))
  ggplot2::ggplot(imp, ggplot2::aes(x = pct_inc_mse, y = variable)) +
    ggplot2::geom_col(fill = "grey40", width = 0.7) +
    ggplot2::labs(
      title = "Random forest variable importance for grain yield",
      subtitle = "Increase in out-of-bag mean squared error when the variable is permuted",
      x = "Percent increase in mean squared error", y = NULL) +
    theme_report()
}
