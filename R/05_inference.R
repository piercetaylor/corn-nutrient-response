# Stage 5: hypothesis tests on the treatment structure.
#
# The nine standard treatments were applied in every one of the 34 site-years,
# with two to four replicate plots per cell. That is a randomised complete block
# design with site-year as the block, and it is analysed as one. Treating the
# 1211 plots as independent would treat replicate plots in the same field in the
# same season as independent evidence about Nebraska, which they are not.
#
# Two questions are asked. Does treatment affect grain yield at all, and if so,
# how large are the specific contrasts the design was built to estimate: the
# response to applied nitrogen, and the cost of omitting phosphorus or potassium
# at a fixed nitrogen rate.
#
# The contrasts are estimated on site-year means, one pair of numbers per block,
# and tested with paired t-tests across the 34 blocks. This keeps the unit of
# inference at the level at which treatments were randomised against
# environments, and it yields a confidence interval in megagrams per hectare,
# which is the quantity an agronomist can act on.

suppressPackageStartupMessages(library(dplyr))

# Contrasts the design supports. Each names a treatment pair whose difference
# isolates one factor, holding the others at a fixed rate.
CONTRASTS <- list(
  list(name = "nitrogen response (N2 against N0)",
       high = "N2P1K1", low = "N0P1K1",
       reads = "yield gained by applying nitrogen at the mid rate"),
  list(name = "nitrogen response (N4 against N2)",
       high = "N4P1K1", low = "N2P1K1",
       reads = "further yield gained by raising nitrogen from the mid to the high rate"),
  list(name = "phosphorus omission (P1 against P0 at N2)",
       high = "N2P1K1", low = "N2P0K1",
       reads = "yield gained by applying phosphorus at a fixed nitrogen rate"),
  list(name = "potassium omission (K1 against K0 at N2)",
       high = "N2P1K1", low = "N2P1K0",
       reads = "yield gained by applying potassium at a fixed nitrogen rate"),
  list(name = "doubled phosphorus and potassium (N4P2K2 against N4P1K1)",
       high = "N4P2K2", low = "N4P1K1",
       reads = "yield gained by doubling phosphorus and potassium at the high nitrogen rate")
)

block_means <- function(s, response = "grain_yield") {
  s %>%
    group_by(block, treatment) %>%
    summarise(value = mean(.data[[response]]), .groups = "drop")
}

# Randomised complete block analysis of variance. Block is entered first so that
# the treatment sum of squares is adjusted for site-year.
rcb_anova <- function(s, response = "grain_yield") {
  fit <- stats::aov(stats::reformulate(c("block", "treatment"), response),
                    data = s)
  tab <- summary(fit)[[1]]
  list(fit = fit,
       table = data.frame(term = trimws(rownames(tab)),
                          df = tab[["Df"]], sum_sq = tab[["Sum Sq"]],
                          mean_sq = tab[["Mean Sq"]],
                          f = tab[["F value"]], p = tab[["Pr(>F)"]],
                          row.names = NULL))
}

paired_contrast <- function(s, high, low, response = "grain_yield") {
  bm <- block_means(s, response)
  wide <- bm %>%
    filter(treatment %in% c(high, low)) %>%
    tidyr::pivot_wider(names_from = treatment, values_from = value)
  assert(nrow(wide) == nlevels(droplevels(s$block)),
         "contrast %s against %s is missing site-years", high, low)
  a <- wide[[high]]
  b <- wide[[low]]
  assert(!any(is.na(a)) && !any(is.na(b)),
         "contrast %s against %s has an empty site-year cell", high, low)
  tt <- stats::t.test(a, b, paired = TRUE)
  data.frame(high = high, low = low, n_blocks = length(a),
             estimate = as.numeric(tt$estimate),
             ci_low = tt$conf.int[1], ci_high = tt$conf.int[2],
             t = as.numeric(tt$statistic), df = as.numeric(tt$parameter),
             p = tt$p.value, row.names = NULL)
}

contrast_table <- function(s, contrasts = CONTRASTS, response = "grain_yield") {
  out <- do.call(rbind, lapply(contrasts, function(c0) {
    r <- paired_contrast(s, c0$high, c0$low, response)
    cbind(data.frame(contrast = c0$name, reads = c0$reads), r)
  }))
  # Five pre-specified contrasts are tested on the same response, so the
  # p-values are reported alongside a Holm adjustment rather than raw.
  out$p_holm <- stats::p.adjust(out$p, method = "holm")
  out
}

