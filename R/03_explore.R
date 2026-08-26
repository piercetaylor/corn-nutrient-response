# Stage 3: description and exploratory analysis.
#
# The purpose of this stage is to establish the shape of the experiment before
# anything is modelled: how yield is distributed, how the treatments differ, how
# the plant measurements covary, and whether relationships observed across the
# whole data set survive within the subgroups the data set is stratified by.
#
# That last question matters here more than usual. The 1211 standard-treatment
# plots sit inside only 34 site-years, and most of the variation in yield is
# variation between site-years rather than between treatments within one. A
# correlation computed across all plots can therefore describe differences
# between Nebraska fields while appearing to describe a response to treatment.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

# Plant measurements used for correlation structure, principal components and
# clustering. All are measured on the plot at or after harvest.
PLANT_VARS <- c("grain_yield", "total_dm", "harvest_index", "ears",
                "kernels_per_ear", "kernel_weight", "barren_pct",
                "n_uptake", "p_uptake", "k_uptake", "s_uptake",
                "n_hi", "p_hi", "k_hi", "s_hi")

# Context that varies between site-years but not between plots within one.
SITE_VARS <- c("irrigation_mm", "latitude", "longitude", "som_pct", "soil_ph",
               "bray_p_ppm", "olsen_p_ppm", "soil_k_ppm", "soil_no3n_ppm")

describe_numeric <- function(d, vars) {
  do.call(rbind, lapply(vars, function(v) {
    x <- d[[v]]
    data.frame(variable = v, n = sum(!is.na(x)), mean = mean(x, na.rm = TRUE),
               sd = stats::sd(x, na.rm = TRUE), min = min(x, na.rm = TRUE),
               q25 = stats::quantile(x, 0.25, na.rm = TRUE),
               median = stats::median(x, na.rm = TRUE),
               q75 = stats::quantile(x, 0.75, na.rm = TRUE),
               max = max(x, na.rm = TRUE), row.names = NULL)
  }))
}

treatment_summary <- function(s, response = "grain_yield") {
  s %>%
    group_by(treatment) %>%
    summarise(n = dplyr::n(),
              site_years = dplyr::n_distinct(block),
              n_rate = mean(n_rate), p_rate = mean(p_rate),
              k_rate = mean(k_rate), s_rate = mean(s_rate),
              mean = mean(.data[[response]]),
              sd = stats::sd(.data[[response]]),
              se = stats::sd(.data[[response]]) / sqrt(dplyr::n()),
              .groups = "drop") %>%
    as.data.frame()
}

# Proportion of variance in a response attributable to differences between
# site-years, from a one-way analysis of variance on the block factor. This is
# the quantity that justifies blocking every later comparison.
between_block_share <- function(s, response = "grain_yield") {
  fit <- stats::aov(stats::reformulate("block", response), data = s)
  ss <- summary(fit)[[1]][["Sum Sq"]]
  ss[1] / sum(ss)
}

# Pooled correlation against correlations computed within each level of a
# grouping factor. A pooled coefficient that is not reproduced within groups,
# and in particular one whose sign reverses, is the signature of Simpson's
# paradox and disqualifies the pooled figure from being read causally.
subgroup_correlations <- function(d, x, y, group) {
  pooled <- stats::cor(d[[x]], d[[y]])
  parts <- d %>%
    group_by(.data[[group]]) %>%
    filter(dplyr::n() >= 8) %>%
    summarise(n = dplyr::n(), r = stats::cor(.data[[x]], .data[[y]]),
              .groups = "drop")
  data.frame(
    x = x, y = y, grouping = group,
    pooled_r = pooled,
    n_groups = nrow(parts),
    min_within_r = min(parts$r),
    median_within_r = stats::median(parts$r),
    max_within_r = max(parts$r),
    n_sign_reversals = sum(sign(parts$r) != sign(pooled)),
    row.names = NULL
  )
}

simpson_report <- function(s, pairs, groups) {
  out <- list()
  for (p in pairs) {
    for (g in groups) {
      out[[length(out) + 1L]] <- subgroup_correlations(s, p[1], p[2], g)
    }
  }
  do.call(rbind, out)
}

# --- figures ----------------------------------------------------------------

