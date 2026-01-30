###################################################
#### Pre-processing of TOMST data with MyClim #####
#### Created by Jeremy Borderieux #################
#### Edited and annotated by Bailey Bingham #######
#### January 20th, 2026 ###########################
###################################################

#### This script is intended to be used with the most recent year data
#### available on GitHub, here: https://github.com/baileybingham/TOMST-QHI
#### Detailed annotations have been provided so that you can understand how 
#### this data is pre-processed. 

### This site was referenced when annotating and may be a helpful read to 
### understand myClim: https://cran.r-project.org/web/packages/myClim/vignettes/myclim-demo.html

####################### Download packages  ####################################
library(myClim) ## logger data reading
library (data.table)
library(foreach) ## efficient loop
library(lubridate) ## manipulate date_time
library(tidyverse) #includes ggplot, tidyr, dplyr, stringr etc. 
library(data.table) ## Efficient data.frame
###################### Begin data upload ######################################
###############################################################################
############## Upload TOMST data from most recent year ########################

# Scans the folder data/2025/ and creates a character vector of every file inside. 
# Since full.names = T, it returns the full name including the relative path. 
# Change the year to the most recent data year only after ensureing that files have
# been uploaded with the correct file naming conventions. 
list_path <- list.files("data/2025/",full.names = T) 

# Scan the same folder but use full.names = F, so it only returns only the 
# filenames without the directory path (e.g., "TOMST_01_QHI.csv"). 
# This makes string manipulation easier in the next step.
list_files <- list.files("data/2025/",full.names = F) 

# Use the stringr package to extract data from the file name. 
# In this case, we are extracting the "locality" name from each filename, 
# meaning the digit of the TOMST and the _QHI identifier.You could also use it 
# to extract the serial number by changing the Regex Pattern to specify the 
# serial number part of the file name. This allows us to use metadata from the file 
# names as a grouping variable in future analysis.
locality_name <-  str_extract(list_files, "TOMST_[:digit:]+_QHI") 
serial_numbers <- str_extract(list_files, "(?<=data_)\\d{8}")

# Assign the extracted TOMST IDs (e.g., TOMST_01_QHI) to their respective paths.
files_table <- data.table(path = list_path,
                          locality_id = locality_name,  
                          serial_number = serial_numbers,
                          data_format = "TOMST") # this adds a column specifying that this is TOMST data
                                                 # (in case you merge it with HOBO data later)

################################################################################
###### Check which TOMSTS are missing from the year folder you selected ########

# Create a vector of all expected IDs from TOMST_01 to TOMST_40
# sprintf ensures the leading zero (01, 02, etc.) matches the file naming convention
expected_ids <- sprintf("TOMST_%02d_QHI", 1:40)

# Identify which expected IDs are NOT present in your files_table
missing_tomst <- setdiff(expected_ids, files_table$locality_id)

# Print the results to the console
if(length(missing_tomst) > 0) {
  message("The following ", length(missing_tomst), " TOMST files are missing:")
  print(missing_tomst)
} else {
  message("All TOMST files (01-40) are present.")
}
# You can check the TOMST graveyard on GitHub to see what happened to these TOMSTS 
# and if we have any of them in previous year folders. Or just run the next bit 
# to check another year's folder. 

################################################################################
############### Upload missing files from an older year folder #################

if(length(missing_tomst) > 0) {
  message("--- Checking 2024 folder for missing files ---")
  # Scan the 2024 folder for potential backup files
  # Change 2024 to reflect the folder year you want
  path_2024 <- "data/2024/"  
  list_path_24 <- list.files("data/2024/", full.names = TRUE)
  list_files_24 <- list.files("data/2024/", full.names = FALSE)
  
  # This extracts the IDs just like we did for 2025 and creates a reference table
  locality_name_24 <- str_extract(list_files_24, "TOMST_[:digit:]+_QHI")
  
  files_table_2024 <- data.table(path = list_path_24,
                                 locality_id = locality_name_24,
                                 data_format = "TOMST")
  
  # Identify which missing IDs are available in 2024
  found_in_2024 <- intersect(missing_tomst, files_table_2024$locality_id)
  still_missing <- setdiff(missing_tomst, found_in_2024)

  # Report Available/Missing
  if(length(found_in_2024) > 0) {
    message("The following TOMST IDs are available in 2024.")
    print(found_in_2024)
  }
  if(length(still_missing) > 0) {
    message("The following TOMST IDs remain missing:")
    print(still_missing)
  }
}

