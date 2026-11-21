###############################################################################
##################                                             ###################
##################             Basic Figures for the           ###################
##################  TOMST from Qikiqtaruk - Herschel Island    ###################
##################                                             ###################
##################          Created November 2026              ###################
##################             by Bailey Bingham               ###################
##################                                             ###################
###############################################################################


# Install Packages
library(lubridate) ## manipulate date_time
library(tidyverse) #includes ggplot, tidyr, dplyr, stringr etc. 
library(data.table) ## Efficient data.frame

# Set Up
theme_set(theme_minimal(base_size = 12))

tms.t3 <- read_csv("export_data/2026_TOMSTdata_T3_preprocessed_daily.csv")%>%
  mutate(
    date   = as_date(datetime),
    # Common-year date so all years overlay on one axis labelled by month.
    # use 2000, because it is a leap year
    md = as_date(format(date, "2000-%m-%d"))
  )
head (tms.t3)

############# Create a heat map of temps across deployment history #############
tms.t3 %>%
  ggplot(aes(date, locality_id, fill = value)) +
  geom_tile(height = 0.9) +
  scale_x_date(
    breaks = seq(as.Date("2022-08-01"), as.Date("2026-08-01"), by = "6 months"),
    date_labels = "%b %Y"  ) +
  scale_y_discrete(limits = rev) +
  scale_fill_viridis_c(option = "inferno", na.value = "transparent") +
  labs(title = "Near ground (15 cm) temp for all TOMST, full record",
       x = NULL, y = NULL, fill = "°C") +
  theme(axis.text.y = element_text(size = 5),
        axis.text.x = element_text(angle = 45, hjust = 1))

############### Graph sensor mortality ########################################
# find sensors where the record ended before the most recent download date. 
death_cutoff <- as.Date("2026-08-01")

present <- tms.t3 %>%
  filter(!is.na(value))

# Find the end of every continuous run of data; runs ending before the cutoff = death
deaths <- present %>%
  arrange(locality_id, date) %>%
  group_by(locality_id) %>%
  mutate(new_run = is.na(lag(date)) | as.numeric(date - lag(date)) > 7,
         run     = cumsum(new_run)) %>%
  group_by(locality_id, run) %>%
  summarise(death_date = max(date), .groups = "drop") %>%
  filter(death_date < death_cutoff)

ggplot() +
  geom_tile(data = present, aes(date, locality_id), fill = "steelblue", height = 0.5) +
  geom_point(data = deaths, aes(death_date, locality_id),
             shape = 4, colour = "red", size = 4, stroke = 2) +
  scale_x_date(
    breaks = seq(as.Date("2022-08-01"), as.Date("2026-08-01"), by = "year"),
    date_labels = "%b %Y"  ) +
  scale_y_discrete(limits = rev) +
  labs(title = "TOMST deployment history",
       subtitle = "Blue = data present, red X = sensor died",
       x = NULL, y = NULL) +
  theme(axis.text.y = element_text(size = 8))
