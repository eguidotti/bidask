# Generate reference outputs from the R implementation for the Python parity tests.
#
# Run from the repository root:
#   Rscript python/tests/fixtures/generate_fixtures.R
#
# The script sources r/R/*.R from this checkout (not an installed CRAN build), so
# fixtures always reflect the R code at the same commit as the Python code.
# Requires: R >= 4.0, data.table.

suppressPackageStartupMessages(library(data.table))
setDTthreads(1)
for (f in list.files("r/R", full.names = TRUE)) source(f)

out_dir <- "python/tests/fixtures"
in_dir <- file.path(out_dir, "inputs")
dir.create(in_dir, showWarnings = FALSE, recursive = TRUE)

fmt <- function(v) {
  s <- sprintf("%.17g", v)
  s[is.nan(v)] <- "NaN"
  s[is.na(v) & !is.nan(v)] <- "NA"
  s[is.infinite(v) & v > 0] <- "Inf"
  s[is.infinite(v) & v < 0] <- "-Inf"
  s
}

write_input <- function(name, x) {
  y <- data.frame(lapply(x[, c("Open", "High", "Low", "Close")], fmt))
  write.csv(y, file.path(in_dir, paste0(name, ".csv")), row.names = FALSE, quote = FALSE)
  # compute from the file that the Python tests will read
  z <- read.csv(file.path(in_dir, paste0(name, ".csv")), na.strings = "NA")
  z[] <- lapply(z, as.numeric)
  z
}

# ---------------------------------------------------------------------------
# Input datasets
# ---------------------------------------------------------------------------
data <- list()

# synthetic series shipped with the repo (simulated with a 1% spread)
data$synth <- write_input("synth", head(read.csv("pseudocode/ohlc.csv"), 300))
data$synth_miss <- write_input("synth_miss", head(read.csv("pseudocode/ohlc-miss.csv"), 300))

# real data: MSFT 1-minute bars shipped with the R package (r/inst/extdata/msft.csv)
msft <- read.csv("r/inst/extdata/msft.csv")
colnames(msft) <- sub("^MSFT\\.", "", colnames(msft))
data$msft_minute <- write_input("msft_minute", head(msft, 600))

# real data: the same bars aggregated to daily OHLC (15 trading days)
msft$Date <- substr(msft$Timestamp, 1, 10)
daily <- do.call(rbind, lapply(split(msft, msft$Date), function(d) data.frame(
  Open = d$Open[1], High = max(d$High), Low = min(d$Low), Close = d$Close[nrow(d)]
)))
data$msft_daily <- write_input("msft_daily", daily)

# edge cases
p <- head(read.csv("pseudocode/ohlc.csv"), 60)
data$single_row <- write_input("single_row", p[1, ])
data$two_rows <- write_input("two_rows", p[1:2, ])
data$constant <- write_input("constant", data.frame(Open = rep(100, 40), High = 100, Low = 100, Close = 100))

halted <- p
halted[c(10, 11, 30), ] <- NA                       # missing (halted) days
halted[20, ] <- halted$Close[19]                     # zero-volume: flat at previous close
halted[21, ] <- halted$Close[20]
halted[40, "Open"] <- NA                             # single missing field
data$halted <- write_input("halted", halted)

nonpos <- p[1:40, ]
nonpos[15, "Low"] <- 0                               # log(0) = -Inf
nonpos[25, "Close"] <- -1                            # log(<0) = NaN
data$nonpositive <- write_input("nonpositive", nonpos)

flat_open <- p[1:40, ]
flat_open$Open <- flat_open$High                     # open always at the high: po2 only
data$open_at_high <- write_input("open_at_high", flat_open)

# ---------------------------------------------------------------------------
# Cases
# ---------------------------------------------------------------------------
methods <- c("EDGE", "AR", "AR2", "CS", "CS2", "ROLL",
             "OHL", "OHLC", "CHL", "CHLO", "OHL.CHL", "OHLC.CHLO")

widths <- function(n) {
  w <- list(full = "full", w1 = 1L, w2 = 2L, w3 = 3L, w21 = 21L, expanding = "expanding")
  w$endpoints <- if (n >= 100) c(3L, 35L, 100L) else unique(c(1L, max(1L, n %/% 2L), n))
  w$endpoints_desc <- if (n >= 10) c(1L, 10L, 5L) else NULL   # negative window -> error
  w[!vapply(w, is.null, TRUE)]
}

resolve <- function(w, n) {
  if (identical(w, "full")) return(n)
  if (identical(w, "expanding")) return(seq_len(n))
  w
}

cases <- list()
values <- list()
k <- 0L
for (name in names(data)) {
  x <- data[[name]]
  n <- nrow(x)
  ws <- widths(n)
  for (wname in names(ws)) for (sg in c(FALSE, TRUE)) for (nr in c(FALSE, TRUE)) {
    k <- k + 1L
    id <- sprintf("c%04d", k)
    width <- resolve(ws[[wname]], n)
    rows <- NULL
    vals <- list()
    errs <- character()
    for (m in methods) {
      r <- tryCatch(suppressWarnings(spread(x, width = width, method = m, sign = sg, na.rm = nr)),
                    error = function(e) e)
      if (inherits(r, "error")) {
        errs <- c(errs, sprintf("%s=%s", m, conditionMessage(r)))
        vals[[m]] <- NULL
      } else {
        rows <- as.integer(rownames(r))
        vals[[m]] <- r[[m]]
      }
    }
    width_str <- if (is.character(ws[[wname]])) ws[[wname]] else paste(width, collapse = " ")
    cases[[k]] <- data.frame(case = id, dataset = name, width_name = wname, width = width_str,
                             sign = sg, na_rm = nr, nrow_out = length(rows),
                             errors = paste(errs, collapse = " | "))
    if (length(rows)) {
      df <- data.frame(case = id, row = rows)
      for (m in methods) df[[m]] <- if (is.null(vals[[m]])) "ERROR" else fmt(vals[[m]])
      values[[k]] <- df
    }
  }
}

cases <- do.call(rbind, cases)
values <- do.call(rbind, values[!vapply(values, is.null, TRUE)])
write.csv(cases, file.path(out_dir, "cases.csv"), row.names = FALSE)
con <- gzfile(file.path(out_dir, "expected.csv.gz"), "w")
write.csv(values, con, row.names = FALSE, quote = FALSE)
close(con)

commit <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) "unknown")
writeLines(c(
  sprintf("generated: %s", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  sprintf("r_source_commit: %s", commit),
  sprintf("bidask_r_version: %s", read.dcf("r/DESCRIPTION", "Version")[1]),
  sprintf("R: %s", R.version.string),
  sprintf("data.table: %s", format(packageVersion("data.table")))
), file.path(out_dir, "VERSION.txt"))

cat(sprintf("%d cases, %d value rows\n", nrow(cases), nrow(values)))
