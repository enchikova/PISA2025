# Arrow chart: PISA reading means, 2015 -> 2025, all shared countries (v24, infographic style)
# Author: Ekaterina Enchikova (ORCID: 0000-0002-3919-2447)
#
# Input: outputs/country_means_2015_2025.csv (from 04_country_means_2015_2025.R)
#        data/slim/*.rds (for the represented-population check)
# Colour intensity and arrowhead size follow the size of the POINT-ESTIMATE change.
# Statistical significance is NOT tested here.

# install.packages(c("showtext", "sysfonts"))   # for the Inter font
library(tidyverse)

sort_by <- "y2015"       # "y2015" (starting level) or "change" (size of change)
thr <- 3                 # changes smaller than this (points) = "about the same"
study_dir <- "studies/reading-change-2015-2025"   # where figures are saved
save_outputs <- FALSE    # TRUE = also write the PNG/SVG and the notes file
arrow_style <- "open"    # "filled" | "open" | "dots" | "gap"  (see make_arrow below)
end_gap <- 4             # only for arrow_style "gap": gap (score points) before the 2025 dot
txt_min <- 3.0           # smallest country-name size (for the smallest change)
row_min <- 1.0           # row height for the smallest change
row_max <- 1.9           # row height for the largest change
w_cap <- 60              # changes of this size (points) or more get the maximum emphasis
txt_max <- 4.8           # largest country-name size (for the largest change); try 4.0

# Colours: deep -> pale for drops, blue for "about the same", pale -> deep for gains
col_down_deep <- "#8c2d04"
col_down_pale <- "#f5a35c"
col_same      <- "#2b6cb0"
col_up_pale   <- "#8fd19e"
col_up_deep   <- "#006d2c"

# Infographic look
bg_col    <- "#fbf7f0"   # warm off-white background
zebra_col <- "#f3ece1"   # alternate row shading
grid_col  <- "#e8dfd0"   # vertical grid lines and header divider
ink_col   <- "#1f2a44"   # title colour
col_key   <- "#c4651c"   # colour of the example arrow and the median number

# --- 0. Font (Inter via Google Fonts; falls back to the default font) -------
font_ok <- tryCatch({
  sysfonts::font_add_google("Inter", "Inter", regular.wt = 400, bold.wt = 700)
  showtext::showtext_auto()
  showtext::showtext_opts(dpi = 96)
  TRUE
}, error = function(e) {
  message("Could not load the Inter font (", conditionMessage(e), "). Using default.")
  FALSE
})
fam <- if (font_ok) "Inter" else ""

# --- 1. Data ---------------------------------------------------------------
means <- read_csv("outputs/country_means_2015_2025.csv", show_col_types = FALSE) |>
  filter(domain == "READ")

stu15 <- readRDS("data/slim/stu15.rds")
stu25 <- readRDS("data/slim/stu25.rds")

pop <- bind_rows(stu15, stu25) |>
  group_by(CNT, year) |>
  summarise(pop = sum(W_FSTUWT), .groups = "drop") |>
  pivot_wider(names_from = year, values_from = pop, names_prefix = "pop") |>
  mutate(pop_change_pct = 100 * (pop2025 / pop2015 - 1))

minus <- "\u2212"

d <- means |>
  left_join(select(pop, CNT, pop_change_pct), by = "CNT") |>
  mutate(
    flag_pop = abs(pop_change_pct) >= 25,
    lab_txt  = paste0(country, if_else(flag_pop, " \u2020", "")),
    change_txt = if_else(abs(change) < 0.5, "0",
                         str_replace(sprintf("%+.0f", change), "-", minus)),
    dir = case_when(change <= -thr ~ "down",
                    change >=  thr ~ "up",
                    TRUE           ~ "same")
  ) |>
  arrange(if (sort_by == "change") change else -y2015)

n <- nrow(d)
n_down <- sum(d$dir == "down"); n_up <- sum(d$dir == "up"); n_same <- sum(d$dir == "same")
med_change <- median(d$change)
n_flag <- sum(d$flag_pop)

# --- 2. One colour scale for everything (arrows, dots, labels) ---------------
rng <- range(d$change)
stops <- c(rng[1], -thr, -thr + 0.01, thr - 0.01, thr, rng[2])
cols  <- c(col_down_deep, col_down_pale, col_same, col_same, col_up_pale, col_up_deep)
stops_01 <- scales::rescale(stops, from = rng)

pal <- scales::pal_gradient_n(cols, values = stops_01)
d$col <- pal(scales::rescale(d$change, from = rng))

darken <- function(x, f = 0.8) {
  m <- grDevices::col2rgb(x) * f
  grDevices::rgb(m[1, ], m[2, ], m[3, ], maxColorValue = 255)
}
d$lab_col <- darken(d$col)   # slightly darker so pale colours stay readable as text

