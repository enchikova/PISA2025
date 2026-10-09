# Analysis and Visualisations of PISA 2025 Results

Exploratory analysis and data visualisation of the OECD's Programme for International Student Assessment (PISA) 2025, using R.

**Status:** work in progress. New studies are added as separate folders under `studies/`.

## Studies

| Study | Description |
|---|---|
| [Change in reading performance, PISA 2015–2025](studies/reading-change-2015-2025/) | Arrow chart of the change in mean reading scores across 63 countries and economies |

## Structure

- `R/` shared steps (reading the PISA files, computing weighted country means)
- `outputs/` shared derived data
- `studies/<study-name>/` one folder per study: its own README, script and figures
- `data/` raw OECD files (git-ignored, not in this repository)

## Aims

- Explore PISA 2025 student performance (reading, mathematics, science) across countries and economies.
- Practise careful handling of PISA's complex survey design (sampling weights, plausible values, replicate weights).
- Build clear, publication-quality graphics with R and ggplot2.

Author: [Ekaterina Enchikova](https://orcid.org/0000-0002-3919-2447) · [LinkedIn](https://www.linkedin.com/in/enchikova) · [GitHub](https://github.com/enchikova)

