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
pproc<- read.csv("data/2025_TOMSTdata_preprocessed_daily.csv")
unique(pproc$sensor_name)

metadata<-read.csv("data/TOMST_metadata.csv")%>%
  rename_with(tolower) # make the column headers lowercase

############# Seperate columns and clean data #################################
clean <- pproc %>%
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

  #Rearrange the headings to your exact specification
  select(location, id, sensor, datetime, 
         year, month, week, day, doy, value)

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

################## keep only T3 mean (i.e. air_temp mean) #####################
t3_mean <- clean_meta %>%
  filter(sensor == "T3_mean")

################## Graph data with all years represented (not averaged) ##########
t3_mean <- t3_mean %>%
  mutate(datetime = ymd(datetime))

ggplot(t3_mean, aes(x = datetime, y = value, color=id)) +
  geom_point(alpha = 0.5) +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  #geom_smooth(method = "loess", color = "blue") +
  scale_x_date(
    date_breaks = "1 month",   # Set marks at every month
    date_labels = "%b %d"      # Format: %b = Abbr Month, %d = Day (e.g., Jan 01)
  ) +
  labs(
    title = "Average daily air temp by TOMST 2022-2025",
    x = "Month",
    y = "Mean Value (°C)"
  ) +
  theme_minimal()

#Normalize the dates to a single dummy year
t3_norm <- t3_mean %>%
  mutate(
    # Force all dates to 2024 (a leap year) to overlay them
    dummy_date = as.Date(paste(2024, month(datetime), day(datetime), sep = "-"))
  )

# plot all years together
ggplot(t3_norm, aes(x = dummy_date, y = value)) +
  # Individual years colored differently (using original year)
  geom_point(aes(color =  factor(year)), alpha = 0.2) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  # add an average line across all years and TOMST
  geom_smooth(method = "loess", color = "black", linewidth = 1.2, se = FALSE) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b %d" 
  ) +
  labs(
    title = "Annual Temperature Overlay (2022-2025)",
    subtitle = "Black line shows the multi-year average trend",
    x = "Month",
    y = "Temperature (°C)",
    color = "Year"
  ) +
  theme_minimal()

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


####################### convert to wide form ##################################
#rearrange so measurement is spread and values are underneath
wide_clean_meta <- clean_meta %>% 
  pivot_wider(
    # define id columns
    id_cols = c(location, serial_no, id, lat, lon, elevation, 
                nearest.phenocam, datetime, year,
                month, day, doy,), 
    # use values in 'sensor' for new headers
    names_from = sensor, 
    # fill measurement columns with values from the 'value' column
    values_from = value
  ) 