###### If you want to bind the missing files found in the 2024 script,
###### you can use this script. ONLY DO THIS ONCE or you will add duplicates: 
files_table_2024[, serial_number := stringr::str_extract(basename(path), "(?<=data_)\\d{8}")]
if(length(found_in_2024) > 0) {
  recovered_files <- files_table_2024[locality_id %in% found_in_2024]
  files_table <- rbind(files_table, recovered_files)
  files_table <- files_table[order(locality_id)]
  locality_name <- files_table$locality_id
  message(paste("Successfully added", nrow(recovered_files), "files from 2024 to the data table."))
}

### Check for missing files again ###
# Identify which expected IDs are NOT present in your files_table
missing_tomst <- setdiff(expected_ids, files_table$locality_id)

# Print the results to the console
if(length(missing_tomst) > 0) {
  message("The following ", length(missing_tomst), " TOMST files are missing:")
  print(missing_tomst)
} else {
  message("All TOMST files (01-40) are present.")
}

############# All available files should now be accounted for #################
# Clean up temporary objects not needed for further analysis
#rm(files_table_2024, recovered_files, expected_ids, found_in_2024, list_files_24, 
#   list_path_24, locality_name_24, missing_tomst, path_2024, still_missing, list_files, list_path)
 
#################### Begin Data Pre-Processing ################################
###############################################################################

####################### Correct for timezone ##################################
# Next is a VERY important line, correcting the timezone for each locality ID
# (which is already linked to the paths of the file). Note that all TOMST are 
# automatically set to Coordinated Universal Time (UTC) and this needs to be 
# corrected for, or your days will not be correct. 
# We correct by geopolitical timezone here, but you could also correct by solar 
# timezone. You would need to include lat and long to do this. 
locality_metadata <-  data.table(locality_id = locality_name ,  
                                 tz_offset  = -7*60) # because we are -7 hours (i.e. 7*60 minutes) from UTC

# Next, join the file paths with the metadata in a single myClim object. 
# This also automatically cleans the data according to the myClim package. 
# This can take a little time. 
tms.f <- mc_read_data(files_table,locality_metadata) #this will produce a report. 

#### Check the newly created myClim object by summarizing some of the data ####
# Returns the number of localities, loggers and sensors in myClim object.
# Note that there are 4 sensors on each TOMST logger. Check that there 
# are the expected number of loggers and sensors.
mc_info_count(tms.f)

# Returns a data frame with summary per sensor. Check for impossible values. 
# Look for NAs. Step_seconds should be 900 (i.e. 15 minutes). 
mc_info(tms.f) 

# Returns a data frame with locality metadata. Lon, Lat and Elev may not be 
# available depending on the year, but you can find this in the separate 
# station_metadata.csv file on GitHub. Check that timezone has been corrected.
mc_info_meta(tms.f) 

# Returns a data frame with the cleaning log, showing what was fixed during the import.
# Some duplicities, missing and disordered are normal, but it's god to check if any 
# are very high. It is also good to check if there are any missing data that might signal tech issues. 
mc_info_clean(tms.f) 
View (mc_info_clean(tms.f)) # Allows you to have a closer look at the data in a bigger window. 

# Uses the myClim package to create TWO raster plots of the data as a time series, 
# visualizing overall patterns. The first plot shows temp and the second shows soil moisture.
mc_plot_raster(tms.f) 
# Look for anything strange-- for example, you will notice that Jan 2022 is showing as well
# above 0*C. This is because the TOMST were manufactured around then, and started temp recordings
# immediately. These temps are from the factory. 

# Given the above finding, let's crop the TOMST time series to when they were installed.
# From the time series, we can guess that this was in July 2022-- but we should try to confirm this.  
tms.f <- mc_prep_crop(tms.f,start = as.POSIXct("2022-07-31", tz="UTC"))  

# You can also make a time series for a single TOMST. Here is an example with TOMST_09
mc_plot_line(mc_filter(tms.f, localities =  "TOMST_09_QHI")) 

#Or for a single sensor: 
mc_plot_raster(mc_filter(tms.f, sensor = "TMS_T3")) 

