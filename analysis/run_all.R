#!/usr/bin/env Rscript
# Run the whole analysis and write every figure, table and recorded quantity.
#
# Run from the repository root:
#   Rscript analysis/run_all.R
#
# Outputs: figures/*.png, results/*.csv, results/metrics.csv, results/session-info.txt.
# Nothing in README.md or docs/writeup.md is written by hand from memory; every
# number quoted there is read out of results/metrics.csv.

for (f in c("99_utils", "01_ingest", "02_prepare", "03_explore",
            "04_multivariate", "05_inference", "06_models")) {
  source(file.path("R", paste0(f, ".R")))
}
suppressPackageStartupMessages(library(tidyr))

ensure_dirs()
set.seed(SEED)
record("seed", SEED, "set once in R/99_utils.R")
record("r_version", paste(R.version$major, R.version$minor, sep = "."))

stage <- function(n, title) message(sprintf("\n== %s. %s", n, title))

# --- 1. acquisition ---------------------------------------------------------
stage(1, "acquisition")
assert(file.exists(PATHS$raw_xls),
       "raw workbook not found. Run: Rscript data/download_data.R")
digest <- sha256_file(PATHS$raw_xls)
assert(identical(digest, DRYAD$data_sha256),
       "SHA-256 mismatch: expected %s, observed %s", DRYAD$data_sha256, digest)
record("data_sha256", digest, "matches the digest published by Dryad")
record("data_bytes", file.size(PATHS$raw_xls))

sheets <- read_sheet_names()
assert(identical(sheets, EXPECTED$sheets),
       "worksheet names differ from expectation: %s",
       paste(sheets, collapse = ", "))
record("sheet_count", length(sheets))

# --- 2. ingestion and schema ------------------------------------------------
stage(2, "ingestion and schema")
plot_df <- read_plot_data()
site_df <- read_siteyear()
dictionary <- read_dictionary()

expected_cols <- readLines("data/expected_columns.txt")
observed_cols <- names(plot_df)
assert(identical(observed_cols, expected_cols),
       "Data worksheet header drifted. %d of %d columns differ; first difference at position %d",
       sum(observed_cols != expected_cols), length(expected_cols),
       which(observed_cols != expected_cols)[1])

assert(nrow(plot_df) == EXPECTED$data_rows,
       "Data worksheet has %d rows, expected %d", nrow(plot_df),
       EXPECTED$data_rows)
assert(ncol(plot_df) == EXPECTED$data_cols,
       "Data worksheet has %d columns, expected %d", ncol(plot_df),
       EXPECTED$data_cols)
record("data_rows", nrow(plot_df))
record("data_cols", ncol(plot_df))
record("siteyear_rows", nrow(site_df))
record("dictionary_entries", nrow(dictionary))
write_table(dictionary, "variable-dictionary")

# --- 3. preparation ---------------------------------------------------------
stage(3, "preparation")
d <- build_analysis_frame(plot_df, site_df)
assert(nrow(d) == EXPECTED$data_rows,
       "analysis frame lost rows: %d of %d", nrow(d), EXPECTED$data_rows)
record("frame_rows", nrow(d))
record("frame_cols", ncol(d))
record("texture_recoded_plots", attr(d, "texture_recoded_plots"),
       "plots whose texture class was recorded as 'ls' and merged into 'lS'")
record("texture_classes", nlevels(d$texture))

ranges <- check_ranges(d)
write_table(ranges, "range-checks")
record("range_violations", sum(ranges$n_outside),
       "values outside agronomically plausible bounds")

identities <- check_identities(d)
write_table(identities, "identity-checks")
record("identity_max_error_dm", identities$max_relative_error[1],
       "grain + cob + stover against total dry matter")
record("identity_max_error_hi", identities$max_relative_error[2],
       "grain dry matter over total against reported harvest index")

miss <- missingness(d)
write_table(miss[miss$n_missing > 0, ], "missingness")
record("missing_cells_total", sum(miss$n_missing))
record("missing_fraction_max", max(miss$fraction))

record("irrigation_min_mm", min(d$irrigation_mm))
record("irrigation_max_mm", max(d$irrigation_mm))
record("site_years", length(unique(d$site_yr)))

s <- standard_subset(d)
assert(nrow(s) == EXPECTED$standard_rows,
       "standard-treatment subset has %d rows, expected %d",
       nrow(s), EXPECTED$standard_rows)
bal <- design_balance(s)
assert(bal$empty_cells == 0,
       "%d of %d design cells are empty", bal$empty_cells, bal$cells)
