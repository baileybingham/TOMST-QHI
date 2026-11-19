###############################################################################
##################  Bailey's Pre-Processing Script for the  ###################
################## TOMST from Qikiqtaruk - Herschel Island  ###################
##################         Created November 2026            ###################
##################  Includes deployment and death dates     ###################
##################            for these TOMST               ###################
###############################################################################
#==============================================================================
# The goal of this script is to pre-process the most recent year of TOMST 
# downloads, while also including TOMST that have died in previous years, and 
# accounting for any known lore about each site and/or device. 

# TOMST histories currently fall into one of the following backgrounds: 
#       1. A continuous run from July 2022 until August 2026
#       2. A continuous run from July 2022 until their untimely death, 
# whenever that might have occurred. 
#       3. A TOMST that was known to be replaced in 2025 and was successfully 
# recovered in August 2026. 
#       4. The TOMST currently residing at the site of TOMST_05, which was first
# deployed at site TOMST_34, before the hardware was moved in August of 2024. 

# BB discovered this lore through a great deal of detective work, which is 
# documented in Allyears_TOMST_Fieldnotes.csv. Field notes should be updated
# each year, when new TOMST data is downloaded. 

# When TOMST hardware (i.e. a TOMST with a unique serial number) dies or is
# replaced, please update the end date for any discontinued TOMST, and the 
# deployment date for any new TOMST. AND make sure the last available download
# of any dead TOMST is stored in the TOMST graveyard. 
#==============================================================================

#==============================================================================
############################ Download packages  ###############################
#==============================================================================
library(myClim) ## logger data reading
library(foreach) ## efficient loop
library(lubridate) ## manipulate date_time
library(tidyverse) #includes ggplot, tidyr, dplyr, stringr etc. 
library(data.table) ## Efficient data.frame


#==============================================================================
########################## BUILD FILES_TABLE ############################
#==============================================================================
#------------------------------------------------------------------------------
# Step 1. Pull all data from the most recent year folder. 
# This will download all TOMST that are currently active. 
#------------------------------------------------------------------------------

# Scans the folder data/2026/ and creates a character vector of every file inside. 
# Since full.names = T, it returns the full name including the relative path. 
# Change the year to the most recent data year only after ensuring that files have
# been uploaded with the correct file naming conventions. 
list_path <- list.files("data/2026/",full.names = T) 

# Scan the same folder but use full.names = F, so it only returns only the 
# filenames without the directory path (e.g., "TOMST_01_QHI.csv"). 
# This makes string manipulation easier in the next step.
list_files <- list.files("data/2026/",full.names = F) 

# Use the stringr package to extract data from the file name. 
# In this case, we are extracting the "locality_id" from each filename, 
# meaning the digit of the TOMST.You could also use it 
# to extract the serial number by changing the Regex Pattern to specify the 
# serial number part of the file name. This allows us to use metadata from the 
# filenames as a grouping variable in future analysis.
locality_name <-  str_extract(list_files, "TOMST_[:digit:]+") 
serial_numbers <- str_extract(list_files, "(?<=data_)\\d{8}")

# Assign the extracted TOMST IDs (e.g., TOMST_01_QHI) to their respective paths.
files_table26 <- data.table(path = list_path,
                          locality_id = locality_name,  
                          serial_number = serial_numbers,
                          data_format = "TOMST") # this adds a column specifying 
                                                 # that this is TOMST data, this 
                                                 # is needed for myClim processing

#------------------------------------------------------------------------------
# Step 2. Pull all data from the TOMST graveyard. 
# This will pull in all TOMST that have died and are no longer active. 
#------------------------------------------------------------------------------

# Redo the above, but instead scan the folder data/TOMST_Graveyard/ to look for all the TOMST that died young. 
list_path_dead <- list.files("data/TOMST_Graveyard/",full.names = T) 
list_files_dead <- list.files("data/TOMST_Graveyard/",full.names = F) 
locality_name_dead <-  str_extract(list_files_dead, "TOMST_[:digit:]+") 
serial_numbers_dead <- str_extract(list_files_dead, "(?<=data_)\\d{8}")

dead_files_table <- data.table(path = list_path_dead,
                          locality_id = locality_name_dead,  
                          serial_number = serial_numbers_dead,
                          data_format = "TOMST") 

#------------------------------------------------------------------------------
# Step 3. Merge both file tables and check for any missing
#------------------------------------------------------------------------------
files_table <- bind_rows (dead_files_table, files_table26)

#Check which TOMSTS are missing after this process.
expected_ids <- sprintf("TOMST_%02d", 1:40) # Create a vector of all expected 
# IDs from TOMST_01 to TOMST_40. sprintf ensures the leading zero (01, 02, etc.) 
# matches the file naming convention

# Identify which expected IDs are NOT present in your files_table
missing_tomst <- setdiff(expected_ids, files_table$locality_id)

# Print the results to the console
if(length(missing_tomst) > 0) {
  message("The following ", length(missing_tomst), "TOMST files are missing:")
  print(missing_tomst)
} else {
  message("All TOMST files (01-40) are present.")
}
#==============================================================================

#==============================================================================
########################## GET DEPLOYMENT DATES ##############################
# We will use this to crop the TOMST data more efficiently later. 
#==============================================================================
# Get metadata information about the deployment record, from the first two rows of the dataframe
deploydates_meta <- read_csv("data/device_deployment_periods.csv", 
                             n_max = 2, 
                             col_names = FALSE, 
                             show_col_types = FALSE) %>%
  mutate(field = c("Description", "Column_Header")) %>%
  pivot_longer(-field) %>%
  pivot_wider(names_from = field, values_from = value) %>%
  select(Column_Header, Description)
