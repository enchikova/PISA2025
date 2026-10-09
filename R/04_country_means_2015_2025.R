# Weighted country means, PISA 2015 vs 2025 (reading, mathematics, science)
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# Uses the slim files from 03_build_slim_data.R.
# Point estimates only: standard errors (replicate weights) come later.
# Only country codes present in BOTH cycles are kept. Special samples with
# different codes (e.g. B-S-J-G 2015 vs B-S-J-Z 2025) are therefore excluded.

library(tidyverse)
library(haven)

stu15 <- readRDS("data/slim/stu15.rds")
stu25 <- readRDS("data/slim/stu25.rds")

shared <- intersect(unique(stu15$CNT), unique(stu25$CNT))
message(length(shared), " country codes in both cycles")

# Country names from the SPSS value labels
lab <- attr(read_sav("data/2025/CY09_MS_STU_PUF.sav", n_max = 0)$CNT, "labels")
lookup <- tibble(CNT = unname(lab), country = names(lab))

# Weighted mean per plausible value, then average over the 10 PVs
country_means <- function(d, dom) {
  pv <- paste0("PV", 1:10, dom)
  d |>
    filter(CNT %in% shared) |>
    select(CNT, year, W_FSTUWT, all_of(pv)) |>
    pivot_longer(all_of(pv), names_to = "pv", values_to = "score") |>
    filter(!is.na(score), !is.na(W_FSTUWT)) |>
    group_by(CNT, year, pv) |>
    summarise(m = weighted.mean(score, W_FSTUWT), .groups = "drop") |>
    group_by(CNT, year) |>
    summarise(mean = mean(m), .groups = "drop") |>
    mutate(domain = dom)
}

both <- bind_rows(stu15, stu25)

means <- map_dfr(c("READ", "MATH", "SCIE"), \(dom) country_means(both, dom)) |>
  left_join(lookup, by = "CNT")

wide <- means |>
  pivot_wider(names_from = year, values_from = mean, names_prefix = "y") |>
  mutate(change = y2025 - y2015) |>
  arrange(domain, desc(change))

dir.create("outputs", showWarnings = FALSE)
write_csv(wide, "outputs/country_means_2015_2025.csv")

print(wide |> filter(domain == "READ"), n = 70)