record("standard_rows", nrow(s))
record("standard_site_years", nlevels(s$block))
record("standard_treatments", nlevels(s$treatment))
record("design_cells", bal$cells)
record("design_empty_cells", bal$empty_cells)
record("design_min_reps", bal$min_reps)
record("design_max_reps", bal$max_reps)
record("excluded_rows", nrow(d) - nrow(s),
       "plots in site-specific treatments 10 to 12")

# --- 4. description and exploration -----------------------------------------
stage(4, "description and exploration")
desc <- describe_numeric(s, c(PLANT_VARS, SITE_VARS, "n_rate", "p_rate",
                              "k_rate", "s_rate", "population"))
write_table(desc, "descriptive-statistics")

ts <- treatment_summary(s)
write_table(ts, "treatment-summary")
for (i in seq_len(nrow(ts))) {
  record(paste0("mean_yield_", ts$treatment[i]), ts$mean[i], "Mg/ha")
}
record("mean_yield", mean(s$grain_yield), "Mg/ha over the 1211 standard plots")
record("sd_yield", stats::sd(s$grain_yield))
record("min_yield", min(s$grain_yield))
record("max_yield", max(s$grain_yield))

bb <- between_block_share(s)
record("between_block_share_yield", bb,
       "share of plot-level yield sum of squares lying between site-years")

simpson <- simpson_report(
  s,
  pairs = list(c("n_uptake", "grain_yield"), c("p_uptake", "grain_yield"),
               c("k_uptake", "grain_yield"), c("population", "grain_yield")),
  groups = c("texture", "tillage", "prev_crop", "block"))
write_table(simpson, "subgroup-correlations")
record("simpson_sign_reversals", sum(simpson$n_sign_reversals),
       "subgroup correlations whose sign opposes the pooled coefficient")
nu <- simpson[simpson$x == "n_uptake" & simpson$grouping == "texture", ]
record("pooled_r_yield_n_uptake", nu$pooled_r)
record("min_within_texture_r_yield_n_uptake", nu$min_within_r)
nb <- simpson[simpson$x == "n_uptake" & simpson$grouping == "block", ]
record("min_within_block_r_yield_n_uptake", nb$min_within_r)
record("median_within_block_r_yield_n_uptake", nb$median_within_r)
pop <- simpson[simpson$x == "population" & simpson$grouping == "block", ]
record("pooled_r_yield_population", pop$pooled_r)
record("min_within_block_r_yield_population", pop$min_within_r)
record("population_sign_reversals_within_block", pop$n_sign_reversals)

save_ggplot("fig01_yield_by_treatment", fig_yield_by_treatment(s))
save_ggplot("fig02_yield_distribution", fig_yield_distribution(s), height = 4)
save_figure("fig03_plant_correlations", fig_correlation(s), width = 8.6,
            height = 7.4)
save_ggplot("fig04_yield_vs_n_uptake_by_texture",
            fig_simpson(s, sprintf(
              "Pooled coefficient %.2f; within texture classes the coefficient ranges from %.2f to %.2f",
              nu$pooled_r, nu$min_within_r, nu$max_within_r)),
            width = 9, height = 3.6)
save_ggplot("fig05_site_years", fig_sites(d))
save_ggplot("fig06_nitrogen_response", fig_nitrogen_response(s), height = 4.4)

# --- 5. dimension reduction and clustering ----------------------------------
stage(5, "dimension reduction and clustering")
split <- split_by_site_year(s, train_fraction = 0.7)
record("split_train_site_years", length(split$train_blocks))
record("split_test_site_years", length(split$test_blocks))
record("split_train_rows", nrow(split$train))
record("split_test_rows", nrow(split$test))
record("split_site_year_overlap",
       length(intersect(split$train_blocks, split$test_blocks)))
record("split_attempts", split$attempts,
       "draws needed before every site-level factor level appeared in training")
write_table(data.frame(partition = c(rep("train", length(split$train_blocks)),
                                     rep("test", length(split$test_blocks))),
                       site_yr = c(split$train_blocks, split$test_blocks)),
            "split-site-years")
singles <- singleton_levels(s)
write_table(singles, "site-factor-levels")
record("singleton_factor_levels", sum(singles$site_years == 1),
       "site-level factor levels carried by a single site-year")

pca <- fit_pca(split$train)
write_table(pca_variance_table(pca), "pca-variance")
write_table(pca_loadings_table(pca), "pca-loadings")
write_table(project_pca(pca, split$test), "pca-projection")
record("pca_n_vars", pca$n_vars)
record("pca_n_retained", pca$n_retained, "components with eigenvalue above one")
record("pca_variance_retained", pca$variance_retained)
record("pca_proportion_sum", sum(pca$proportion),
       "proportions of variance must sum to one")
