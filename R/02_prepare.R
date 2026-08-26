# Stage 2: assemble the analysis frame.
#
# Plot-level observations carry the treatment design and the plant measurements.
# The site-year worksheet carries the context in which each plot sat: position,
# irrigation applied, and the soil test taken before the season. The two are
# joined on site-year, which is a 34-row lookup against 1483 plots, so the join
# must not change the number of rows. That is asserted rather than assumed.
#
# The analysis is then restricted to the nine standard treatments, which were
# applied at every one of the 34 site-years. Treatments 10 to 12 are
# site-specific extras (manure, banded placement, plant population and sulfur
# sub-trials) present at one to seven site-years each. They are kept in the full
# frame for description and excluded from every inferential comparison, because
# contrasts drawn from them would confound treatment with site.

suppressPackageStartupMessages(library(dplyr))

# Deposited name, occurrence within the header, and the name used from here on.
PLOT_COLUMNS <- rbind(
  data.frame(src = "Year",       occ = 1, dst = "year"),
  data.frame(src = "Site-yr",    occ = 1, dst = "site_yr"),
  data.frame(src = "Site-no",    occ = 1, dst = "site_no"),
  data.frame(src = "Site",       occ = 1, dst = "site"),
  data.frame(src = "Soil",       occ = 1, dst = "soil_series"),
  data.frame(src = "Texture",    occ = 1, dst = "texture"),
  data.frame(src = "prevCrop",   occ = 1, dst = "prev_crop"),
  data.frame(src = "Till",       occ = 1, dst = "tillage"),
  data.frame(src = "Treatment",  occ = 1, dst = "treatment"),
  data.frame(src = "Treat-no",   occ = 1, dst = "treat_no"),
  data.frame(src = "Plot",       occ = 1, dst = "plot"),
  data.frame(src = "Rep",        occ = 1, dst = "rep"),
  data.frame(src = "FN",         occ = 1, dst = "n_rate"),
  data.frame(src = "FP",         occ = 1, dst = "p_rate"),
  data.frame(src = "FK",         occ = 1, dst = "k_rate"),
  data.frame(src = "FS",         occ = 1, dst = "s_rate"),
  data.frame(src = "POP ha",     occ = 1, dst = "population"),
  data.frame(src = "GY Mg",      occ = 1, dst = "grain_yield"),
  data.frame(src = "GDM",        occ = 1, dst = "grain_dm"),
  data.frame(src = "CDM",        occ = 1, dst = "cob_dm"),
  data.frame(src = "VDM",        occ = 1, dst = "stover_dm"),
  data.frame(src = "TDM",        occ = 1, dst = "total_dm"),
  data.frame(src = "cobHi",      occ = 1, dst = "cob_hi"),
  data.frame(src = "HI",         occ = 1, dst = "harvest_index"),
  data.frame(src = "EARS",       occ = 1, dst = "ears"),
  data.frame(src = "BARR",       occ = 1, dst = "barren_pct"),
  data.frame(src = "PROL",       occ = 1, dst = "prolific_pct"),
  data.frame(src = "KERNE",      occ = 1, dst = "kernels_per_ear"),
  data.frame(src = "KERNm",      occ = 1, dst = "kernels_per_m2"),
  data.frame(src = "HSW",        occ = 1, dst = "kernel_weight"),
  data.frame(src = "UN",         occ = 1, dst = "n_uptake"),
  data.frame(src = "NHI",        occ = 1, dst = "n_hi"),
  data.frame(src = "UP",         occ = 1, dst = "p_uptake"),
  data.frame(src = "PHI",        occ = 1, dst = "p_hi"),
  data.frame(src = "UK",         occ = 1, dst = "k_uptake"),
  data.frame(src = "KHI",        occ = 1, dst = "k_hi"),
  data.frame(src = "US",         occ = 1, dst = "s_uptake"),
  data.frame(src = "SHI",        occ = 1, dst = "s_hi")
)

