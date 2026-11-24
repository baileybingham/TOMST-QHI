#############################################################
#### TOMST Data cleaning for growth chamber programming #####
#### Created by Bailey Bingham ##############################
#### January 28th, 2026 #####################################
#############################################################

#### This script is used to clean the already pre-processed TOMST data 
#### to determine the weekly temperature averages for the 2026 Growth
#### Chamber experiment. 

####################### Download packages  ####################################
library(tidyverse) #includes ggplot, tidyr, dplyr, etc. 
library(lubridate)

############## Upload Pre-processed DAILY TOMST data ##########################
getwd() # check working directory
pproc.daily<- read.csv("export_data/2025_TOMSTdata_preprocessed_daily.csv") %>%
  mutate(datetime = ymd(datetime))
unique(pproc.daily$sensor_name)

pproc.weekly<- read.csv("export_data/2025_TOMSTdata_preprocessed_weekly.csv") %>%
  mutate(datetime = ymd(datetime))
unique(pproc.weekly$sensor_name)

######## DAILY: Separate columns, clean data, and pivot to wide  ################
T3daily <- pproc.daily %>%
  #seperate QHI as the location, and the TOMST ID out into seperate columns
  separate_wider_regex( #using regex so that we can account for there being two underscores in locality_id
             locality_id,
             patterns = c(
             id = ".*",      # Greedily matches everything until...
                   "_",      # ...the last underscore (discarded)
             location = ".*") # Everything after that last underscore
               ) %>%
  # remove TMS for the sensors that include it
  mutate(sensor = str_remove(sensor_name, "^TMS_"), .keep = "unused") %>%
  
  # remove all sensors other than the air temperature data (T3)
  filter(sensor %in% c("T3_mean", "T3_min", "T3_max")) %>%

  #Rearrange the headings 
  select(location, id, sensor, datetime, 
         year, month, week, day, doy, value) %>%
  
  #pivot to wide format
  pivot_wider(
    # define id columns
    id_cols = c(location, id, datetime, year,
                month, week, day, doy,), 
    # use values in 'sensor' for new headers
    names_from = sensor, 
    # fill measurement columns with values from the 'value' column
    values_from = value)
#### DAILY: INITIAL GRAPHS #########################################
# Graph of August 2022- August 2025 time series for T_mean #
ggplot(T3daily, aes(x = datetime, y = T3_mean, color=id)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  geom_smooth(method = "loess", span = 0.25, color = "black", linewidth = 1.2, se = FALSE) +
  scale_x_date(
    date_breaks = "2 month",   # Set marks at every month
    date_labels = "%b %y"      # Format: %b = Abbr Month, %y = year (e.g., Jan 22)
  ) +
  labs(
    title = "Average daily air temp by TOMST August 2022- August 2025",
    x = "Month and Year",
    y = "Mean Value (°C)"
  ) +
  theme_minimal()

# Graph showing all TOMST data as a single year of temperatures #
#Normalize the dates to a single dummy year
t3_graph <- T3daily %>%
  mutate(
    # Make a dummy year in order to overlay dates. 
    dummy_date = as.Date(paste(2024, month(datetime), day(datetime), sep = "-"))
  ) %>%
  # Triple years of data to place dummy years on either end, so that 
  # R knows that December and January are next to each other when making
  # average line.
  mutate(dummy_date = as.Date(paste(2024, month(datetime), day(datetime), sep = "-"))) %>%
  bind_rows(
    mutate(., dummy_date = dummy_date - years(1)), # Add year before
    mutate(., dummy_date = dummy_date + years(1))  # Add year after
  )

# Plot, but restrict the X-axis to only certain dates (either main year or just the growing season)
ggplot(t3_graph, aes(x = dummy_date, y = T3_mean)) +
  geom_point(aes(color = factor(year)), alpha = 0.1) + # Real points
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  # The smoother now sees Dec 31 -> Jan 1 as a continuous sequence
  geom_smooth(method = "loess", span = 0.25, color = "black", linewidth = 1.2, se = FALSE) +
  # CROP the view back to a single year loop
  coord_cartesian(
    xlim = as.Date(c("2024-01-01", "2024-12-31")), # if you want to crop it to the year. 
    #xlim = as.Date(c("2024-05-15", "2024-10-15")), # if you want to crop to just the growing season. 
    expand = FALSE) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b %d" 
  ) +
  labs(
    title = "QHI Annual Temperature Overlay (Aug 2022- Aug 2025)",
    subtitle = "Black line shows the multi-year average trend. Each point represents average daily air temp (T3) at one TOMST station.",
    x = "Month",
    y = "Temperature (°C)",
    color = "Year"
  ) +
  theme_minimal()

