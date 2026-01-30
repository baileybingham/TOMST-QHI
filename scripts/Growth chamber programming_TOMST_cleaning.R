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
pproc<- read.csv("data/2025_TOMSTdata_preprocessed_daily.csv") %>%
  mutate(datetime = ymd(datetime))
unique(pproc$sensor_name)

############# Separate columns, clean data, and pivot to wide  ################
T3_clean <- pproc %>%
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

############################## INITIAL GRAPHS #########################################
#### Graph of August 2022- August 2025 time series for T_mean ####
ggplot(T3_clean, aes(x = datetime, y = T3_mean, color=id)) +
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

#### Graph showing all TOMST data as a single year of temperatures ####
#Normalize the dates to a single dummy year
t3_graph <- T3_clean %>%
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

ggplot(chamber_plan, aes(x = week, y = target_temp)) +
  geom_line(color = "darkred", size = 1) +
  geom_ribbon(aes(ymin = min_temp, ymax = max_temp), alpha = 0.2, fill = "red") +
  labs(title = "Proposed Growth Chamber Weekly Temp Cycle",
       subtitle = "Shaded area represents historical extremes (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()

# something weird is going on with the Mins and Maxes... Why are they so different from the means?
################## Chamber Programming (By week) ##############################
# 1. Filter for Growing Season (May 15 to Oct 15)
# Using 'doy' (Day of Year) is often cleaner: May 15 is ~135, Oct 15 is ~288
df_growing <- T3_clean %>%
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
 # geom_line(aes(y = avg_daytime_high, color = "Daytime High (Max)"), size = 1) +
#  geom_line(aes(y = avg_nighttime_low, color = "Nighttime Low (Min)"), size = 1) +
  geom_ribbon(aes(ymin = avg_nighttime_low, ymax = avg_daytime_high), alpha = 0.1) +
  scale_color_manual(values = c("Daytime High (Max)" = "firebrick", 
                                "Nighttime Low (Min)" = "darkblue")) +
  labs(title = "Growth Chamber Programming Schedule: Weekly Diurnal Cycle",
       subtitle = "Averaged across 40 sensors (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)", color = "Setpoint") +
  theme_minimal()


























# 1. Clean Data: Ensure datetime is a date object
df_clean <- T3_clean %>%
  mutate(datetime = as.Date(datetime)) %>%
  drop_na(T3_mean)  # Remove NAs for accurate averages

# 2. Filter for Growing Season (May 15 to Oct 15)
df_growing <- df_clean %>%
  filter((month == 5 & day >= 15) | 
           (month > 5 & month < 10) | 
           (month == 10 & day <= 15))

# 3. Create Weekly Chamber Profile
# We group by 'week' (1-52) across ALL years to get a representative average
chamber_plan <- df_growing %>%
  group_by(week) %>%
  summarise(
    target_temp = mean(T3_mean),
    min_temp = T3_min,
    max_temp = T3_max,
    #sd_temp = sd(T3_mean) # Standard deviation shows year-to-year variability
  ) %>%
  arrange(week)

# 4. Visualization for Validation
ggplot(chamber_plan, aes(x = week, y = target_temp)) +
  geom_line(color = "darkred", size = 1) +
  geom_ribbon(aes(ymin = min_temp, ymax = max_temp), alpha = 0.2, fill = "red") +
  labs(title = "Proposed Growth Chamber Weekly Temp Cycle",
       subtitle = "Shaded area represents historical extremes (2022-2025)",
       x = "Week of Year", y = "Temperature (°C)") +
  theme_minimal()


################## INITIAL GRAPHS #############################################
################## Graph data with all years represented (not averaged) #######

#### This graph is showing a pretty good average temp trend over 3 years (from Aug01 2022 - Aug08 2025)

#################### Average all years of T3 data by DAY ##################################
# Creates a daily average for each sensor over all years
daily_values <- t3_mean %>%
  group_by(location, month, day, doy, sensor) %>%
  summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop")

#################### Average all years of T3 by WEEK ##################################
# Creates a weekly average for each sensor over all years
weekly_values <- t3_mean %>%
  group_by(location, id, month, week, sensor) %>%
  summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop")

## The weeks are currently falling across multiple months (i.e more than one line per week)
## Let's make it so the month registers as whatever month the first day of the week falls in
weekly_values <- grow_seas %>%
  mutate(datetime = ymd(datetime)) %>% 
  #Create a "start_month" which is the month that the week started in (according to Julian date)
  mutate(start_month = month(as.Date(paste0(year, "-01-01")) + (week - 1) * 7)) %>%
    #Group by the new 'start_month' and other metadata columns
  group_by(location, start_month, week, sensor) %>% # add id if you want to sort by TOMST too
  #Summarize as before, the 'month' column is no longer needed in group_by
  summarize(mean_value = mean(value, na.rm = TRUE), .groups = "drop")


###################### Graph Daily Averages ###################################
daily_values_cropped <- daily_values %>%
  mutate(
    # Create a Date object; ggplot needs this for scale_x_date to work
    date = as.Date(paste(2024, month, day, sep = "-")))  %>%
    # filter to just the growing season
    filter(between(date, as.Date("2024-05-15"), as.Date("2024-10-15")))
  

ggplot(daily_values_cropped, aes(x = date, y = mean_value)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
    geom_smooth(method = "loess", color = "blue") +
    scale_x_date(
      date_breaks = "1 month",   # Set marks at every month
      date_labels = "%b %d"      # Format: %b = Abbr Month, %d = Day (e.g., Jan 01)
    ) +
    labs(
      title = "Average daily air temp 2022-2025",
      x = "Month",
      y = "Mean Value (°C)"
    ) +
    theme_minimal()



###################### Graph weekly averages ##################################












################### Working Notes ##############################################

################## Filter May to October ######################################
grow_seas<- t3_mean %>%
  filter(month >= 5 & month <= 10)




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
