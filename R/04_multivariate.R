# Stage 4: dimension reduction and clustering.
#
# The plant measurements are heavily redundant: uptake of each nutrient is the
# product of a tissue concentration and a dry-matter mass, and the harvest
# indices are ratios of those same masses. Principal components are used here to
# describe that redundancy, not to build a predictor of yield. Grain yield is an
# algebraic component of several of these variables, so any model that predicts
# yield from components fitted on them is circular. Prediction is handled
# separately in R/06_models.R with a predictor set fixed before harvest.
#
# The components are fitted on the training site-years only and projected onto
# the held-out site-years, so that the retained structure can be shown to be a
# property of the experiment rather than of one particular subset of fields.

suppressPackageStartupMessages({
  library(dplyr)
  library(NbClust)
})

# Split by site-year, never by plot. Plots within a site-year share a field, a
# hybrid, a planting date and a season, so a split that scatters them across the
# partitions leaves near-duplicates on both sides.
#
# Texture, tillage and previous crop are properties of a site-year, and some
# levels are represented by a single site-year. A partition that placed such a
# site-year in the test set would ask the model to predict from a category it
# had never seen. The split is therefore drawn repeatedly, with a deterministic
# sequence of seeds, until every level of those factors is present in the
# training partition. Which site-years that constraint pins to the training set
# is recorded, because it bounds what the held-out estimate can speak to.
split_by_site_year <- function(d, train_fraction = 0.7, seed = SEED,
                               ensure_levels = c("texture", "tillage",
                                                 "prev_crop"),
                               max_attempts = 200) {
  blocks <- sort(unique(as.integer(as.character(d$block))))
  n_train <- round(train_fraction * length(blocks))
  block_of <- as.integer(as.character(d$block))

  covered <- function(train_blocks) {
    tr <- d[block_of %in% train_blocks, ]
    all(vapply(ensure_levels, function(v)
      setequal(levels(droplevels(factor(tr[[v]]))),
               levels(droplevels(factor(d[[v]])))), logical(1)))
  }

  for (attempt in seq_len(max_attempts)) {
    set.seed(seed + attempt - 1L)
    train_blocks <- sort(sample(blocks, n_train))
    if (covered(train_blocks)) break
    if (attempt == max_attempts)
      stop(sprintf("no partition after %d attempts covers every level of %s",
                   max_attempts, paste(ensure_levels, collapse = ", ")),
           call. = FALSE)
  }
  test_blocks <- setdiff(blocks, train_blocks)
  assert(length(intersect(train_blocks, test_blocks)) == 0,
         "training and test site-years overlap")
  assert(length(test_blocks) > 0, "test partition is empty")
  list(train_blocks = train_blocks, test_blocks = test_blocks,
       attempts = attempt,
       train = d[block_of %in% train_blocks, ],
       test  = d[block_of %in% test_blocks, ])
}

# Levels of a site-level factor carried by a single site-year. Such a level can
# only ever appear on one side of a site-year split.
singleton_levels <- function(d, vars = c("texture", "tillage", "prev_crop")) {
  do.call(rbind, lapply(vars, function(v) {
    n <- tapply(d$site_yr, d[[v]], function(x) length(unique(x)))
    data.frame(variable = v, level = names(n), site_years = as.integer(n),
               row.names = NULL)
  }))
}

# Principal components on standardised plant measurements, with the number of
# components fixed by Kaiser's criterion: retain components whose eigenvalue
# exceeds the average eigenvalue, which for standardised data is one.
fit_pca <- function(train, vars = PLANT_VARS) {
  p <- stats::prcomp(train[, vars], center = TRUE, scale. = TRUE)
  eig <- p$sdev^2
  prop <- eig / sum(eig)
  retained <- sum(eig > 1)
  list(fit = p, eigenvalues = eig, proportion = prop,
       cumulative = cumsum(prop), n_retained = retained,
       variance_retained = sum(prop[seq_len(retained)]),
       n_vars = length(vars))
}

pca_loadings_table <- function(pca, n = pca$n_retained) {
  l <- pca$fit$rotation[, seq_len(n), drop = FALSE]
  data.frame(variable = rownames(l), round(l, 3), row.names = NULL)
}

pca_variance_table <- function(pca) {
  data.frame(component = paste0("PC", seq_along(pca$eigenvalues)),
             eigenvalue = pca$eigenvalues,
             proportion = pca$proportion,
             cumulative = pca$cumulative)
}

# Projecting the held-out site-years onto the training components and comparing
# the resulting variances shows whether the structure transfers to fields the
# components were not fitted on.
project_pca <- function(pca, test, vars = PLANT_VARS) {
  scores <- stats::predict(pca$fit, newdata = test[, vars])
  v <- apply(scores, 2, stats::var)
  data.frame(component = colnames(scores),
             train_eigenvalue = pca$eigenvalues,
             test_variance = as.numeric(v))
}

