# Change in reading performance, PISA 2015–2025

Analysis and visualisations of PISA 2025 results, with a first chart comparing mean reading scores in PISA 2015 and PISA 2025.

![Change in reading performance, PISA 2015–2025](outputs/arrows_reading_2015_2025.png)

*Each arrow runs from a country's mean reading score in 2015 (dot) to its score in 2025 (arrowhead). Orange = lower in 2025, green = higher, blue = about the same (under 3 points). Larger changes get larger arrowheads and larger names.*

## Key points

- **55 of 63 countries and economies** scored lower in reading in 2025 than in 2015 (by 3+ points).
- The **median change** across countries was **−19 points**.
- Countries are sorted by their 2015 score (highest at the top). † marks countries where the represented 15-year-old population changed by 25% or more (demography and/or coverage), so the change should be read with caution.

## Important caveats

- **Point estimates only.** Colours and sizes reflect the size of the difference between point estimates. Statistical significance (standard errors from the 80 replicate weights, plus link error between cycles) has **not** been tested yet.
- Only countries with the **same sample code in both cycles** are shown (for example, China's 2015 sample B-S-J-G and 2025 sample B-S-J-Z are not comparable and are excluded). Uzbekistan has no 2025 reading score.
- 2025 means were checked against the OECD's published PISA 2025 reading table.

## Method

Weighted country means (final student weight `W_FSTUWT`), computed separately for each of the 10 plausible values and then averaged.

## Repository structure

| File | Purpose |
|---|---|
| `R/03_build_slim_data.R` | Reads only the needed columns from the PISA 2015 and 2025 SPSS files and saves slim `.rds` files |
| `R/04_country_means_2015_2025.R` | Computes weighted country means (reading, mathematics, science) and changes |
| `R/06_dumbbell_reading.R` | Builds the arrow chart (set `save_outputs <- TRUE` to write PNG/SVG and notes) |
| `R/01_…`, `R/02_…` | Early starter scripts |
| `outputs/` | Country means (CSV), final chart (PNG, SVG) and chart notes |

## Reproduce

1. Download the student files from the OECD (PISA 2015 `CY6_MS_CMB_STU_QQQ.sav`, PISA 2025 `CY09_MS_STU_PUF.sav`) into `data/` (git-ignored; raw data is not included in this repository).
2. Run `R/03_build_slim_data.R`, then `R/04_country_means_2015_2025.R`, then `R/06_dumbbell_reading.R`.

R packages: `tidyverse`, `haven`, `showtext`, `sysfonts`, `scales`.

## Source and credit

OECD, PISA 2015 and PISA 2025 student data.
Analysis and chart: [Ekaterina Enchikova](https://orcid.org/0000-0002-3919-2447) · [LinkedIn](https://www.linkedin.com/in/enchikova) · [GitHub](https://github.com/enchikova)
