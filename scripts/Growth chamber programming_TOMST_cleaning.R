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

############## Upload Pre-processed DAILY TOMST data ##########################
getwd() # check working directory
pproc<- read.csv("data/2025_TOMSTdata_preprocessed_daily.csv")

############# Clean data and switch to wide ###################################
clean <- pproc %>%
  #seperate QHI as the location, and the TOMST ID out into seperate columns
  separate_wider_regex(
             locality_id,
             patterns = c(
             id = ".*",      # Greedily matches everything until...
                   "_",      # ...the last underscore (discarded)
             location = ".*" # Everything after that last underscore
    ))
  #remove TMS_ from sensor_name
  mutate(sensor_name = str_remove(sensor_name, "TMS_"))%>%
  
  # seperate sensor and measurement
  separate_wider_delim(cols = sensor_name, 
                       delim = "_", 
                       names = c("sensor", "measurement"))%>%
  
  ##seperate out the sensor and the measurement, create description and unite with measurement immediately
  mutate(descrip = case_match(sensor, 
                              "T1" ~ "soil_temp", "T2" ~ "nearsoil_temp", 
                              "T3" ~ "air_temp", "moist" ~ "soil_moisture"),
         measurement = paste(descrip, measurement, sep = "_"))%>%
  
  # add year column and calculate day of year (doy)
  mutate(datetime = as.POSIXct(datetime)) %>%
  mutate(
    year  = year(datetime),
    month = month(datetime),
    day   = day(datetime),
    doy   = yday(datetime)) %>%
  
  #Rearrange the headings to your exact specification
  select(location, id, sensor, datetime, 
         year, month, day, doy, measurement, value)