print(deploydates_meta)

# Get the data
deploydates <-read_csv("data/device_deployment_periods.csv", 
                       skip=1, #skip the first line, which contains a verbose description of each column printed above
                       col_types = cols(serial_number = col_character(),
                       deploy_date = col_date(format = "%m-%d-%Y"),
                       end_date = col_date(format = "%m-%d-%Y"))) %>%
                       rename(start_date = deploy_date)

#==============================================================================

#==============================================================================
######################### CREATE LOCALITIES TABLE #############################
# This is specific to the myClim package and includes our timezone offset and
# can include elevation (elevation in m), lon_wgs84 (longitude in decimal 
# degrees), lat_wgs84 (latitude in decimal degrees)
#==============================================================================

# Next is a VERY important line, correcting the timezone for each locality ID
# (which is already linked to the paths of the file). Note that all TOMST are 
# automatically set to Coordinated Universal Time (UTC) and this needs to be 
# corrected for, or your days will not be correct. 
# We correct by geopolitical timezone here, but you could also correct by solar 
# timezone. You would need to include lat and long to do this. 
timezone <-  data.table(locality_id = expected_ids ,  
                                 tz_offset  = -7*60) # because we are -7 hours (i.e. 7*60 minutes) from UTC

loc <-read_csv("data/TOMST_metadata.csv")%>%
      select (Field_ID, Lat, Lon, Elevation)%>%
      rename(locality_id = Field_ID, 
             elevation = Elevation, 
             lon_wgs84 = Lon,
             lat_wgs84 = Lat)

localities_table <-left_join(timezone, loc) 

# All tables needed to pre-process in myClim are now created. 

# clean up workspace
rm(list = setdiff(ls(), c("files_table", "deploydates", "localities_table")))


#==============================================================================
######################### BEGIN DATA PRE-PROCESSING ###########################
#==============================================================================

# Next, join the file paths with the metadata in a single myClim object. 
# This also automatically cleans the data according to the myClim package. 
# This can take a little time. 
tms.f <- mc_read_data(files_table,localities_table) #this will produce a report.

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
# Some duplicities, missing and disordered are normal, but it's good to check if any 
# are very high. It is also good to check if there are any missing data that might signal tech issues. 
mc_info_clean(tms.f) 
View (mc_info_clean(tms.f)) # Allows you to have a closer look at the data in a bigger window. 

# Uses the myClim package to create two raster plots of the data as a time series, 
# visualizing overall patterns. The first plot shows temp and the second shows soil moisture.
mc_plot_raster(tms.f) 
# Look for anything strange-- for example, you will notice that Jan 2022 is showing as well
# above 0*C. This is because the TOMST were manufactured around then, and started temp recordings
# immediately. These temps are from the factory. 

# Given the above finding, let's crop the TOMST time series to when they were installed.
# The start dates and end dates of each logger are listed in the deploydates data frame, 
# so we can use this to crop. 

logger_lookup <- mc_info_logger(tms.f) %>%
  select(locality_id, serial_number, logger_name) # get the logger name that myClim assigned

crop_df <- deploydates %>%
  inner_join(logger_lookup, by = c("locality_id", "serial_number")) %>%
  transmute(
    locality_id = locality_id,
    logger_name = logger_name,
    start = as.POSIXct(start_date, tz = "UTC"),
    end   = as.POSIXct(end_date, tz = "UTC") # NAs in end date keep the data until the most recent download
  )

tms.f <- mc_prep_crop(tms.f, crop_table = crop_df)

#remake the raster, now that the data should be cropped to the correct start dates. 
mc_plot_raster(tms.f) 

# You can also make a time series for a single TOMST. Let's look at TOMST_14, since
# it looks a little weird. 
mc_plot_line(mc_filter(tms.f, localities =  "TOMST_14")) 
# Checking the data, the sensor broke on June 12th, 2024, so let's further crop the sensor. 

## HOW DO I CROP ONE SENSOR??? ###


# TOMST_08 also has something weird going on with it. 
mc_plot_line(mc_filter(tms.f, localities =  "TOMST_08")) 
# From looking at the data, the sensor seems to have broken sometime after 
# October 12, 2023. Unclear if the later data is good. So let's just remove it. 

crop_df_erroneous_values <- data.table(locality_id = c("TOMST_14","TOMST_08"),
                                       logger_name = c("TMS_1"),
                                       start = NA , 
                                       end = c( as.POSIXct("2023-06-11", tz="UTC"), as.POSIXct("2023-11-11", tz="UTC")))

tms.f <- mc_prep_crop(tms.f, crop_table = crop_df_erroneous_values)

## did it work ?
mc_info(tms.f)[mc_info(tms.f)$locality_id %in% c( "TOMST_14", "TOMST_08"),]
# yes


# Or you could select out specific tomst to remove from your myCLim object. When 
# For example, we could remove TOMST_14 and TOMST_8 since they look strange.
# reverse =T tells mc_filter to exclude rather than keep these two TOMSTS.  
tms.f <- mc_filter(tms.f,localities = c("TOMST_14_QHI","TOMST_08_QHI"),reverse = T )

## WE NEED TO CROP TO START AND END DATES. 

# Once all TOMST are together, we need to clean the data for logging errors. 
# -81.12 should equal NA. 














