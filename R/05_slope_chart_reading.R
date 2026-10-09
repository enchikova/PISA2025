# Slope chart: PISA reading means, 2015 vs 2025
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# Input: outputs/country_means_2015_2025.csv (from 04_country_means_2015_2025.R)
#        data/slim/*.rds (for the represented-population check)
# Point estimates only. Significance of changes is NOT tested here.

library(tidyverse)
library(ggrepel)

# --- 1. Data ---------------------------------------------------------------
means <- read_csv("outputs/country_means_2015_2025.csv", show_col_types = FALSE) |>
  filter(domain == "READ")

stu15 <- readRDS("data/slim/stu15.rds")
stu25 <- readRDS("data/slim/stu25.rds")

# Represented 15-year-old population (sum of final weights) in each cycle
pop <- bind_rows(stu15, stu25) |>
  group_by(CNT, year) |>
  summarise(pop = sum(W_FSTUWT), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = pop, names_prefix = "pop") |>
  mutate(pop_change_pct = 100 * (pop2025 / pop2015 - 1))

d <- means |>
  left_join(select(pop, CNT, pop_change_pct), by = "CNT") |>
  mutate(
    flag_pop  = abs(pop_change_pct) >= 25,   # represented population changed >= 25%
    highlight = CNT == "PRT",                # change to highlight another country
    group = case_when(
      highlight ~ "Highlighted country",
      flag_pop  ~ "Population changed >= 25%",
      TRUE      ~ "Other countries"
    )
  )

long <- d |>
  pivot_longer(c(y2015, y2025), names_to = "year", values_to = "score") |>
  mutate(year = factor(str_remove(year, "y")))

# Which countries to label: Portugal, the 3 biggest gains, the 5 biggest losses
to_label <- d |>
  mutate(up = min_rank(desc(change)), down = min_rank(change)) |>
  filter(highlight | up <= 3 | down <= 5) |>
  mutate(label = sprintf("%s (%+.0f)", country, change))

labels_2025 <- long |>
  filter(year == "2025") |>
  inner_join(select(to_label, CNT, label), by = "CNT")

# --- 2. Title built from the results --------------------------------------
n_all  <- nrow(d)
n_down <- sum(d$change < 0)
title  <- paste0("Reading scores were lower in 2025 than in 2015 in ",
                 n_down, " of ", n_all, " countries")

caption <- str_wrap(paste(
  "Weighted country means averaged over 10 plausible values.",
  "Point estimates only: statistical significance of changes not tested.",
  "Dashed lines: the represented 15-year-old population changed by 25% or more",
  "between cycles (demography and/or coverage).",
  "Only countries with the same sample code in both cycles are shown",
  "(e.g. B-S-J-G 2015 and B-S-J-Z 2025 China are not comparable).",
  "Source: OECD PISA 2015 and 2025 student data. Chart: Ekaterina Enchikova"
), width = 95)

# --- 3. Plot ----------------------------------------------------------------
p <- ggplot(long, aes(x = year, y = score, group = CNT)) +
  geom_line(data = filter(long, group == "Other countries"),
            colour = "grey75", linewidth = 0.5) +
  geom_line(data = filter(long, group == "Population changed >= 25%"),
            colour = "grey55", linewidth = 0.5, linetype = "22") +
  geom_line(data = filter(long, group == "Highlighted country"),
            colour = "#d95f02", linewidth = 1.4) +
  geom_point(data = filter(long, group == "Highlighted country"),
             colour = "#d95f02", size = 3) +
  geom_text_repel(
    data = labels_2025,
    aes(label = label, colour = CNT == "PRT"),
    nudge_x = 0.12, hjust = 0, direction = "y", size = 3.3,
    segment.size = 0.2, segment.colour = "grey70",
    min.segment.length = 0, show.legend = FALSE
  ) +
  scale_colour_manual(values = c(`TRUE` = "#d95f02", `FALSE` = "grey25")) +
  scale_x_discrete(expand = expansion(add = c(0.15, 1.1))) +
  scale_y_continuous(breaks = seq(300, 550, 50)) +
  labs(title = title, x = NULL, y = "Mean reading score", caption = caption) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.caption = element_text(hjust = 0, colour = "grey35", size = 8,
                                margin = margin(t = 10)),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(face = "bold", size = 12)
  )

# --- 4. Save ----------------------------------------------------------------
dir.create("outputs", showWarnings = FALSE)
ggsave("outputs/slope_reading_2015_2025.png", p, width = 8, height = 9.5,
       dpi = 300, bg = "white")
ggsave("outputs/slope_reading_2015_2025.svg", p, width = 8, height = 9.5)

p