# --- 3. Size follows the size of the change ----------------------------------
# w runs from 0 (no change) to 1 (change of w_cap points or more)
d <- d |>
  mutate(
    w = pmin(abs(change) / w_cap, 1),
    lw       = 0.7,                    # arrow line width: constant and thin
    dot_start = 1.7 + 1.6 * w,         # 2015 dot
    dot_end   = 0.6 * dot_start,       # small 2025 dot (styles "dots" and "gap")
    # name/number size grows with the change
    txt_size  = txt_min + (txt_max - txt_min) * w,
    txt_face  = if_else(abs(change) >= 40 | dir == "same", "bold", "plain"),   # big changes and "same" cases stand out,
    bucket = pmax(1L, as.integer(ceiling(w * 6))),  # arrowhead size class, 1 (small) to 6 (large)
    h = row_min + (row_max - row_min) * w                           # row height: taller for bigger changes
  ) |>
  mutate(idx = row_number(),
         row = sum(h) - (cumsum(h) - h) - h / 2)    # row centre (first row on top)
H <- sum(d$h)                                       # total data height

head_len <- seq(0.14, 0.42, length.out = 6)   # arrowhead length (cm) for size classes 1..6

# --- 4. Text on the image ----------------------------------------------------
title <- "CHANGE IN READING PERFORMANCE, PISA 2015\u20132025"
subtitle <- paste0("Mean reading score of 15-year-olds in ", n, " countries and economies")
caption <- "\u2020 Population base changed by 25%+   |   Source: OECD PISA 2015, 2025   |   Chart: Ekaterina Enchikova"

# --- 5. Plot ---------------------------------------------------------------
x_min <- 180      # left edge of the panel (room for country names)
x_axis0 <- 300    # where the score axis starts
x_lab <- 296      # right edge of the country names
x_max <- 575      # right edge (change column)
header_h <- 8.5   # height of the header band above the data (in rows)

moved <- filter(d, dir != "same")
same  <- filter(d, dir == "same")

gap_use <- if (arrow_style == "gap") end_gap else 0
make_arrow <- function(len) {
  switch(arrow_style,
    filled = arrow(length = unit(len, "cm"), angle = 22, type = "closed"),
    dots   = NULL,
    arrow(length = unit(len, "cm"), angle = 30, type = "open")   # "open" and "gap"
  )
}

# One arrow layer per size class, so bigger changes get bigger arrowheads
arrow_layers <- lapply(seq_along(head_len), function(b) {
  geom_segment(
    data = filter(moved, bucket == b),
    aes(x = y2015, xend = y2015 + sign(change) * pmax(abs(change) - gap_use, 1),
        y = row, yend = row,
        colour = change, linewidth = I(lw)),
    arrow = make_arrow(head_len[[b]])
  )
})

# Header band positions: number on top, text below; three blocks spread across the panel
y_big <- H + header_h - 1.0    # top of the big numbers
y_sub <- y_big - 3.7           # top of the text under the numbers
hx <- (x_min + x_max) / 2 + c(-125, 0, 125)   # block centres, symmetric around the panel centre
y_r1 <- y_big - 1.4            # legend arrow row (centre of the number row)
y_r2 <- y_sub - 0.6            # legend "same" row (aligned with the text row)
y_div  <- H + 1.6              # divider line between header and data

grid_x <- tibble(x = seq(300, 550, 50))

