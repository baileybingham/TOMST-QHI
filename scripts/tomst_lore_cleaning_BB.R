###############################################################################
##################  Bailey's Pre-Processing Script for the  ###################
################## TOMST from Qikiqtaruk - Herschel Island  ###################
##################         Created November 2026            ###################
################## and includes and accounts for the unique ###################
##################         lore of these TOMST              ###################
###############################################################################

#------------------------------------------------------------------------------
############################ Download packages  ###############################
library(myClim) ## logger data reading
library(foreach) ## efficient loop
library(lubridate) ## manipulate date_time
library(tidyverse) #includes ggplot, tidyr, dplyr, stringr etc. 
library(data.table) ## Efficient data.frame


#==============================================================================
# In order to account for the unique and confusing histories of each
# TOMST site, we will process the TOMST by their histories, including the four
# following possible trajectories: 
#       1. A continuous run from July 2022 until August 2026
#       2. A continuous run from July 2022 until their untimely death, 
# whenever that might have occurred. 
#       3. A TOMST that was known to be replaced in 2025 and was successfully 
# recovered in August 2026. 
#       5. The TOMST currently residing at the site of TOMST_05, which was first
# deployed at site TOMST_34, before the hardware was moved in August of 2024. 
#==============================================================================

#------------------------------------------------------------------------------
############ STEP 1: Pull the normal, easy TOMST sites ########################
#------------------------------------------------------------------------------

#==============================================================================
# The following n=28 TOMST have had a single continuous run of working: #blessed. 
# TOMST_01, TOMST_03, TOMST_06, TOMST_09, TOMST_10, TOMST_12, TOMST_13, TOMST_15,
# TOMST_16, TOMST_17, TOMST_18, TOMST_19, TOMST_20, TOMST_21, TOMST_22, TOMST_23, 
# TOMST_24, TOMST_25, TOMST_26, TOMST_30, TOMST_31, TOMST_32, TOMST_33, TOMST_36, 
# TOMST_37, TOMST_38, TOMST_39, TOMST_40

# For all of these TOMST, we can just use the downloaded 2026 data. Yay!
#==============================================================================






#------------------------------------------------------------------------------
############ STEP 2: Pull the TOMST that died young ###########################
#------------------------------------------------------------------------------

#==============================================================================
# The following n= TOMST died young, but had a continuous run until they died: 
# TOMST_XX, 

















#==============================================================================
######################## YEARLY SUMMARIES #####################################
#==============================================================================

#------------------------------------------------------------------------------
########################### 2022 TOMST Data #############################
#==============================================================================
# n= 40 TOMST downloaded

# In 2022, all the TOMST were deployed on QHI for the first time, between July 
# 18th and July 27th (see Allyears_TOMST_Fieldnotes.csv for details). Any dates 
# before their deployment date must be removed. Recall that the TOMST begin 
# recording data from the time that they are manufactured. 
# Data from all 40 TOMST were successfully downloaded in early August 2022. 
#==============================================================================

#------------------------------------------------------------------------------
########################### 2023 TOMST Data #############################
#==============================================================================
# n= 39 TOMST downloaded

# From early August 2022, the TOMST were left to continued monitoring until  
# their next download date in late June 2023. By this point, TOMST_02 had died
# and the data was not recoverable. i.e. only 39 TOMST were successfully  
# downloaded in 2023. The data was downloaded again in early August, and at this 
# point TOMST 11 was not recovered, so the data is only available from the 
# earlier download and extends until late June, 2023. 
# Neither TOMST was replaced. 
#==============================================================================

#------------------------------------------------------------------------------
########################### 2024 TOMST Data #############################
#==============================================================================
# n= 37 TOMST downloaded

# From early August 2023, the TOMST were left to continued monitoring until  
# their next download date in early August 2024. By this point, TOMST_05 was 
# lost and data was not recoverable. This was in addition to TOMST_02 and 
# TOMST_11 that were lost in 2023. 37 TOMSTs were downloadable this year. 

# **** Note that, because TOMST_05 was an important location (ITEX plot and 
# Phenocam) the hardware for nearby TOMST_34 was moved to the site for TOMST_05
# and longterm monitoring at the site of TOMST_34 was discontinued moving 
# forward. ****

# **** TOMST_14 was downloaded this year but was not redeployed as it was 
# damaged. All data after June 13, 2024 for TOMST_14 reads as -81.12, and should 
# be considered NA. ****

# TOMST_02 and TOMST_11 were still not replaced. 
#==============================================================================

#------------------------------------------------------------------------------
########################### 2025 TOMST Data #############################
#==============================================================================
# n= 33 TOMST downloaded

# TOMST_11, TOMST_02, TOMST_14 and TOMST_34 were not downloaded in 2025, as they
# were not re-deployed after damage/ loss in previous years. 
# Additionally, TOMST_08, TOMST_27, and TOMST_29 were lost/ not recovered this year.
# 
# **** Note that all data from TOMST_05 is actually old_TOMST_34, before the date 
# that the device was moved (~August 11, 2024). This should be removed and the 
# data should be merged with old_TOMST_05. ****

# **** Some TOMST were replaced this year, but we didn't do a good job of tracking
# which ones, or their serial numbers. All will be revealed in future years 
# though, when we download new serial numbers at the sites. ****
#==============================================================================


#------------------------------------------------------------------------------
########################### 2026 TOMST Data #############################
#==============================================================================
# n= 36 TOMST downloaded,but 32 are usable, since four of the downloads have  
# serial numbers that are not associated with known sites, due to bad record 
# keeping. All will be clear next year, when we revisit the sites. 

# TOMST_02 and TOMST_27 were redeployed with new serial numbers on August 2025 
# and were downloaded this year. Dates before August 15th should be removed,  
# since the devices weren't deployed yet. Four additional new TOMST were deployed 
# in 2025, but we did not keep detailed notes during the field season, so we will
# have to check which site these serial numbers are at in 2027. 
#
# TOMST_04, TOMST_08, TOMST_11, TOMST_14, TOMST_28, and TOMST_29 were 
# not downloaded in 2026, and may or may not have been redeployed in 2025 after
# being lost in previous years. 

# Additionally TOMST_07 was not recovered in 2026. 
# **** NOTE: four of these missing sites are likely covered by the downloaded data 
# that was unlabeled, and had new serial numbers (mentioned above).

# TOMST_34 site was discontinued in 2024 and no longer exists. 
# (i.e. expected # of IDS is n=39)
#==============================================================================