record("pca_pc1_proportion", pca$proportion[1])
record("pca_pc2_proportion", pca$proportion[2])
record("pca_eigenvalue_sum", sum(pca$eigenvalues),
       "equals the number of standardised variables")

save_ggplot("fig07_pca_scree", fig_scree(pca), height = 4.4)
save_ggplot("fig08_pca_scores", fig_pca_scores(pca, split$train))

message("selecting cluster count by majority rule across NbClust indices")
cc <- utils::capture.output(
  nbres <- choose_cluster_count(s, PLANT_VARS, min_nc = 2, max_nc = 8))
record("kmeans_k", nbres$k, "chosen by majority rule, not fixed in advance")
record("kmeans_index_votes", nbres$majority)
record("kmeans_indices_reporting", nbres$n_indices)
write_table(data.frame(clusters = as.integer(names(nbres$votes)),
                       indices_voting = as.integer(nbres$votes)),
            "cluster-count-votes")

km <- fit_kmeans(s, PLANT_VARS, nbres$k)
record("kmeans_between_share", km$between_share,
       "between-cluster share of total sum of squares")
corr <- cluster_correspondence(km$cluster, s)
write_table(corr, "cluster-correspondence")
record("cramers_v_cluster_site_yr",
       corr$cramers_v[corr$grouping == "site_yr"])
record("cramers_v_cluster_treatment",
       corr$cramers_v[corr$grouping == "treatment"])
save_ggplot("fig09_clusters", fig_clusters(
  s, km$cluster,
  sprintf("k = %d chosen by majority rule; association with site-year %.2f, with treatment %.2f (Cramer's V)",
          nbres$k, corr$cramers_v[corr$grouping == "site_yr"],
          corr$cramers_v[corr$grouping == "treatment"])))

# --- 6. inference -----------------------------------------------------------
stage(6, "inference")
av <- rcb_anova(s)
write_table(av$table, "anova-rcb")
record("anova_block_f", av$table$f[av$table$term == "block"])
record("anova_block_p", av$table$p[av$table$term == "block"])
record("anova_treatment_f", av$table$f[av$table$term == "treatment"])
record("anova_treatment_p", av$table$p[av$table$term == "treatment"])

ct <- contrast_table(s)
write_table(ct, "treatment-contrasts")
slug <- function(x) gsub("[^a-z0-9]+", "_", tolower(x))
for (i in seq_len(nrow(ct))) {
  k <- slug(paste(ct$low[i], "to", ct$high[i]))
  record(paste0("contrast_", k, "_estimate"), ct$estimate[i], "Mg/ha")
  record(paste0("contrast_", k, "_ci_low"), ct$ci_low[i])
  record(paste0("contrast_", k, "_ci_high"), ct$ci_high[i])
  record(paste0("contrast_", k, "_p_holm"), ct$p_holm[i])
}
save_ggplot("fig10_treatment_contrasts", fig_contrasts(ct), width = 9.5,
            height = 4.2)

sw <- shapiro_residuals(av$fit)
bf <- brown_forsythe(s, "grain_yield", "treatment")
bfb <- brown_forsythe(s, "grain_yield", "block")
assumptions <- data.frame(
  test = c(sw$test, bf$test, bfb$test),
  statistic = c(sw$statistic, bf$statistic, bfb$statistic),
  p = c(sw$p, bf$p, bfb$p))
write_table(assumptions, "anova-assumptions")
record("shapiro_statistic", sw$statistic)
record("shapiro_p", sw$p)
record("brown_forsythe_treatment_p", bf$p)
record("brown_forsythe_block_p", bfb$p)

scd <- shapiro_contrast_differences(s)
write_table(scd, "contrast-normality")
record("contrast_differences_min_shapiro_p", min(scd$p),
       "smallest p across the five contrasts, on 34 block differences each")

mv <- manova_treatments(s)
write_table(mv, "manova")
record("manova_treatment_pillai", mv$pillai[mv$term == "treatment"])
record("manova_treatment_p", mv$p[mv$term == "treatment"])
record("manova_block_pillai", mv$pillai[mv$term == "block"])

# --- 7. modelling -----------------------------------------------------------
stage(7, "modelling")
assert(length(intersect(ALLOWED_PREDICTORS, BLOCKED_PREDICTORS)) == 0,
       "a predictor appears in both the allowed and the blocked list")
train_plots <- rownames(split$train)
test_plots <- rownames(split$test)
record("split_plot_overlap", length(intersect(train_plots, test_plots)),
       "plots appearing in both partitions")