SITEYEAR_COLUMNS <- rbind(
  data.frame(src = "Site-yr",       dst = "site_yr"),
  data.frame(src = "Latitude",      dst = "latitude"),
  data.frame(src = "Longitude",     dst = "longitude"),
  data.frame(src = "Irrigation mm", dst = "irrigation_mm"),
  data.frame(src = "SOM (%)",       dst = "som_pct"),
  data.frame(src = "pH",            dst = "soil_ph"),
  data.frame(src = "Br.P (ppm)",    dst = "bray_p_ppm"),
  data.frame(src = "Ols.P (ppm)",   dst = "olsen_p_ppm"),
  data.frame(src = "K (ppm)",       dst = "soil_k_ppm"),
  data.frame(src = "NO3-N (ppm)",   dst = "soil_no3n_ppm"),
  data.frame(src = "Texture",       dst = "texture_ref"),
  data.frame(src = "Till",          dst = "tillage_ref"),
  data.frame(src = "prev. Crop",    dst = "prev_crop_ref")
)

STANDARD_TREATMENTS <- c("N0P1K1", "N1P1K1", "N2P0K1", "N2P1K0", "N2P1K1",
                         "N3P1K1", "N4P1K1", "N4P2K2", "UNL")

# Physically plausible ranges for the quantities the analysis depends on. These
# are agronomic bounds rather than observed ranges: a value outside them points
# to a unit change or a corrupted read, not to an unusual field.
PLAUSIBLE <- list(
  grain_yield   = c(0, 25),          # Mg/ha at 15.5 percent moisture
  total_dm      = c(3000, 45000),    # kg/ha
  grain_dm      = c(1000, 25000),    # kg/ha
  population    = c(20000, 120000),  # plants/ha
  ears          = c(20000, 140000),  # ears/ha
  harvest_index = c(0.20, 0.75),
  n_uptake      = c(10, 600),        # kg/ha
  p_uptake      = c(1, 150),         # kg/ha
  k_uptake      = c(20, 800),        # kg/ha
  s_uptake      = c(1, 100),         # kg/ha
  n_rate        = c(0, 400),         # kg/ha applied
  p_rate        = c(0, 150),         # kg/ha applied
  k_rate        = c(0, 200),         # kg/ha applied
  s_rate        = c(0, 50),          # kg/ha applied
  irrigation_mm = c(0, 800),
  soil_ph       = c(4, 9),
  som_pct       = c(0, 10)
)

select_named <- function(d, map) {
  header <- names(d)
  occ <- if ("occ" %in% names(map)) map$occ else rep(1L, nrow(map))
  idx <- mapply(col_index, name = map$src, which = occ,
                MoreArgs = list(header = header))
  out <- d[, idx, drop = FALSE]
  names(out) <- map$dst
  out
}

build_analysis_frame <- function(plot_df, site_df) {
  plots <- select_named(plot_df, PLOT_COLUMNS)
  sites <- select_named(site_df, SITEYEAR_COLUMNS)

  assert(nrow(sites) == EXPECTED$siteyear_rows,
         "site-year lookup has %d rows, expected %d",
         nrow(sites), EXPECTED$siteyear_rows)
  assert(!any(duplicated(sites$site_yr)),
         "site-year lookup contains duplicate keys")
  assert(all(plots$site_yr %in% sites$site_yr),
         "%d plots reference a site-year absent from the lookup",
         sum(!plots$site_yr %in% sites$site_yr))

  n_before <- nrow(plots)
  d <- merge(plots, sites, by = "site_yr", all.x = TRUE, sort = FALSE)
  assert(nrow(d) == n_before,
         "join changed the row count: %d before, %d after", n_before, nrow(d))

  # The plot sheet and the site-year sheet both describe texture, tillage and
  # previous crop. Disagreement would mean the two sheets describe different
  # experiments, so they are compared and the duplicates then discarded.
  for (pair in list(c("texture", "texture_ref"), c("tillage", "tillage_ref"),
                    c("prev_crop", "prev_crop_ref"))) {
    a <- trimws(as.character(d[[pair[1]]]))
    b <- trimws(as.character(d[[pair[2]]]))
    assert(all(a == b), "worksheets disagree on %s for %d plots",
           pair[1], sum(a != b))
  }
  d <- d[, !names(d) %in% c("texture_ref", "tillage_ref", "prev_crop_ref")]

  # The deposit records the loamy sand texture class as both "lS" and "ls". The
  # single site-year spelled "ls" (Spurgin, 2004) is on the Vetal soil series,
  # which also carries the "lS" label at Paxton in 2002 and 2003, so the two
  # spellings denote one class. They are merged onto the dominant spelling and
  # the number of plots affected is returned as an attribute, so that the
  # correction is visible in the record rather than silent.
  texture_chr <- trimws(as.character(d$texture))
  n_recoded <- sum(texture_chr == "ls")
  texture_chr[texture_chr == "ls"] <- "lS"
  d$texture <- texture_chr

  for (v in c("texture", "prev_crop", "tillage", "site", "soil_series",
              "treatment")) {
    d[[v]] <- factor(trimws(as.character(d[[v]])))
  }
  d$site_yr  <- as.integer(d$site_yr)
  d$year     <- as.integer(d$year)
  d$treat_no <- as.integer(d$treat_no)
  d$block <- factor(d$site_yr)   # site-year is the experimental block

  # Every site-year in this deposit received irrigation. There is therefore no
  # irrigated-against-rainfed contrast to draw, only a gradient in the amount
  # applied, and the assertion below keeps that reading of the data honest if a
  # future version of the deposit adds rainfed sites.
  assert(all(d$irrigation_mm > 0),
         "%d plots sit in site-years with no irrigation; the analysis assumes all site-years were irrigated",
         sum(d$irrigation_mm <= 0))

  d <- d[order(d$site_yr, d$treat_no, d$rep), ]
  rownames(d) <- NULL
  attr(d, "texture_recoded_plots") <- n_recoded
  d
}