# Cluster count chosen by the majority rule across the indices NbClust computes,
# not by inspection and not fixed in advance. The chosen value is returned with
# the vote count that produced it.
choose_cluster_count <- function(d, vars, min_nc = 2, max_nc = 8,
                                 seed = SEED, sample_n = NULL) {
  x <- scale(as.matrix(d[, vars]))
  set.seed(seed)
  if (!is.null(sample_n) && nrow(x) > sample_n) {
    x <- x[sort(sample(nrow(x), sample_n)), , drop = FALSE]
  }
  # Several NbClust indices draw diagnostic plots. With no device open R would
  # start one and leave an Rplots.pdf behind in the working directory, so a null
  # device absorbs them; the votes, not the plots, are what is wanted here.
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  nb <- NbClust::NbClust(x, distance = "euclidean", min.nc = min_nc,
                         max.nc = max_nc, method = "kmeans", index = "all")
  votes <- table(nb$Best.nc["Number_clusters", ])
  votes <- votes[names(votes) != "0"]
  best <- as.integer(names(votes)[which.max(votes)])
  list(k = best, votes = votes, n_indices = sum(votes),
       majority = as.integer(max(votes)))
}

fit_kmeans <- function(d, vars, k, seed = SEED, nstart = 25) {
  x <- scale(as.matrix(d[, vars]))
  set.seed(seed)
  km <- stats::kmeans(x, centers = k, nstart = nstart, iter.max = 100)
  list(fit = km, cluster = factor(km$cluster),
       between_share = km$betweenss / km$totss)
}

# Cramer's V between the cluster assignment and a candidate explanation. The
# comparison of interest is whether clusters track site-year or treatment.
cramers_v <- function(a, b) {
  tab <- table(a, b)
  chi <- suppressWarnings(stats::chisq.test(tab)$statistic)
  n <- sum(tab)
  as.numeric(sqrt((chi / n) / (min(dim(tab)) - 1)))
}

cluster_correspondence <- function(cluster, d) {
  data.frame(
    grouping = c("site_yr", "treatment", "texture", "tillage", "prev_crop"),
    cramers_v = c(cramers_v(cluster, d$site_yr),
                  cramers_v(cluster, d$treatment),
                  cramers_v(cluster, d$texture),
                  cramers_v(cluster, d$tillage),
                  cramers_v(cluster, d$prev_crop))
  )
}

# --- figures ----------------------------------------------------------------

fig_scree <- function(pca) {
  v <- pca_variance_table(pca)
  v$retained <- v$eigenvalue > 1
  ggplot2::ggplot(v, ggplot2::aes(x = stats::reorder(component, -eigenvalue),
                                  y = eigenvalue, fill = retained)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                        colour = "firebrick") +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "grey35", `FALSE` = "grey80"),
                               guide = "none") +
    ggplot2::labs(
      title = "Eigenvalues of the principal components",
      subtitle = sprintf("Kaiser's criterion retains %d of %d components, accounting for %.0f percent of total variance",
                         pca$n_retained, pca$n_vars, 100 * pca$variance_retained),
      x = NULL, y = "Eigenvalue",
      caption = "Dashed line marks an eigenvalue of one, the average for standardised variables.") +
    theme_report() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

fig_pca_scores <- function(pca, train, colour_by = "treatment") {
  scores <- as.data.frame(pca$fit$x[, 1:2])
  scores[[colour_by]] <- train[[colour_by]]
  ggplot2::ggplot(scores, ggplot2::aes(x = PC1, y = PC2,
                                       colour = .data[[colour_by]])) +
    ggplot2::geom_point(alpha = 0.7, size = 1.1) +
    ggplot2::scale_colour_viridis_d(option = "D", name = "Treatment") +
    ggplot2::labs(
      title = "Plots in the plane of the first two principal components",
      subtitle = sprintf("PC1 accounts for %.0f percent of variance, PC2 for %.0f percent",
                         100 * pca$proportion[1], 100 * pca$proportion[2]),
      x = "PC1", y = "PC2") +
    theme_report()
}

fig_clusters <- function(d, cluster, subtitle) {
  df <- data.frame(longitude = d$longitude, latitude = d$latitude,
                   cluster = cluster)
  ggplot2::ggplot(df, ggplot2::aes(x = longitude, y = latitude,
                                   colour = cluster)) +
    ggplot2::geom_jitter(width = 0.05, height = 0.05, alpha = 0.6, size = 1) +
    ggplot2::scale_colour_viridis_d(option = "C", name = "Cluster") +
    ggplot2::labs(title = "Cluster membership against field position",
                  subtitle = subtitle,
                  x = "Longitude", y = "Latitude") +
    theme_report()
}