# Or you could select out specific tomst to remove from your myCLim object. When 
# For example, we could remove TOMST_14 and TOMST_8 since they look strange.
# reverse =T tells mc_filter to exclude rather than keep these two TOMSTS.  
tms.f <- mc_filter(tms.f,localities = c("TOMST_14_QHI","TOMST_08_QHI"),reverse = T )

###################################################################################
############### Calculate virtual sensors using physical sensors ################## 
# In addition to the four actual sensors on the TOMST, the myClim package also
# provides a standardized way to calculate virtual sensors by extrapolating from
# this data. 

## To do this, we need to specify a soiltype, so we will default to universal for now
# This will also calculate Volumetric Water Content 
tms.calc <- mc_calc_vwc(tms.f, soiltype = "universal") #sensor name vwc_moisture

## Calculate virtual sensor with growing and freezing degree days
tms.calc <- mc_calc_gdd(tms.calc, sensor = "TMS_T3",) #sensor name gdd5
tms.calc <- mc_calc_fdd(tms.calc, sensor = "TMS_T3") #sensor name fdd0

## Calculate virtual sensor to estimate snow presence using 2 cm air temperature.
# This works by looking for times when the near ground temperature was 0*C, 
# meaning that the sensor was under snow. 
tms.calc <- mc_calc_snow(tms.calc, sensor = "TMS_T2") #sensor name "snow"

#### This is the end of our standardized pre-processing. 
#### You could export this now, using the following script: 
#### export_dt <- data.table(mc_reshape_long(tms.calc),use_utc = F)
#### But this would produce several million rows of data as it is currently
#### documenting every 15 minutes since July 2022. 

#### You likely will want to aggregate your data by day or month. 

#### Aggregating sensors to daily or monthly ####
# When aggregating, you will likely want to produce mean, min, and max values. 
# However, you may not want the true min and max values, as they could be incorrect
# if, for example, the sun shone directly onto the T3 sensor, artificially heating it
# and increasing the max. Therefore, we use a minimum percentile to calculate min 
# and max (i.e. the 5th percentile and 95th percentile). 

################## Aggregate to DAILY values using percentiles ################# 


#daily.tms <- mc_agg(tms.calc,fun=c("mean","percentile"),percentiles = c(2.5,97.5),period = "day",min_coverage=1,use_utc = F) 
daily.tms <- mc_agg(tms.calc, 
                   fun=c("mean","percentile"),
                   #custom_functions = list(mean_t=function(x) mean(x[x%between%  quantile(x,na.rm=T,probs=c(0.025,0.975))],na.rm=T)),
                   period = "day", 
                   min_coverage = 0.95,
                   percentiles = c(2.5,97.5))

# Export the object out of the myClim framework so you can view it.  
export_dt_daily <- data.table(mc_reshape_long(daily.tms), use_utc = FALSE) %>%
            select(-serial_number, -use_utc) %>%
            mutate(datetime = as.POSIXct(datetime)) %>% # make the date read as a date in lubridate
            mutate(  # add year column and calculate day of year (doy)
                year  = year(datetime),
                month = month(datetime),
                week  = week(datetime),
                day   = day(datetime),
                doy   = yday(datetime)) %>%
            mutate(sensor_name = case_when(
                str_detect(sensor_name, "percentile2.5$") ~ str_replace(sensor_name, "percentile.*", "min"), # shortens percentiles to just being called min or max
                str_detect(sensor_name, "percentile97.5$") ~ str_replace(sensor_name, "percentile.*", "max"),
                TRUE ~ sensor_name
                 ))
                   
unique(export_dt_daily$sensor_name) #checking that the sensor names were shortened correctly
view(export_dt_daily)

################## Aggregate to MONTHLY values using percentiles ################# 
monthly.tms <- mc_agg(daily.tms,
                      fun=c("mean","min","max"),
                      period = "month",min_coverage=0.95,use_utc = F) 

# Export the object out of the myClim framework so you can view it.  
export_dt_monthly <- data.table(mc_reshape_long(monthly.tms), use_utc = FALSE) %>%
  select(-serial_number, -use_utc) %>% # remove these columns
  mutate(datetime = as.POSIXct(datetime)) %>% # make the date read as a date in lubridate
  mutate(  # add year column and calculate day of year (doy)
    year  = year(datetime),
    month = month(datetime)) %>%
  mutate(sensor_name = case_when(
    str_detect(sensor_name, "percentile2.5") ~ str_replace(sensor_name, "percentile2.5", "min"), # shortens percentiles to just being called min or max
    str_detect(sensor_name, "percentile97.5") ~ str_replace(sensor_name, "percentile97.5", "max"),
    TRUE ~ sensor_name
  ))