standard_subset <- function(d) {
  s <- d[d$treat_no %in% 1:9, ]
  assert(setequal(as.character(unique(s$treatment)), STANDARD_TREATMENTS),
         "treatment numbers 1-9 do not map onto the nine standard codes; found: %s",
         paste(sort(unique(as.character(s$treatment))), collapse = ", "))
  s$treatment <- factor(as.character(s$treatment), levels = STANDARD_TREATMENTS)
  s$block <- droplevels(s$block)
  rownames(s) <- NULL
  s
}

# Every site-year by treatment cell should be occupied. Replication is close to
# but not exactly four plots per cell, so the cell counts are reported rather
# than assumed equal.
design_balance <- function(s) {
  tab <- table(s$block, s$treatment)
  list(table = tab,
       cells = length(tab),
       empty_cells = sum(tab == 0),
       min_reps = min(tab),
       max_reps = max(tab))
}

check_ranges <- function(d, bounds = PLAUSIBLE) {
  out <- vector("list", length(bounds))
  for (i in seq_along(bounds)) {
    v <- names(bounds)[i]
    assert(v %in% names(d), "range check refers to an absent column: %s", v)
    x <- d[[v]]
    lo <- bounds[[i]][1]
    hi <- bounds[[i]][2]
    out[[i]] <- data.frame(
      variable = v, lower = lo, upper = hi,
      observed_min = min(x, na.rm = TRUE),
      observed_max = max(x, na.rm = TRUE),
      n_outside = sum(!is.na(x) & (x < lo | x > hi))
    )
  }
  do.call(rbind, out)
}

# Two identities that the workbook satisfies by construction. They are checked
# because they are the clearest evidence that total dry matter contains grain
# dry matter, which is why total dry matter cannot serve as a predictor of
# grain yield.
check_identities <- function(d) {
  dm_err <- abs((d$grain_dm + d$cob_dm + d$stover_dm) - d$total_dm) / d$total_dm
  hi_err <- abs(d$grain_dm / d$total_dm - d$harvest_index)
  data.frame(
    identity = c("grain_dm + cob_dm + stover_dm = total_dm",
                 "grain_dm / total_dm = harvest_index"),
    max_relative_error = c(max(dm_err, na.rm = TRUE), max(hi_err, na.rm = TRUE)),
    n_over_tolerance = c(sum(dm_err > 1e-6, na.rm = TRUE),
                         sum(hi_err > 1e-6, na.rm = TRUE))
  )
}

missingness <- function(d) {
  m <- colSums(is.na(d))
  data.frame(variable = names(m), n_missing = as.integer(m),
             fraction = as.numeric(m) / nrow(d), row.names = NULL)
}