# --- assumption checks ------------------------------------------------------
# Reported whatever they show. The paired contrasts above are the primary
# analysis precisely because they depend on fewer of these assumptions than the
# plot-level analysis of variance does.

# The paired contrasts assume that the 34 block differences are approximately
# normal, which is a far weaker requirement than normality of the 1211 plot
# residuals. It is tested separately for each contrast.
shapiro_contrast_differences <- function(s, contrasts = CONTRASTS,
                                         response = "grain_yield") {
  bm <- block_means(s, response)
  do.call(rbind, lapply(contrasts, function(c0) {
    wide <- bm %>%
      filter(treatment %in% c(c0$high, c0$low)) %>%
      tidyr::pivot_wider(names_from = treatment, values_from = value)
    diffs <- wide[[c0$high]] - wide[[c0$low]]
    t <- stats::shapiro.test(diffs)
    data.frame(contrast = c0$name, n = length(diffs),
               statistic = as.numeric(t$statistic), p = t$p.value,
               row.names = NULL)
  }))
}

shapiro_residuals <- function(fit, seed = SEED, max_n = 5000) {
  r <- stats::residuals(fit)
  set.seed(seed)
  if (length(r) > max_n) r <- sample(r, max_n)
  t <- stats::shapiro.test(r)
  data.frame(test = "Shapiro-Wilk on residuals", n = length(r),
             statistic = as.numeric(t$statistic), p = t$p.value,
             row.names = NULL)
}

# Brown-Forsythe test of equal variances: a one-way analysis of variance on the
# absolute deviation of each observation from its group median. Written out here
# rather than taken from a package, because it is three lines and the package
# that supplies it carries a large dependency tree.
brown_forsythe <- function(d, response, group) {
  x <- d[[response]]
  g <- factor(d[[group]])
  med <- stats::ave(x, g, FUN = stats::median)
  fit <- stats::aov(abs(x - med) ~ g)
  tab <- summary(fit)[[1]]
  data.frame(test = sprintf("Brown-Forsythe across %s", group),
             df1 = tab[["Df"]][1], df2 = tab[["Df"]][2],
             statistic = tab[["F value"]][1], p = tab[["Pr(>F)"]][1],
             row.names = NULL)
}

# --- multivariate test ------------------------------------------------------
# Grain yield, total dry matter, ear number and nitrogen uptake respond to the
# same treatments and to each other. A multivariate analysis of variance asks
# whether the treatment means differ on the four responses jointly, which a
# separate test on each response cannot answer without inflating the error rate.
# It is run on site-year means so that the rows entering the test are the 306
# design cells rather than the 1211 correlated plots.
manova_treatments <- function(s, responses = c("grain_yield", "total_dm",
                                               "ears", "n_uptake")) {
  cell <- s %>%
    group_by(block, treatment) %>%
    summarise(dplyr::across(dplyr::all_of(responses), mean), .groups = "drop")
  y <- as.matrix(cell[, responses])
  fit <- stats::manova(y ~ block + treatment, data = cell)
  tab <- summary(fit, test = "Pillai")$stats
  data.frame(term = trimws(rownames(tab)), df = tab[, "Df"],
             pillai = tab[, "Pillai"],
             approx_f = tab[, "approx F"],
             num_df = tab[, "num Df"], den_df = tab[, "den Df"],
             p = tab[, "Pr(>F)"], row.names = NULL)
}

# --- figure -----------------------------------------------------------------

fig_contrasts <- function(ct) {
  ct$label <- factor(ct$contrast, levels = rev(ct$contrast))
  ggplot2::ggplot(ct, ggplot2::aes(x = estimate, y = label)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.4) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = ci_low, xmax = ci_high),
                           orientation = "y", width = 0.16, colour = "grey25") +
    ggplot2::geom_point(size = 2.6, colour = "firebrick") +
    ggplot2::labs(
      title = "Pre-specified treatment contrasts on grain yield",
      subtitle = "Paired differences of site-year means across 34 blocks, with 95 percent confidence intervals",
      x = "Difference in grain yield (Mg/ha)", y = NULL) +
    theme_report()
}
