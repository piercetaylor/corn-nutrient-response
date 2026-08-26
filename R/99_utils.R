# Shared constants, paths, and small helpers used by every pipeline stage.

SEED <- 20250317L

PATHS <- list(
  raw_dir   = file.path("data", "raw"),
  raw_xls   = file.path("data", "raw", "Nebr_HiYieldCornNPKS_Feb_2021.xls"),
  checksums = file.path("data", "checksums.txt"),
  figures   = "figures",
  results   = "results"
)

# The Dryad record for the deposited workbook. The digest is published by Dryad
# in its own file metadata, so the expectation below can be checked against the
# repository of record rather than against a value invented here.
DRYAD <- list(
  doi        = "10.5061/dryad.p30c6",
  api_base   = "https://datadryad.org/api/v2",
  data_file  = "Nebr_HiYieldCornNPKS_Feb_2021.xls",
  data_sha256 = "62262f92257fa26f7927fa2ad5bbeaf9f026d7ab96fbfdb7834ad2dcf185d2df",
  data_bytes = 51500032
)

# Structural expectations recorded when the workbook was first read. The schema
# gate fails if a later download drifts from any of these.
EXPECTED <- list(
  sheets        = c("Site-year information", "Treatments", "Variables",
                    "Data", "Means", "SE"),
  data_rows     = 1483L,
  data_cols     = 162L,
  siteyear_rows = 34L,
  site_years    = 34L,
  standard_treatments = 9L,
  standard_rows = 1211L
)

ensure_dirs <- function() {
  for (d in c(PATHS$figures, PATHS$results)) {
    if (!dir.exists(d)) dir.create(d, recursive = TRUE)
  }
  invisible(TRUE)
}

# --- assertion helper -------------------------------------------------------
# Every check in the pipeline goes through this, so a violated expectation stops
# the run at the point of violation with the observed value in the message.
assert <- function(condition, fmt, ...) {
  if (!isTRUE(condition)) stop(sprintf(fmt, ...), call. = FALSE)
  invisible(TRUE)
}

# --- results ledger ---------------------------------------------------------
# Named scalars written to results/metrics.csv. The gate scripts read this file,
# so any quantity a gate needs to judge must be recorded here by the pipeline.
.metrics <- new.env(parent = emptyenv())
.metrics$rows <- list()

record <- function(key, value, note = "") {
  .metrics$rows[[length(.metrics$rows) + 1L]] <-
    data.frame(key = key,
               value = if (is.numeric(value)) format(value, digits = 10) else as.character(value),
               note = note, stringsAsFactors = FALSE)
  invisible(value)
}

write_metrics <- function(path = file.path(PATHS$results, "metrics.csv")) {
  out <- do.call(rbind, .metrics$rows)
  assert(!is.null(out), "no metrics were recorded")
  utils::write.csv(out, path, row.names = FALSE)
  message(sprintf("wrote %s (%d metrics)", path, nrow(out)))
  invisible(out)
}

read_metrics <- function(path = file.path(PATHS$results, "metrics.csv")) {
  assert(file.exists(path), "metrics file not found: %s", path)
  m <- utils::read.csv(path, stringsAsFactors = FALSE)
  stats::setNames(m$value, m$key)
}

metric_num <- function(m, key) {
  assert(key %in% names(m), "metric '%s' not present in results/metrics.csv", key)
  as.numeric(m[[key]])
}

# --- table output -----------------------------------------------------------
write_table <- function(x, name) {
  path <- file.path(PATHS$results, paste0(name, ".csv"))
  utils::write.csv(x, path, row.names = FALSE)
  message(sprintf("wrote %s (%d rows)", path, nrow(x)))
  invisible(path)
}

# --- figure output ----------------------------------------------------------
# One figure device wrapper so every figure in the repository shares dimensions,
# resolution, and background, and so figure files are never left half-written.
save_figure <- function(name, plot_expr, width = 7.5, height = 5.0, dpi = 150) {
  path <- file.path(PATHS$figures, paste0(name, ".png"))
  grDevices::png(path, width = width * dpi, height = height * dpi, res = dpi,
                 bg = "white", type = "cairo")
  on.exit(grDevices::dev.off(), add = TRUE)
  force(plot_expr)
  message(sprintf("wrote %s", path))
  invisible(path)
}

save_ggplot <- function(name, p, width = 7.5, height = 5.0, dpi = 150) {
  path <- file.path(PATHS$figures, paste0(name, ".png"))
  ggplot2::ggsave(path, p, width = width, height = height, dpi = dpi,
                  bg = "white")
  message(sprintf("wrote %s", path))
  invisible(path)
}

theme_report <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 11),
      plot.subtitle = ggplot2::element_text(size = 9, colour = "grey30"),
      plot.caption = ggplot2::element_text(size = 8, colour = "grey40", hjust = 0)
    )
}

# Base R hashes with MD5 only, so SHA-256 is delegated to a system tool rather
# than added as a further package dependency. certutil ships with Windows and
# sha256sum with GNU coreutils, which covers the platforms this repository runs on.
sha256_file <- function(path) {
  assert(file.exists(path), "file not found: %s", path)
  out <- tryCatch(
    system2("certutil", c("-hashfile", shQuote(normalizePath(path)), "SHA256"),
            stdout = TRUE, stderr = FALSE),
    error = function(e) NULL)
  if (!is.null(out)) {
    hit <- grep("^[0-9a-fA-F ]{60,}$", trimws(out), value = TRUE)
    if (length(hit)) return(tolower(gsub("[^0-9a-fA-F]", "", hit[1])))
  }
  out <- tryCatch(system2("sha256sum", shQuote(path), stdout = TRUE),
                  error = function(e) NULL)
  if (!is.null(out) && length(out)) return(sub(" .*$", "", out[1]))
  stop("no SHA-256 implementation available (tried certutil and sha256sum)")
}