# Screen the admitted predictors for a tautological relationship with the
# response. A numeric predictor correlating above 0.95 with grain yield in the
# training partition would mean the rule that fixed the predictor set has failed.
numeric_allowed <- ALLOWED_PREDICTORS[
  vapply(ALLOWED_PREDICTORS, function(v) is.numeric(split$train[[v]]),
         logical(1))]
cors <- vapply(numeric_allowed,
               function(v) abs(stats::cor(split$train[[v]],
                                          split$train[[RESPONSE]])),
               numeric(1))
write_table(data.frame(predictor = names(cors),
                       abs_correlation_with_yield = as.numeric(cors)),
            "predictor-response-correlations")
record("max_abs_predictor_response_correlation", max(cors))
record("n_allowed_predictors", length(ALLOWED_PREDICTORS))
record("n_blocked_predictors", length(BLOCKED_PREDICTORS))

base <- fit_baseline(split)
agr <- fit_linear(split, AGRONOMIC_PREDICTORS,
                  name = "linear model, agronomic predictors")
lin <- fit_linear(split, ALLOWED_PREDICTORS,
                  name = "linear model, all admitted predictors")
rf <- fit_forest(split)
leak <- fit_leakage_illustration(split)

plot_split <- split_by_plot(s, train_fraction = 0.7)
rf_plotsplit <- fit_forest(plot_split, name = "random forest, plot-level split",
                           role = "illustration")

metrics_tbl <- rbind(base, agr$metrics, lin$metrics, rf$metrics, leak$metrics,
                     rf_plotsplit$metrics)
write_table(metrics_tbl, "model-metrics")
write_table(agr$coefficients, "linear-model-coefficients")
write_table(rf$importance, "random-forest-importance")

record("baseline_test_rmse", base$rmse)
record("baseline_test_r2", base$r2)
record("agronomic_lm_train_r2", agr$train_r2)
record("agronomic_lm_test_rmse", agr$metrics$rmse)
record("agronomic_lm_test_r2", agr$metrics$r2)
record("n_agronomic_predictors", length(AGRONOMIC_PREDICTORS))
record("lm_train_r2", lin$train_r2)
record("lm_test_rmse", lin$metrics$rmse)
record("lm_test_r2", lin$metrics$r2)
record("rf_test_rmse", rf$metrics$rmse)
record("rf_test_r2", rf$metrics$r2)
record("leakage_test_r2", leak$metrics$r2,
       "illustration only: harvest measurements admitted as predictors")
record("leakage_test_rmse", leak$metrics$rmse)
record("plot_split_rf_test_r2", rf_plotsplit$metrics$r2,
       "illustration only: partitions formed over plots rather than site-years")
record("n_predictive_models", sum(metrics_tbl$role == "predictive"))

message("cross-validating by leaving out one site-year at a time")
cv_tbl <- rbind(
  cv_metrics("training mean", cv_by_site_year(s, learner_mean)),
  cv_metrics("linear model, agronomic predictors",
             cv_by_site_year(s, learner_lm)),
  cv_metrics("random forest, agronomic predictors",
             cv_by_site_year(s, learner_rf)))
write_table(cv_tbl, "cross-validation")
record("cv_folds", cv_tbl$n_folds[1], "one fold per site-year")
record("cv_mean_rmse", cv_tbl$rmse[cv_tbl$model == "training mean"])
record("cv_lm_rmse", cv_tbl$rmse[grepl("^linear", cv_tbl$model)])
record("cv_lm_r2", cv_tbl$r2[grepl("^linear", cv_tbl$model)])
record("cv_rf_rmse", cv_tbl$rmse[grepl("^random", cv_tbl$model)])
record("cv_rf_r2", cv_tbl$r2[grepl("^random", cv_tbl$model)])

rf_pred <- stats::predict(rf$fit, newdata = split$test)
save_ggplot("fig11_observed_vs_predicted",
            fig_observed_predicted(split, rf_pred, sprintf(
              "Random forest on %d predictors fixed before harvest; RMSE %.2f Mg/ha, R-squared %.2f on %d plots in %d site-years",
              length(ALLOWED_PREDICTORS), rf$metrics$rmse, rf$metrics$r2,
              nrow(split$test), length(split$test_blocks))),
            width = 6, height = 6)
save_ggplot("fig12_variable_importance", fig_importance(rf$importance),
            height = 4.6)

# --- 8. record --------------------------------------------------------------
stage(8, "recording")
write_metrics()
si <- utils::capture.output(utils::sessionInfo())
writeLines(c(paste("run date:", format(Sys.Date())), "", si),
           file.path(PATHS$results, "session-info.txt"))
message("\npipeline complete")
