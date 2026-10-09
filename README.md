# Analysis and Visualisations of PISA 2025 Results

Exploratory analysis and data visualisation of the OECD's **Programme for International Student Assessment (PISA) 2025**, using R.

**Status:** work in progress. Charts and findings will be added as the analysis develops.

## Aims

- Explore PISA 2025 student performance (reading, mathematics, science) across countries and economies.
- Practise careful handling of PISA's complex survey design (sampling weights, plausible values, replicate weights).
- Build clear, publication-quality graphics with R and ggplot2.

## Data

PISA 2025 microdata are published by the OECD and are **not included in this repository**.

- Official data page: https://www.oecd.org/en/about/programmes/pisa/pisa-data.html
- To reproduce the analysis, download the student questionnaire data file (SPSS format) from the OECD and unzip it into a local `data/` folder. This folder is excluded from version control.

Please check the OECD terms of use and the PISA 2025 codebook before working with the data.

## Repository structure

```
R/          analysis and plotting scripts
data/       raw data (not tracked by Git)
outputs/    charts and derived tables
```

## Methods notes

- Country means are computed per plausible value with the final student weight, then averaged across plausible values.
- Standard errors require the replicate weights and imputation variance; results shown in published charts should use dedicated survey tools (e.g. `intsvy` or `EdSurvey`).
- Results should be validated against the OECD's published tables.

## How to run

1. Clone the repository.
2. Download and unzip the data as described above.
3. Open the project in RStudio and run the scripts in `R/` in numeric order.

Required packages: `tidyverse`, `haven`, `ggrepel` (and `intsvy` for standard errors).

## Author

**Ekaterina Enchikova**
ORCID: https://orcid.org/0000-0002-3919-2447
LinkedIn: https://www.linkedin.com/in/enchikova

## Acknowledgements

Data: OECD, PISA 2025 Results. This project is independent and is not affiliated with or endorsed by the OECD.
