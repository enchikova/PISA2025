# PISA 2025 visuals: slope chart, 2015 vs 2025
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# !! PLACEHOLDER DATA !!
# The numbers below are invented so the script runs. Replace `scores` with
# real country means from the OECD PISA 2025 Results (Volume I) tables
# before publishing anything.

# install.packages(c("tidyverse", "ggrepel"))
library(tidyverse)
library(ggrepel)

# --- 1. Data --------------------------------------------------------------
# One row per country and year. Columns: country, year, score (e.g. reading mean)
scores <- tribble(
  ~country,    ~year, ~score,
  "Country A", 2015,  500,
  "Country A", 2025,  480,
  "Country B", 2015,  520,
  "Country B", 2025,  490,
  "Country C", 2015,  470,
  "Country C", 2025,  475,
  "Country D", 2015,  510,
  "Country D", 2025,  460
) |>
  mutate(year = factor(year))

# Direction of change, used for colour
change <- scores |>
  pivot_wider(names_from = year, values_from = score) |>
  mutate(
    diff = `2025` - `2015`,
    direction = if_else(diff >= 0, "Up", "Down")
  ) |>
  select(country, direction)

plot_data <- scores |> left_join(change, by = "country")

# --- 2. Chart -------------------------------------------------------------
p <- ggplot(plot_data, aes(x = year, y = score, group = country, colour = direction)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_text_repel(
    data = filter(plot_data, year == "2025"),
    aes(label = country),
    nudge_x = 0.15, direction = "y", hjust = 0, segment.size = 0.2,
    show.legend = FALSE
  ) +
  scale_colour_manual(values = c(Up = "#1b9e77", Down = "#d95f02")) +
  scale_x_discrete(expand = expansion(add = c(0.3, 0.8))) +
  labs(
    title = "Reading scores, 2015 vs 2025",
    subtitle = "Placeholder data: replace with OECD PISA 2025 results",
    x = NULL, y = "Mean score", colour = NULL,
    caption = "Source: OECD PISA. Chart: Ekaterina Enchikova"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

# --- 3. Save --------------------------------------------------------------
dir.create("outputs", showWarnings = FALSE)
ggsave("outputs/slope_chart.png", p, width = 7, height = 5, dpi = 300, bg = "white")
ggsave("outputs/slope_chart.svg", p, width = 7, height = 5)

p