p <- ggplot(d) +
  # zebra rows (data rows only)
  geom_rect(data = filter(d, idx %% 2 == 0),
            aes(xmin = x_min, xmax = x_max, ymin = row - h / 2, ymax = row + h / 2),
            fill = zebra_col, inherit.aes = FALSE) +
  # vertical grid lines (data rows only)
  geom_segment(data = grid_x, aes(x = x, xend = x, y = 0, yend = H + 0.7),
               colour = grid_col, linewidth = 0.4, inherit.aes = FALSE) +
  arrow_layers +
  geom_point(data = moved, aes(x = y2015, y = row, colour = change, size = I(dot_start))) +
  (if (arrow_style %in% c("dots", "gap"))
    geom_point(data = moved, aes(x = y2025, y = row, colour = change, size = I(dot_end)))) +
  geom_point(data = same, aes(x = y2025, y = row, colour = change), size = 2.4) +
  # country names and change column
  geom_text(aes(x = x_lab, y = row, label = lab_txt, colour = I(lab_col),
                size = I(txt_size), fontface = txt_face),
            hjust = 1, family = fam) +
  geom_text(aes(x = x_max, y = row, label = change_txt,
                size = I(txt_size * 0.95), fontface = txt_face),
            hjust = 1, colour = "grey35", family = fam) +
  # ---- header band: number on top, text below -----------------------------
  annotate("text", x = hx[1], y = y_big, label = as.character(n_down),
           hjust = 0.5, vjust = 1, size = 11, fontface = "bold",
           colour = col_down_deep, family = fam) +
  annotate("text", x = hx[1], y = y_sub, label = "countries decreased",
           hjust = 0.5, vjust = 1, size = 3.3, colour = "grey30", family = fam) +
  annotate("text", x = hx[2], y = y_big,
           label = str_replace(sprintf("%+.0f", med_change), "-", minus),
           hjust = 0.5, vjust = 1, size = 11, fontface = "bold",
           colour = col_key, family = fam) +
  annotate("text", x = hx[2], y = y_sub, label = "points median change",
           hjust = 0.5, vjust = 1, size = 3.3, colour = "grey30", family = fam) +
  # legend: example arrow on the number row, "same" on the text row
  annotate("text", x = hx[3] - 22, y = y_r1, label = "2015", hjust = 1,
           size = 3.3, colour = "grey30", family = fam) +
  annotate("segment", x = hx[3] - 18, xend = hx[3] + 18, y = y_r1, yend = y_r1,
           colour = col_key, linewidth = 0.7, arrow = make_arrow(0.25)) +
  annotate("point", x = hx[3] - 18, y = y_r1, size = 3, colour = col_key) +
  annotate("text", x = hx[3] + 22, y = y_r1, label = "2025", hjust = 0,
           size = 3.3, colour = "grey30", family = fam) +
  annotate("point", x = hx[3] - 26, y = y_r2, size = 2.4, colour = col_same) +
  annotate("text", x = hx[3] - 21, y = y_r2, label = "about the same", hjust = 0,
           size = 3.3, colour = "grey30", family = fam) +
  # divider between header and data
  annotate("segment", x = x_min, xend = x_max, y = y_div, yend = y_div,
           colour = grid_col, linewidth = 0.6) +
  scale_colour_gradientn(colours = cols, values = stops_01, limits = rng,
                         guide = "none") +
  scale_x_continuous(breaks = seq(300, 550, 50)) +
  scale_y_continuous(breaks = NULL) +
  coord_cartesian(xlim = c(x_min, x_max), ylim = c(0, H + header_h), expand = FALSE) +
  labs(title = title, subtitle = subtitle, x = NULL, y = NULL, caption = caption) +
  theme_minimal(base_size = 12, base_family = fam) +
  theme(
    plot.background = element_rect(fill = bg_col, colour = NA),
    panel.background = element_rect(fill = bg_col, colour = NA),
    plot.margin = margin(14, 16, 10, 14),
    plot.title = element_text(face = "bold", size = 16, colour = ink_col),
    plot.subtitle = element_text(size = 10, colour = "grey35",
                                 margin = margin(t = 2, b = 10)),
    plot.caption = element_text(hjust = 0, colour = "grey50", size = 8,
                                margin = margin(t = 10)),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.text.x = element_text(colour = "grey45"),
    panel.grid = element_blank()
  )

# --- 6. Save (only when save_outputs <- TRUE) --------------------------------
if (save_outputs) {
  dir.create(file.path(study_dir, "figures"), recursive = TRUE, showWarnings = FALSE)
  if (font_ok) showtext::showtext_opts(dpi = 300)   # match the export resolution
  ggsave(file.path(study_dir, "figures", "arrows_reading_2015_2025.png"), p, width = 8, height = 16 * H / n,
         dpi = 300, bg = bg_col)
  try(ggsave(file.path(study_dir, "figures", "arrows_reading_2015_2025.svg"), p, width = 8, height = 16 * H / n),
      silent = TRUE)
  if (font_ok) showtext::showtext_opts(dpi = 96)    # back to screen resolution

  notes <- c(
    "# Change in reading performance, PISA 2015-2025: chart notes",
    "",
    "## What the chart shows",
    paste0("Each arrow runs from a country's mean reading score in PISA 2015 (dot) ",
           "to its score in PISA 2025 (arrowhead), for the ", n,
           " countries and economies present in both cycles with the same sample code."),
    paste0("Orange arrows: lower in 2025 by ", thr, "+ points (", n_down,
           " countries); the darker the orange, the bigger the drop. ",
           "Green arrows: higher by ", thr, "+ points (", n_up, "); darker = bigger gain. ",
           "Blue dots: about the same, a difference of under ", thr, " points (", n_same, "). ",
           "Larger changes have larger arrowheads. ",
           "Median change across countries: ",
           str_replace(sprintf("%+.0f", med_change), "-", minus), " points."),
    "",
    "## Caveats",
    paste0("- **Point estimates only.** Colours and sizes reflect the size of the difference ",
           "between point estimates (threshold: ", thr, " points). Statistical significance, ",
           "including link error between cycles, has not been tested."),
    paste0("- **Population base (\u2020).** For ", n_flag, " countries the weighted ",
           "15-year-old population represented by the sample changed by 25% or more between ",
           "cycles. This can reflect demography and/or changes in coverage, so the change in ",
           "mean score should be interpreted with caution."),
    "- **Non-comparable samples are excluded.** For example, China's 2015 sample (B-S-J-G) and 2025 sample (B-S-J-Z) cover different jurisdictions.",
    "- Countries are sorted by their 2015 score (highest at the top).",
    "",
    "## Method",
    "Weighted country means (final student weight W_FSTUWT), computed separately for each of the 10 plausible values and then averaged. 2025 means were checked against the OECD's published PISA 2025 reading table.",
    "",
    "## Source and credit",
    "OECD, PISA 2015 and PISA 2025 student data files. Analysis and chart: Ekaterina Enchikova (ORCID 0000-0002-3919-2447)."
  )
  writeLines(notes, file.path(study_dir, "figures", "arrows_reading_notes.md"))
}

p