unique(export_dt_monthly$sensor_name) #checking that the sensor names were shortened correctly
## monthly naming convention examples: TMS_T3_mean_t_mean monthly mean of the daily mean
## monthly naming convention examples: TMS_T3_max_t_mean monthly mean of the daily max
## monthly naming convention examples: TMS_T3_mean_t_max monthly max of the daily mean
view(export_dt_monthly)


################## Aggregate to HOURLY values  ################# 
hourly.tms <- mc_agg(tms.calc,
                     fun=list(TMS_T3 =c("mean","min","max")), ### to fasten the computation, only selection the sensor of interest
                     period = "hour",
                     min_coverage=1,use_utc = T) ##have to use UTC == T for hourly

# Export the object out of the myClim framework so you can view it.  
export_dt_hourly <- data.table(mc_reshape_long(hourly.tms), use_utc = F) %>%
  select(-serial_number, -use_utc) %>% # remove these columns
  mutate(datetime = as.POSIXct(datetime)) %>% # make the date read as a date in lubridate
  mutate(  # add year column and calculate day of year (doy)
    year  = year(datetime),
    month = month(datetime),
    week  = week(datetime),
    day   = day(datetime),
    doy   = yday(datetime),
    hour  = hour(datetime)) %>%
  mutate(sensor_name = case_when(
    str_detect(sensor_name, "percentile2.5") ~ str_replace(sensor_name, "percentile2.5", "min"), # shortens percentiles to just being called min or max
    str_detect(sensor_name, "percentile97.5") ~ str_replace(sensor_name, "percentile97.5", "max"),
    TRUE ~ sensor_name
  ))

unique(export_dt_hourly$sensor_name) #checking that the sensor names were shortened correctly

view(export_dt_hourly)



###################### Print pre-processed data ###########################
# The 2025 dataset has aready been printed to "TOMST-QHI/data/". Please do not print this again. 
# When a new year of TOMST data is available, use this script to pre-process and save to the "TOMST-QHI/data/" 
# folder using the same naming convention and just updating the year. 
dir.create("export_data")
write.csv(export_dt_daily, "export_data/2025_TOMSTdata_preprocessed_daily.csv", row.names = FALSE)
write.csv(export_dt_monthly, "export_data/2025_TOMSTdata_preprocessed_monthly.csv", row.names = FALSE)
write.csv(export_dt_hourly, "export_data/2025_TOMSTdata_preprocessed_hourly .csv", row.names = FALSE)

# The data is now ready to be cleaned or processed in whichever way makes the most sense for your research. 





###################### Working notes #################################
## export the object out of the MC framework
## This uses data.table to produce the exact same datasheet as the tidyverse style that produces "export_dt_daily"
export_dt <- data.table(mc_reshape_long(daily.tms),use_utc = F)
export_dt[, serial_number:=NULL] ##removing useless col
export_dt[, datetime := ymd(datetime)] ## :=  creates or update a column in data.table, here we swith to a lubridate format with ymd
export_dt[, month := month(datetime)] ## extracting the month
export_dt[, day := day(datetime)] ## extracting the day
export_dt[, week := week(datetime)] ## extracting the week

#Creates an monthly average for each sensor over all years. 
monthly_averages <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                              by=.(month,sensor_name)] # na.rm=T remove incomplete months 

#Creates a daily average for each sensor over all years. 
daily_values <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                          by=.(month,day,sensor_name,height,week)] # na.rm=T remove incomplete days 

#Creates a weekly average for each sensor over all years. 
weekly_values <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                           by=.(month,sensor_name,height,week)] # na.rm=T remove incomplete days 

daily_values <- daily_values[month == 10,] # get october

weekly_values <- weekly_values[month == 10,] # get october

#uses datatable function to switch to wide view instead of long view for the sensor names
daily_values <- dcast(daily_values,month+day ~ sensor_name,value.var = 'mean_value',fun.aggregate = mean)

weekly_values <- dcast(weekly_values,month+week ~ sensor_name,value.var = 'mean_value')

View(weekly_values)
View(daily_values)