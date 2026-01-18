#################################
### Bulk Renaming TOMST files ###
### Bailey Bingham
#################################

library (tidyverse)
library (lubridate)

# Define the base directory containing all 40 subfolders
base_dir <- "data/2023/"


# Get a list of all subdirectories (folders) within the base directory
# full.names = TRUE gives the complete path
folders <- list.dirs(base_dir, full.names = TRUE, recursive = FALSE)

# Iterate through each folder
for (folder_path in folders) {
  # 1. Get the folder name (e.g., "TOMST_01_15Aug2023")
  folder_name <- basename(folder_path)
  
  # 2. Extract the prefix needed for the new file name (e.g., "TOMST_01")
  # This uses regular expressions to capture everything before the last underscore
  # The pattern "_(?!.*_)" finds the last underscore. We replace everything after it.
  prefix <- gsub("_(?!.*_).*", "", folder_name, perl = TRUE)
  
  # 3. List all the target files in the current folder (assuming .csv files)
  # full.names = TRUE ensures we have the complete path for renaming
  files_to_rename <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)
  
  # Iterate through each file in the current folder
  for (old_filepath in files_to_rename) {
    # Get the original file name (e.g., "data_94217254_2023_08_15_0.csv")
    original_filename <- basename(old_filepath)
    
    # Construct the new file name using the extracted prefix
    # The target format is: "TOMSTXX-QHI-original_filename.csv"
    new_filename <- paste0(prefix, "-QHI-", original_filename)
    
    # Construct the full new file path (keeping it in the same folder)
    new_filepath <- file.path(folder_path, new_filename)
    
    # Perform the renaming operation
    # It is a good practice to test with a few files first or use a dry run
    file.rename(from = old_filepath, to = new_filepath)
  }
}

print("Renaming process complete.")

#######DO NOT RUN MORE THAN ONCE!!! You will just keep adding the TOMST## to the file name. 
##########################################################################################
library(fs)
# 1. Define your main directory (where the subfolders are located)
base_dir <- "data/2023/"

# 2. Define the target directory (the parent folder where files will go)
target_dir <- "data/2023/"

# 3. Find all files within subdirectories (recursive=TRUE)
#    full.names=TRUE gives the complete path to each file
all_files <- list.files(path = parent_dir, recursive = TRUE, full.names = TRUE)

# 4. Loop through the files and copy/move them to the target folder
for (file_path in all_files) {
  # Get just the filename
  file_name <- basename(file_path)
  
  # Construct the destination path
  destination_path <- file.path(target_dir, file_name)
  
  # Copy the file (use file.rename() to move instead of copy)
  file.copy(from = file_path, to = destination_path, overwrite = TRUE) # overwrite=TRUE if files with same name exist
  
  # Optional: Remove original file after copying (if you want to move, not copy)
  # file.remove(file_path)
}

print("Files extracted successfully!")
