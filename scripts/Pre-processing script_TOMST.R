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
library(foreach) ## efficient loop
library(data.table) ## efficient data.frame  
library(stringr) ## efficient character manipulation
library(lubridate) ## manipulate date_time

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
                          locality_id = locality_name ,  
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

#if(length(missing_tomst) > 0) {
#  message("--- Checking 2024 folder for missing files ---")
#  # Scan the 2024 folder for potential backup files
#  # Change 2024 to reflect the folder year you want
#  path_2024 <- "data/2024/"  
#  list_path_24 <- list.files("data/2024/", full.names = TRUE)
#  list_files_24 <- list.files("data/2024/", full.names = FALSE)
#  
#  # This extracts the IDs just like we did for 2025 and creates a reference table
#  locality_name_24 <- str_extract(list_files_24, "TOMST_[:digit:]+_QHI")
#  
#  files_table_2024 <- data.table(path = list_path_24,
#                                 locality_id = locality_name_24,
#                                 data_format = "TOMST")
#  
#  # Identify which missing IDs are available in 2024
#  found_in_2024 <- intersect(missing_tomst, files_table_2024$locality_id)
#  still_missing <- setdiff(missing_tomst, found_in_2024)
  
#  # Report Available/Missing
#  if(length(found_in_2024) > 0) {
#    message("The following TOMST IDs are available in 2024.")
#    print(found_in_2024)
#  }
#  if(length(still_missing) > 0) {
#    message("The following TOMST IDs remain missing:")
#    print(still_missing)
#  }
#}

###### If you want to bind the missing files found in the 2024 script,
###### you can use this script. ONLY DO THIS ONCE or you will add duplicates: 
#files_table_2024[, serial_number := stringr::str_extract(basename(path), "(?<=data_)\\d{8}")]
#if(length(found_in_2024) > 0) {
#  recovered_files <- files_table_2024[locality_id %in% found_in_2024]
#  files_table <- rbind(files_table, recovered_files)
#  files_table <- files_table[order(locality_id)]
#  locality_name <- files_table$locality_id
#  message(paste("Successfully added", nrow(recovered_files), "files from 2024 to the data table."))
#}

### Check for missing files again ###
# Identify which expected IDs are NOT present in your files_table
#missing_tomst <- setdiff(expected_ids, files_table$locality_id)

# Print the results to the console
#if(length(missing_tomst) > 0) {
#  message("The following ", length(missing_tomst), " TOMST files are missing:")
#  print(missing_tomst)
#} else {
#  message("All TOMST files (01-40) are present.")
#}

############# All available files should now be accounted for #################
# Clean up temporary objects not needed for further analysis
#rm(files_table_2024, recovered_files, expected_ids, found_in_2024, list_files_24, 
#   list_path_24, locality_name_24, missing_tomst, path_2024, still_missing, list_files, list_path)
 
#################### Begin Data Pre-Processing ################################
###############################################################################

####################### Correct for timezone ##################################
# Next is a VERY important line, correcting the timezone for each locality ID
#(which is already linked to the paths of the file). Note that all TOMST are 
# automatically set to Coordinated Universal Time (UTC) and this needs to be 
# corrected for, or your days will not be correct. 
# We correct by geopolitical timezone here, but you could also correct by solar 
# timezone. You would need to include lat and long to do this. 
locality_metadata <-  data.table(locality_id = locality_name ,  
                                 tz_offset  = -7*60) # because we are -7 hours (i.e. 7*60 minutes) from UTC

# Next, join the file paths with the metadata in a single myClim object. 
# This also automatically cleans the data according to the myClim package. 
# This can take a little time. It will produce a log telling you how it cleaned the data.
tms.f <- mc_read_data(files_table,locality_metadata) #this will produce a report. 

# GETTING LOTS OF ERRORS SAYING: 
# 1: In .prep_clean_check_different_values_in_duplicated(locality_id,  ... :
# In logger 94217246 are different values of TMS_T1 in same time.
# 
# Jeremy, I got to here and I am getting a ton of warnings that I can't figure 
# out how to fix. Can you help?
#
#
#
#
#
#


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
# Look for anything strange-- for example, you will notice that Jan 2022 is showing as well
# above 0*C. This is because the TOMST were manufactured around then, and started temp recordings
# immediately. These temps are from the factory. 
mc_plot_raster(tms.f) 

# Given the above finding, let's crop the TOMST time series to when they were installed.
# From the time series, we can guess that this was in July 2022-- but we should try to confirm this.  
tms.f <- mc_prep_crop(tms.f,start = as.POSIXct("2022-07-31", tz="UTC"))  


# You can also select out specific tomst to remove from your myCLim object.
# For example, we could remove TOMST_14 and TOMST_8. revers =T tells mc_filter 
# to exclude rather than keep these two TOMSTS. Remove the # to run this. 
# tms.f_filtered <- mc_filter(tms.f,localities = c("TOMST_14_QHI","TOMST_08_QHI"),reverse = T )

# Or you could make a time series for a single TOMST. Here is an example with TOMST_09
mc_plot_line(mc_filter(tms.f, localities = "TOMST_09_QHI")) 

#### Calculate virtual sensors using physical sensors #### 
# In addition to the four actual sensors on the TOMST, the myClim package also
# provides a standardized way to calculate virtual sensors by extrapolating from
# this data. 

## To do this, we need to specify a soiltype, so we will default to universal for now
tms.calc <- mc_calc_vwc(tms.f, soiltype = "universal")

## Calculate virtual sensor with growing and freezing degree days
tms.calc <- mc_calc_gdd(tms.calc, sensor = "TMS_T3",)
tms.calc <- mc_calc_fdd(tms.calc, sensor = "TMS_T3")

## Calculate virtual sensor to estimate snow presence using 2 cm air temperature.
# This works by looking for times when the near ground temperature was 0*C, 
# meaning that the sensor was under snow. 
tms.calc <- mc_calc_snow(tms.calc, sensor = "TMS_T2")

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

# Aggregate all those sensors to daily values using percentiles.  
daily.tms <- mc_agg(tms.calc,fun=c("mean","percentile"),percentiles = c(0.05,0.95),period = "day",min_coverage=1,use_utc = F)
# Export the object out of the myClim framework so you can view it. 
export_dt <- data.table(mc_reshape_long(daily.tms),use_utc = F)
export_dt[, datetime := ymd(datetime)] ## :=  creates or update a column in data.table, here we swith to a lubridate format with ymd
export_dt[, month := month(datetime)] ## extracting the month
export_dt[, day := day(datetime)] ## extracting the day
export_dt[, week := week(datetime)] ## extracting the week

monthly_averages <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                              by=.(month,sensor_name)] # na.rm=T remove incomplete months 

daily_values <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                              by=.(month,day,sensor_name,height,week)] # na.rm=T remove incomplete days 

weekly_values <- export_dt[,.(mean_value = mean(value,na.rm=T)),
                          by=.(month,sensor_name,height,week)] # na.rm=T remove incomplete days 

daily_values <- daily_values[month == 10,] # get october

weekly_values <- weekly_values[month == 10,] # get october

daily_values <- dcast(daily_values,month+day ~ sensor_name,value.var = 'mean_value',fun.aggregate = mean)

weekly_values <- dcast(weekly_values,month+week ~ sensor_name,value.var = 'mean_value')

View(weekly_values)
View(daily_values)
View(daily_values_svg)
View(daily_values_svg_2)
