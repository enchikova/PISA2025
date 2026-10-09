# PISA 2025: country means from the student questionnaire file
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# STEP 0 (manual): download and unzip
#   https://webfs.oecd.org/pisa2022/2025/CY09_MS_STU_PUF.zip
# into data/ (do NOT commit it to GitHub: add data/ to .gitignore).
# The unzipped file is SPSS (.sav). File name below is a guess: adjust it.
#
# NOTE: variable names are assumed to follow earlier PISA cycles
# (CNT, W_FSTUWT, PV1READ..PV10READ, PV1MATH.., PV1SCIE..).
# CHECK THEM against the PISA 2025 codebook before trusting results.

# install.packages(c("haven", "tidyverse"))
library(haven)
library(tidyverse)

sav_file <- "data/CY09_MS_STU_QQQ.sav"   # <- adjust to the real file name

# --- 1. Read only the columns we need (the full file is huge) --------------
stu <- read_sav(
  sav_file,
  col_select = c(CNT, W_FSTUWT, starts_with("PV") & matches("READ|MATH|SCIE"))
)

# --- 2. Sanity checks -----------------------------------------------------
glimpse(stu)
stopifnot(all(c("CNT", "W_FSTUWT") %in% names(stu)))
names(stu)[str_detect(names(stu), "^PV1")]   # which domains exist?

# --- 3. Weighted country means, averaged over plausible values -------------
# Correct point estimate: compute the weighted mean for EACH plausible value,
# then average those means. (Do not average the PVs per student first.)
country_mean <- function(data, prefix) {
  pv_cols <- names(data)[str_detect(names(data), paste0("^PV\\d+", prefix, "$"))]
  map_dfr(pv_cols, \(col) {
    data |>
      filter(!is.na(.data[[col]]), !is.na(W_FSTUWT)) |>
      group_by(CNT) |>
      summarise(mean_pv = weighted.mean(.data[[col]], W_FSTUWT), .groups = "drop")
  }) |>
    group_by(CNT) |>
    summarise(mean_score = mean(mean_pv), .groups = "drop") |>
    mutate(domain = prefix)
}

reading <- country_mean(stu, "READ")
# math    <- country_mean(stu, "MATH")
# science <- country_mean(stu, "SCIE")

# CAUTION: standard errors need the 80 replicate weights (BRR/Fay) plus
# imputation variance across PVs. Use intsvy or EdSurvey for publication.
# Compare your means with the OECD Volume I tables before posting.

dir.create("outputs", showWarnings = FALSE)
write_csv(reading, "outputs/reading_country_means_2025.csv")

reading |> arrange(desc(mean_score)) |> print(n = 20)
