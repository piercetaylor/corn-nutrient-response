#!/usr/bin/env Rscript
# Obtain the analysis workbook from its repository of record.
#
# The data are deposited at Data Dryad under doi:10.5061/dryad.p30c6 (Wortmann,
# Dobermann, Ferguson, Hergert, Shapiro, Tarkalson and Walters) and released
# under CC0. This script resolves the DOI through the Dryad API, downloads the
# current version, extracts the workbook, and verifies its SHA-256 digest
# against the value Dryad publishes in its own file metadata. Verification is
# therefore against the publisher's record, not against a value asserted here.
#
# The per-file download endpoint requires an API bearer token and the browser
# download path is behind an interactive challenge; the version-level archive
# endpoint is public and unauthenticated, so that is the route used.
#
# Run from the repository root:
#   Rscript data/download_data.R

source(file.path("R", "99_utils.R"))

resolve_version <- function(doi) {
  url <- sprintf("%s/datasets/doi%%3A%s", DRYAD$api_base,
                 utils::URLencode(doi, reserved = TRUE))
  txt <- paste(readLines(url, warn = FALSE), collapse = "")
  # The version href is the authoritative pointer to the current deposit.
  m <- regmatches(txt, regexpr('"stash:version":[{]"href":"/api/v2/versions/[0-9]+"', txt))
  assert(length(m) == 1L, "could not resolve current version from %s", url)
  # Take the digits that follow "versions/" only. Stripping every non-digit from
  # the matched string would fold the "2" of "/api/v2/" into the identifier.
  id <- sub("^versions/", "", regmatches(m, regexpr("versions/[0-9]+", m)))
  assert(nzchar(id), "version identifier came back empty from %s", url)
  list(id = id, metadata = txt)
}

published_digest <- function(version_id, filename) {
  url <- sprintf("%s/versions/%s/files", DRYAD$api_base, version_id)
  txt <- paste(readLines(url, warn = FALSE), collapse = "")
  entries <- strsplit(txt, '[{]"_links"')[[1]]
  hit <- entries[grepl(filename, entries, fixed = TRUE)]
  assert(length(hit) >= 1L, "file '%s' not listed in version %s", filename, version_id)
  digest <- regmatches(hit[1], regexpr('"digest":"[0-9a-f]{64}"', hit[1]))
  size <- regmatches(hit[1], regexpr('"size":[0-9]+', hit[1]))
  assert(length(digest) == 1L, "no SHA-256 digest published for '%s'", filename)
  list(sha256 = gsub('.*"digest":"|"', "", digest),
       bytes  = as.integer(sub('"size":', "", size)))
}

fetch_version_archive <- function(version_id, dest) {
  url <- sprintf("%s/versions/%s/download", DRYAD$api_base, version_id)
  message("downloading ", url)
  old <- options(timeout = 1800)
  on.exit(options(old), add = TRUE)
  utils::download.file(url, dest, mode = "wb", quiet = FALSE)
  assert(file.exists(dest) && file.size(dest) > 1e7,
         "downloaded archive is missing or implausibly small: %s", dest)
  invisible(dest)
}

main <- function() {
  dir.create(PATHS$raw_dir, recursive = TRUE, showWarnings = FALSE)

  if (file.exists(PATHS$raw_xls) &&
      identical(sha256_file(PATHS$raw_xls), DRYAD$data_sha256)) {
    message("workbook already present and verified; nothing to download")
    return(invisible(TRUE))
  }

  ver <- resolve_version(DRYAD$doi)
  message("Dryad version id: ", ver$id)

  pub <- published_digest(ver$id, DRYAD$data_file)
  message("Dryad-published digest: ", pub$sha256)
  assert(identical(pub$sha256, DRYAD$data_sha256),
         paste("Dryad now publishes a different digest for %s.",
               "Expected %s, Dryad reports %s. The deposit has been revised;",
               "review the change before updating the recorded expectation."),
         DRYAD$data_file, DRYAD$data_sha256, pub$sha256)

  # The version archive is assembled on demand, so the zip itself is not
  # byte-stable and is not checksummed. The extracted workbook is.
  zip_path <- file.path(PATHS$raw_dir, "dryad_version_archive.zip")
  fetch_version_archive(ver$id, zip_path)
  utils::unzip(zip_path, exdir = PATHS$raw_dir)
  unlink(zip_path)

  assert(file.exists(PATHS$raw_xls), "workbook not found after extraction: %s",
         PATHS$raw_xls)
  got <- sha256_file(PATHS$raw_xls)
  assert(identical(got, DRYAD$data_sha256),
         "SHA-256 mismatch for %s\n  expected %s\n  observed %s",
         PATHS$raw_xls, DRYAD$data_sha256, got)
  assert(file.size(PATHS$raw_xls) == DRYAD$data_bytes,
         "size mismatch for %s: expected %d bytes, observed %d",
         PATHS$raw_xls, DRYAD$data_bytes, file.size(PATHS$raw_xls))

  message("verified ", PATHS$raw_xls)
  message("SHA-256 ", got)
  invisible(TRUE)
}

if (sys.nframe() == 0L) main()
