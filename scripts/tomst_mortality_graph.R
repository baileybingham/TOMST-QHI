# Graphing the deaths of the TOMST up till autumn 2026
# October 29th, 2026

# Load libraries
library(tidyverse)
library(lubridate)

# treat 'na' strings as NA
df <- read_csv("data/QHI_TOMST_deployment-history_graphable.csv", na = c("", "NA", "na")) %>%
  filter(!is.na(id))

# define when the graph should go until (i.e. 2026 downlaod date)
lastdownload <- ymd("2026-08-10")

# build segments for active and inactive intervals
segments <- df %>%
  mutate(
    deploy_date   = ymd(deploy_date),
    death_date    = ymd(death_date),
    redeploy_date = ymd(redeploy_date)
  ) %>%
  rowwise() %>%
  do({
    id <- .$id
    dep <- .$deploy_date
    death <- .$death_date
    redep <- .$redeploy_date
    
    rows <- list()
    
    if (is.na(death)) {
      # Active continuously from deployment through August 2026
      rows[[1]] <- data.frame(id = id, start = dep, end = lastdownload, status = "Initial Deployment")
    } else {
      # Active from deployment until death
      rows[[1]] <- data.frame(id = id, start = dep, end = death, status = "Initial Deployment")
      
      # Active from redeployment through August 2026 (if applicable)
      if (!is.na(redep)) {
        rows[[2]] <- data.frame(id = id, start = redep, end = lastdownload, status = "Redeployment")
      }
    }
    
    bind_rows(rows)
  }) %>%
  ungroup()

# Extract deaths
deaths <- df %>%
  mutate(death_date = ymd(death_date)) %>%
  filter(!is.na(death_date))

# Reorder TOMST IDs numerically (TOMST_01 to TOMST_40) on the Y-axis
segments <- segments %>%
  mutate(id = factor(id, levels = rev(paste0("TOMST_", sprintf("%02d", 1:40)))))

# Plot

ggplot() +
  geom_segment(
    data = segments,
    aes(y = id, x = start, xend = end, yend = id, color = status),
    linewidth = 2.5
  ) +
  geom_point(
    data = deaths,
    aes(y = id, x = death_date),
    shape = 4,
    color = "red",
    size = 3,
    stroke = 1.5
  ) +
  scale_color_manual(
    values = c(
      "Initial Deployment" = "#0288D1",  
      "Redeployment"       = "#0320D1"   
    )
  ) +
  scale_x_date(
    date_breaks = "1 year",
    date_labels = "%b %Y",
    limits = c(ymd("2022-07-15"), lastdownload)
  ) +
  labs(
    title = "TOMST Deployment History",
    x = "Date",
    y = "TOMST ID",
    color = "Status"
  ) +
  theme_bw() +
  theme(
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )


