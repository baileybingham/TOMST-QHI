#######################################################
########## Comparing TOMST to ECCC Data ##############
##########    By Bailey Bingham            ############
######################################################

library(tidyverse) #includes ggplot, tidyr, dplyr, etc. 
library(lubridate)
library(zoo)

### IMPORT AGGREGATED DAILY TOMST DATA ###
eccc <- read_csv("~/1. PhD Research/GitHub/Growth-chambers/1. Exploring QHI temp data/data/ECCC temp data/combined_ECCC_dailymeantemp_1996-2025.csv") %>%
  drop_na()%>%
  # Read datetime as a date
  mutate(dummydate = ymd(dummydate)) %>% 
  # change column headers
  select(dummydate,Mean_Temp, Max_Temp, Min_Temp)  %>%
  rename(
    eccc_mean_temp = Mean_Temp,
    eccc_max_temp = Max_Temp,
    eccc_min_temp = Min_Temp
  )

tomst<-read_csv("export_data/2026_TOMSTdata_T3_preprocessed_daily.csv") %>%
  filter(locality_id %in% sprintf("TOMST_%02d", 1:40)) %>% #filter to just the 40 TOMST
  # Read datetime as a date
  mutate(datetime = ymd(datetime))%>%
    # remove TMS for the sensors that include it
  mutate(sensor = str_remove(sensor_name, "^TMS_"), .keep = "unused") %>%
  # remove all sensors other than the air temperature data (T3)
  filter(sensor %in% c("T3_mean_trimmed", "T3_min", "T3_max")) %>%
  #Rearrange the headings 
  select(locality_id, sensor, datetime, 
         year, month, week, day, doy, value)  %>%
  #pivot to wide format
  pivot_wider(
    # define id columns
    id_cols = c(locality_id, datetime, year,
                month, week, day, doy,), 
    # use values in 'sensor' for new headers
    names_from = sensor, 
    # fill measurement columns with values from the 'value' column
    values_from = value)

### Graph all TOMSTS onto one graph, to get an idea of the range
ggplot(tomst, aes(x = datetime, y = T3_mean_trimmed, color = locality_id)) +
  geom_line(alpha = 0.5) + 
  theme_minimal() +
  facet_wrap(~locality_id)+
  labs(title = "Time Series by Sensor ID",
       x = "Date",
       y = "Mean Temperature (T3)") 

### TOMST_21 and _22 look kinda weird, but they are right near each other on 
### the island so the data is probably accurate.

### Average all stations to get one daily average for the whole island ###
tomst_daily_avg <- tomst %>%
  mutate(  # add year column and calculate day of year (doy)
  year  = year(datetime),
  month = month(datetime),
  day   = day(datetime),
  doy   = yday(datetime)) %>%
  group_by(year, doy, datetime) %>%
  summarise(
    # Average of the mean temperatures across all stations
    QHI_mean = mean(T3_mean_trimmed, na.rm = TRUE),
    # The absolute lowest temperature recorded by ANY station that week
    QHI_min  = median (T3_min, na.rm = TRUE),
    # The absolute highest temperature recorded by ANY station that week
    QHI_max  = median (T3_max, na.rm = TRUE))

### Graph the average to see if it makes sense
ggplot(tomst_daily_avg, aes(x = doy, y = QHI_mean)) +
  geom_line(alpha = 0.5) + 
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), alpha = 0.2, fill = "grey") +
  #facet_grid(year~.)+
  scale_x_date(
    date_breaks = "1 month",   # Set marks at every month
    date_labels = "%b"      # Format: %b = Abbr Month, %y = year (e.g., Jan 22)
  ) +
  theme_minimal() +
  labs(title = "QHI average temperature",
       subtitle = "Grey shaded area shows the extreme temperatures for each day",
       x = "Date",
       y = "Mean Daily Air Temperature") 
### Calculate rolling average
rollavg <-tomst_daily_avg %>%
  mutate(
    # Rolling Average: Smoothes data, but lowers peaks
    rolling_avg = rollmean(QHI_mean, k = 7, fill = NA, align = "center"),
    # Rolling Max: Preserves the heatwave intensity for the week
    rolling_max = rollmax(QHI_max, k = 7, fill = NA, align = "center"),
    # Rolling Min: Captures the coolest dip of the week
    rolling_min = rollapply(QHI_min, width = 7, FUN = min, fill = NA, align = "center"))


#### Combine TOMST with ECCC to compare 2023 to the 30 year average
cdata<-cbind(eccc, rollavg)

# graph it
ggplot(cdata, aes(x = dummydate)) +
  geom_hline(yintercept = 0, color = "red", linewidth = 0.5, linetype = "dashed") +
  #ECCC Ribbon (Grey Background)
  geom_ribbon(aes(ymin = eccc_min_temp, ymax = eccc_max_temp),fill = "grey", alpha = 0.3) +
  #ECCC Mean Line
  geom_line(aes(y = eccc_mean_temp), color = "grey20", size = 0.8) +
  #QHI Ribbon 
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), fill = "darkred", alpha = 0.3) +
  #QHI Mean Line
  geom_line(aes(y = QHI_mean), color = "darkred", size = 1) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 month") +
  labs(
      # title = "QHI ECCC weather station historical temps compared to 2023 TOMST average, max and min temps",
      # subtitle = "Grey: ECCC (30-yr) | Red: QHI TOMST (2023)",
       x = "Date",
       y = "Temperature (°C)")



# what about with rolling 2023 averages?
ggplot(cdata, aes(x = dummydate)) +
  geom_hline(yintercept = 0, color = "grey", linewidth = 0.5, linetype = "dashed") +
  #ECCC Ribbon (Grey Background)
  geom_ribbon(aes(ymin = eccc_min_temp, ymax = eccc_max_temp),fill = "grey", alpha = 0.3) +
  #ECCC Mean Line
  geom_line(aes(y = eccc_mean_temp), color = "grey20", size = 0.8) +
  #QHI actual extremes Ribbon 
  geom_ribbon(aes(ymin = QHI_min, ymax = QHI_max), fill = "#CA2100", alpha = 0.3) +
  #QHI Mean rolling average Line
  geom_line(aes(y = rolling_avg), color = "#CA2100", size = 1) +
  scale_x_date(date_labels = "%b %d", date_breaks = "1 month") +
  labs(
      # title = "QHI ECCC weather station historical temps compared to 2023 TOMST rolling average and max and min temps",
      # subtitle = "Grey: ECCC (30-yr) | Red: rolling average and actual max and mins of the TOMST (2023)",
       x = "Date (2023)",
       y = "Temperature (°C)")  

## if making graphs for presentations
  coord_cartesian(xlim = c(as.Date("2023-04-15"), as.Date("2023-10-15"))) +
  theme_minimal(base_size = 16) +
  theme(legend.position = "none")

### Should consider comparing the TOMST 2023 data to the ECCC 2023 data if it exists?