fig_yield_by_treatment <- function(s) {
  means <- s %>% group_by(treatment) %>%
    summarise(m = mean(grain_yield), .groups = "drop")
  ggplot(s, aes(x = treatment, y = grain_yield)) +
    geom_boxplot(outlier.size = 0.6, outlier.colour = "grey50",
                 fill = "grey93", colour = "grey30", width = 0.62) +
    geom_point(data = means, aes(y = m), colour = "firebrick", size = 2.2) +
    labs(title = "Grain yield by standard treatment",
         subtitle = "1211 plots, 34 site-years; red points are treatment means",
         x = NULL, y = "Grain yield (Mg/ha at 15.5% moisture)",
         caption = "Nitrogen rate rises from N0 to N4. P0 and K0 omit applied phosphorus and potassium at the N2 rate.") +
    theme_report()
}

fig_yield_distribution <- function(s) {
  ggplot(s, aes(x = grain_yield)) +
    geom_histogram(bins = 40, fill = "grey80", colour = "grey30",
                   linewidth = 0.25) +
    geom_vline(xintercept = mean(s$grain_yield), colour = "firebrick",
               linewidth = 0.6) +
    labs(title = "Distribution of plot grain yield",
         subtitle = sprintf("mean %.2f Mg/ha, standard deviation %.2f Mg/ha",
                            mean(s$grain_yield), stats::sd(s$grain_yield)),
         x = "Grain yield (Mg/ha)", y = "Plots") +
    theme_report()
}

fig_correlation <- function(s, vars = PLANT_VARS) {
  m <- stats::cor(s[, vars])
  corrplot::corrplot(m, method = "color", type = "upper", order = "hclust",
                     tl.col = "black", tl.cex = 0.8, tl.srt = 45,
                     addCoef.col = "grey20", number.cex = 0.5,
                     mar = c(0, 0, 2, 0),
                     title = "Correlation among plant measurements")
}

# The subtitle is supplied by the caller so that it can state the measured
# within-group coefficients rather than a claim written in advance.
fig_simpson <- function(s, subtitle) {
  ggplot(s, aes(x = n_uptake, y = grain_yield)) +
    geom_point(alpha = 0.25, size = 0.8, colour = "grey35") +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE,
                colour = "firebrick", linewidth = 0.6) +
    facet_wrap(~ texture, nrow = 1) +
    labs(title = "Grain yield against nitrogen uptake, by soil texture class",
         subtitle = subtitle,
         x = "Nitrogen uptake (kg/ha)", y = "Grain yield (Mg/ha)") +
    theme_report()
}

fig_sites <- function(d) {
  sy <- d %>% group_by(site_yr, site, year) %>%
    summarise(latitude = dplyr::first(latitude),
              longitude = dplyr::first(longitude),
              irrigation_mm = dplyr::first(irrigation_mm),
              yield = mean(grain_yield), .groups = "drop")
  ggplot(sy, aes(x = longitude, y = latitude)) +
    geom_point(aes(size = irrigation_mm, colour = yield), alpha = 0.85) +
    scale_colour_viridis_c(option = "D", name = "Mean yield\n(Mg/ha)") +
    scale_size_continuous(name = "Irrigation\n(mm)", range = c(2, 7)) +
    labs(title = "The 34 site-years across Nebraska",
         subtitle = "Irrigation applied increases westward as growing-season rainfall declines",
         x = "Longitude", y = "Latitude") +
    theme_report()
}

fig_nitrogen_response <- function(s) {
  by_block <- s %>%
    group_by(block, treatment) %>%
    summarise(n_rate = mean(n_rate), yield = mean(grain_yield), .groups = "drop")
  overall <- by_block %>% group_by(treatment) %>%
    summarise(n_rate = mean(n_rate), yield = mean(yield), .groups = "drop")
  ggplot(by_block, aes(x = n_rate, y = yield)) +
    geom_point(alpha = 0.3, size = 1, colour = "grey45") +
    geom_line(data = overall, aes(group = 1), colour = "firebrick",
              linewidth = 0.7) +
    geom_point(data = overall, colour = "firebrick", size = 2.4) +
    labs(title = "Yield response to applied nitrogen",
         subtitle = "Grey points are site-year means for each treatment; the red line joins treatment means across all 34 site-years",
         x = "Applied nitrogen (kg/ha)", y = "Grain yield (Mg/ha)") +
    theme_report()
}
