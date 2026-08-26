# Stage 1: read the deposited workbook.
#
# The workbook holds six worksheets. Three are used here: "Data" (plot-level
# observations), "Site-year information" (one row per site-year) and "Variables"
# (the depositors' data dictionary). "Means" and "SE" are treatment summaries
# derived from "Data" and are not read; "Treatments" is a per-site-year listing
# of treatment codes that adds nothing to the rates already carried in "Data".
#
# Sheets are read with minimal name repair so that the header is seen exactly as
# deposited. The workbook contains repeated column names (HI, UN, NHI and others
# appear twice), and letting the reader silently rename them would hide that.
# Columns are therefore resolved by position against a recorded header.

suppressPackageStartupMessages(library(readxl))

read_header <- function(path, sheet) {
  h <- suppressWarnings(readxl::read_excel(path, sheet = sheet, n_max = 0,
                                           .name_repair = "minimal"))
  names(h)
}

# Resolve a deposited column name to a position. Repeated names are disambiguated
# by occurrence, which is why `which` is explicit rather than implied.
col_index <- function(header, name, which = 1L) {
  hits <- which(header == name)
  assert(length(hits) >= which,
         "column '%s' occurrence %d not found in worksheet header", name, which)
  hits[which]
}

read_plot_data <- function(path = PATHS$raw_xls) {
  header <- read_header(path, "Data")
  d <- suppressWarnings(readxl::read_excel(path, sheet = "Data",
                                           guess_max = 5000,
                                           .name_repair = "minimal"))
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  names(d) <- header
  attr(d, "header") <- header
  d
}

read_siteyear <- function(path = PATHS$raw_xls) {
  d <- suppressWarnings(readxl::read_excel(path, sheet = "Site-year information",
                                           guess_max = 5000,
                                           .name_repair = "minimal"))
  as.data.frame(d, stringsAsFactors = FALSE)
}

# The depositors' dictionary: variable, unit, description. The sheet has a title
# row above the entries, so the first row is dropped and the three informative
# columns are kept.
read_dictionary <- function(path = PATHS$raw_xls) {
  d <- suppressWarnings(readxl::read_excel(path, sheet = "Variables",
                                           col_names = FALSE,
                                           .name_repair = "minimal"))
  d <- as.data.frame(d, stringsAsFactors = FALSE)[, 1:3]
  names(d) <- c("variable", "unit", "description")
  d <- d[-1, ]
  d <- d[!is.na(d$variable), ]
  rownames(d) <- NULL
  d
}

read_sheet_names <- function(path = PATHS$raw_xls) readxl::excel_sheets(path)
