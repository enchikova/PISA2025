# Build slim analysis files from the big PISA SPSS files
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# Reads ONLY the columns needed for country means (id, country, final weight,
# 10 plausible values each for reading, mathematics, science) and saves them
# as small .rds files in data/slim/ (ignored by Git because data/ is ignored).
# Run once; later scripts load the slim files in seconds.
#
# Replicate weights (W_FSTURWT1-80) are NOT included yet: they are needed for
# standard errors and will be added in a later step.

library(haven)
library(tidyverse)

pv_cols <- c(
  paste0("PV", 1:10, "READ"),
  paste0("PV", 1:10, "MATH"),
  paste0("PV", 1:10, "SCIE")
)
keep <- c("CNT", "CNTSTUID", "W_FSTUWT", pv_cols)

read_slim <- function(path, year) {
  message("Reading ", path, " (this can take a few minutes)...")
  read_sav(path, col_select = all_of(keep)) |>
    mutate(
      CNT = as.character(zap_labels(CNT)),
      across(c(CNTSTUID, W_FSTUWT, all_of(pv_cols)), \(x) as.numeric(zap_labels(x))),
      year = year
    ) |>
    zap_formats()
}

dir.create("data/slim", showWarnings = FALSE, recursive = TRUE)

# --- 2025 -----------------------------------------------------------------
stu25 <- read_slim("data/2025/CY09_MS_STU_PUF.sav", 2025)
saveRDS(stu25, "data/slim/stu25.rds")

# --- 2015 -----------------------------------------------------------------
stu15 <- read_slim("data/2015/CY6_MS_CMB_STU_QQQ.sav", 2015)
saveRDS(stu15, "data/slim/stu15.rds")

# --- Quick checks (look at these before going further) --------------------
for (d in list(stu15, stu25)) {
  cat("\nYear", d$year[1], ":", nrow(d), "students,",
      n_distinct(d$CNT), "country codes\n")
  cat("Missing weights:", sum(is.na(d$W_FSTUWT)),
      "| Missing PV1READ:", sum(is.na(d$PV1READ)), "\n")
}