######## DAILY QHI WIDE ########################################################
QHI_dtay <- T3daily %>%
  group_by(doy) %>%
  summarise(
    # Average of the mean temperatures across all stations
    QHI_mean = mean(T3_mean, na.rm = TRUE),
    # The absolute lowest temperature recorded by ANY station that week
    QHI_min  = min(T3_min, na.rm = TRUE),
    # The absolute highest temperature recorded by ANY station that week
    QHI_max  = max(T3_max, na.rm = TRUE),
    # Recommended: count how many stations contributed to this average
    n_stations    = sum(!is.na(T3_mean)),
    .groups = "drop")%>%
  # remove first and last weeks that don't have a calculated mean
    filter(is.finite(QHI_mean))

##Graph
ggplot(QHI_dtay, aes(x = doy, y = QHI_mean)) +
  geom_line(color = "darkred", size = 1) +
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), alpha = 0.2, fill = "grey") +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  labs(title = "QHI mean daily temp by doy",
       subtitle = "Shaded area represents the min and max temperatures by day (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()


QHI_dt <- T3daily %>%
  group_by(datetime) %>%
  summarise(
    # Average of the mean temperatures across all stations
    QHI_mean = mean(T3_mean, na.rm = TRUE),
    # The absolute lowest temperature recorded by ANY station that week
    QHI_min  = min(T3_min, na.rm = TRUE),
    # The absolute highest temperature recorded by ANY station that week
    QHI_max  = max(T3_max, na.rm = TRUE),
    # Recommended: count how many stations contributed to this average
    n_stations    = sum(!is.na(T3_mean)),
    .groups = "drop")%>%
  # remove first and last weeks that don't have a calculated mean
  filter(is.finite(QHI_mean))

##Graph
ggplot(QHI_dt, aes(x = datetime, y = QHI_mean)) +
  geom_line(color = "darkred", size = 1) +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), alpha = 0.2, fill = "grey") +
  labs(title = "QHI mean daily temp by doy",
       subtitle = "Shaded area represents the min and max temperatures by day (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()

######## WEEKLY: Separate columns, clean data, and pivot to wide  ################
T3weekly <- pproc.weekly %>%
  #seperate QHI as the location, and the TOMST ID out into seperate columns
  separate_wider_regex( #using regex so that we can account for there being two underscores in locality_id
    locality_id,
    patterns = c(
      id = ".*",      # Greedily matches everything until...
      "_",      # ...the last underscore (discarded)
      location = ".*") # Everything after that last underscore
  ) %>%
  # remove TMS for the sensors that include it
  mutate(sensor = str_remove(sensor_name, "^TMS_"), .keep = "unused") %>%
  
  # remove all sensors other than the air temperature data (T3)
  filter(sensor %in% c("T3_mean_mean", "T3_min_min", "T3_max_max")) %>%
  
  #Rearrange the headings 
  select(location, id, sensor, datetime, 
         year, month, week, value) %>%
  
  #pivot to wide format
  pivot_wider(
    # define id columns
    id_cols = c(location, id, datetime, year,
                month, week), 
    # use values in 'sensor' for new headers
    names_from = sensor, 
    # fill measurement columns with values from the 'value' column
    values_from = value)

######## ALL TOMST (i.e. QHI) WEEKLY: Average all TOMSTS across the island by week #######
#QHI_wtal = QHI_weekly_temp_all_years
QHI_wtay <- T3weekly %>%
  group_by(week) %>%
  summarise(
    # Average of the mean temperatures across all stations
    QHI_mean = mean(T3_mean_mean, na.rm = TRUE),
    # The absolute lowest temperature recorded by ANY station that week
    QHI_min  = min(T3_min_min, na.rm = TRUE),
    # The absolute highest temperature recorded by ANY station that week
    QHI_max  = max(T3_max_max, na.rm = TRUE),
    # Recommended: count how many stations contributed to this average
    n_stations    = sum(!is.na(T3_mean_mean)),
    .groups = "drop")%>%
  # remove first and last weeks that don't have a calculated mean
    filter(is.finite(QHI_mean))

#### REGIONAL WEEKLY GRAPH ###################################################
ggplot(QHI_wtay, aes(x = week, y = QHI_mean)) +
  geom_line(color = "darkred", size = 1) +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), alpha = 0.2, fill = "grey") +
  labs(title = "Mean weekly temperature averaged across years on QHI",
       subtitle = "Shaded area represents weekly max and min temperatures (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()

#QHI_wtal = QHI_weekly_temp_all_years
QHI_wt <- T3weekly %>%
  group_by(year,month,week) %>%
  summarise(
    # Create an anchor date for the X-axis (the start of that week)
    week_date = min(datetime, na.rm = TRUE),
    # Average of the mean temperatures across all stations
    QHI_mean = mean(T3_mean_mean, na.rm = TRUE),
    # The absolute lowest temperature recorded by ANY station that week
    QHI_min  = min(T3_min_min, na.rm = TRUE),
    # The absolute highest temperature recorded by ANY station that week
    QHI_max  = max(T3_max_max, na.rm = TRUE),
    # Recommended: count how many stations contributed to this average
    n_stations    = sum(!is.na(T3_mean_mean)),
    .groups = "drop")%>%
  # remove first and last weeks that don't have a calculated mean
  filter(is.finite(QHI_mean))

#### REGIONAL WEEKLY GRAPH ###################################################
ggplot(QHI_wt, aes(x = week_date, y = QHI_mean)) +
  geom_line(color = "darkred", size = 1) +
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), alpha = 0.2, fill = "red") +
  labs(title = "Mean weekly temperature across QHI (2022-2025)",
       subtitle = "Shaded area represents max and min temperatures",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()

#################### 


################## Chamber Programming (By week) ##############################
# 1. Filter for Growing Season (May 15 to Oct 15)
# Using 'doy' (Day of Year) is often cleaner: May 15 is ~135, Oct 15 is ~288
df_growing <- T3daily %>%
  filter(doy >= 135 & doy <= 288) %>%
  drop_na(T3_mean)

# 2. Create the Weekly Programming Guide
# We average the daily mins and maxes to get a "Typical" diurnal range
weekly_guide <- df_growing %>%
  group_by(week) %>%
  summarise(
    avg_daytime_high = mean(T3_max, na.rm = TRUE),
    avg_nighttime_low = mean(T3_min, na.rm = TRUE),
    weekly_mean = mean(T3_mean, na.rm = TRUE),
    n_observations = n()
  ) %>%
  arrange(week)

# 3. Visualization: The "Envelope" of your Growing Season
ggplot(weekly_guide, aes(x = week)) +
  geom_line(aes(y = weekly_mean, color = "Weekly Mean"), size = 2) +
  geom_line(aes(y = avg_daytime_high, color = "Daytime High (Max)"), size = 1) +
  geom_line(aes(y = avg_nighttime_low, color = "Nighttime Low (Min)"), size = 1) +
  geom_ribbon(aes(ymin = avg_nighttime_low, ymax = avg_daytime_high), alpha = 0.1) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  scale_color_manual(values = c("Daytime High (Max)" = "firebrick", 
                                "Nighttime Low (Min)" = "darkblue")) +
  labs(title = "Growth Chamber Programming Schedule: Weekly Diurnal Cycle",
       subtitle = "Averaged across 40 sensors (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)", color = "Setpoint") +
  theme_minimal()


























############################ Join with metadata ###############################

# join tomst and metadata where 'id' in tomst matches 'field id' in the metdata set
clean_meta <- clean %>%
  left_join(metadata %>% select(-location),
            by = c("id" = "field_id")) %>%
  
  # reorganize columns
  select(location, serial_no, id, lat, lon, elevation,
         nearest.phenocam, datetime, year, 
         month, week, day, doy, 
         sensor, value) 
