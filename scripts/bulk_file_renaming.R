#################################
### Bulk Renaming TOMST files ###
### Bailey Bingham
#################################

library (tidyverse)
library (lubridate)
library(stringr)

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

########################################################################################

# 1. Define the path to your 2024 files directory
dir_path <- "data/2024/"

# 2. Define the file pattern to match (e.g., all CSV files that start with "TOMST-")
# This pattern matches files like "TOMST-07_QHI_2024_08_11_0.csv"
file_pattern <- "^TOMST-\\d{2}_QHI_.*\\.csv$" 

# -----------------------------------------------------


# --- RENAMING LOGIC ---

# Get full paths and short names of existing files matching the pattern
old_files_full_path <- list.files(dir_path, pattern = file_pattern, full.names = TRUE)
old_files_short_name <- basename(old_files_full_path)

if (length(old_files_full_path) == 0) {
  stop("No files found matching the specified pattern in the directory. 
  Please check your 'dir_path' and 'file_pattern' configuration.")
}

# Function to generate the correct new filename
generate_new_name <- function(old_name) {
  # Replace the FIRST hyphen with an underscore using sub()
  # sub(pattern, replacement, x)
  new_name <- sub("-", "_", old_name)
  return(new_name)
}

# Apply the function to all filenames to create a vector of new names
new_files_short_name <- sapply(old_files_short_name, generate_new_name, USE.NAMES = FALSE)

# Define the full paths for the new files
new_files_full_path <- file.path(dir_path, new_files_short_name)

# --- EXECUTION (UNCOMMENT THE LINE BELOW TO RUN) ---

 file.rename(from = old_files_full_path, to = new_files_full_path)

if (length(new_files_full_path) > 0) {
  cat("\nPreview of renaming operation:\n")
  # Display a preview of changes
  print(data.frame(
    "Old Name" = basename(old_files_full_path),
    "New Name" = basename(new_files_full_path)
  ))
  cat("\nTo apply these changes, uncomment the 'file.rename(...)' line above and run the script again.\n")
}
 
 ####################################################################################################
 file1_path <- "data/2024/TOMST_37_QHI_2024_08_11__confirmnumber_onridgebetweeneastandwesticecreek.csv"
 file2_path <- "data/2024/TOMST_37_QHI_2024_08_11_0.csv"
 
 # Calculate MD5 hashes for both files
 checksums <- tools::md5sum(c(file1_path, file2_path))
 
 # Compare the two hash values
 are_identical <- checksums[1] == checksums[2]
 
 if (are_identical) {
   print("The files have identical content.")
 } else {
   print("The files are different.")
 }
 
 #########################################################################################
 
 # --- Step 1: Define your input directory ---
 # Set this to the folder where your files are located
 input_dir <- "data/2023/"
 
 # --- Step 2: Get all relevant files ---
 # List all files ending with your specific pattern (adjust as needed)
 # For example, to get all .txt files:
 file_list <- list.files(path = input_dir, pattern = "TOMST_.*\\.txt$", full.names = TRUE)
 
 # --- Step 3: Process each file ---
 # Create an empty list to store the old and new names
 file_changes <- list()
 
 for (file_path in file_list) {
   # Get just the filename from the full path
   original_filename <- basename(file_path)
   
   # Use gsub to replace the first hyphen with an underscore
   # The pattern "-QHI" is specific, but we can generalize to just the first hyphen
   # For your specific case, replacing the *first* hyphen might work best if other hyphens exist
   new_filename <- gsub("-", "_", original_filename, fixed = TRUE, nmax = 1) # nmax=1 replaces only the first one
   
   # Store the original and new name
   file_changes[[original_filename]] <- new_filename
   
   # --- Optional: Perform the actual renaming ---
   # Uncomment the lines below to rename the files on your disk
    new_file_path <- file.path(input_dir, new_filename)
    file.rename(file_path, new_file_path)
    cat("Renamed:", original_filename, " -> ", new_filename, "\n")
 }
 
 #######################################################################
 
 folder_path <- "data/2025/"
 
 # 2. List files including the full directory path
old_files <- list.files(path = folder_path, 
                         pattern = NULL, 
                         full.names = TRUE)


 # 3. Transform names while preserving the directory path
 # Pattern captures: (path/data_...)_TOMST_([number])
 new_files <- gsub(
   pattern = "(.*)_TOMST_([0-9]+)\\.csv$", 
   replacement = "\\1_TEMP_\\2.csv", # Temporary step to handle pathing
   x = old_files
 )
 
 # Refined replacement to insert "TOMST_01_QHI_" at the start of the filename
 # but AFTER the directory path
 new_files <- paste0(
   dirname(old_files), "/", 
   "TOMST_0", gsub(".*_TOMST_([0-9]+)\\.csv$", "\\1", old_files), 
   "_QHI_", 
   basename(gsub("_TOMST_.*\\.csv$", "", old_files)), 
   ".csv"
 )
 
 # 4. Rename files in place
 file.rename(from = old_files, to = new_files)
 ################################################################
 
 # 1. Define the folder path
 folder_path <- "data/2025/"
 
 # 2. List all files in the folder (as requested)
 all_files <- list.files(path = folder_path, full.names = TRUE)
 
 # 3. Filter for files that match your naming pattern to avoid errors
 # This ensures we only touch files that contain "TOMST"
 old_files <- all_files[grepl("TOMST", all_files)]
 
 # 4. Generate new names by applying the cleanup rules
 # Rule A: Find "TOMST_" followed by any number of zeros and then digits, 
 #         and replace it with "TOMST_" and just those digits (removes leading 0s).
 # Rule B: Find "QHI" at the very end of the name (before .csv) and remove it.
 new_files <- gsub("TOMST_0+([0-9]+)", "TOMST_\\1", old_files) # Rule A
 new_files <- gsub("QHI\\.csv$", ".csv", new_files)           # Rule B
 
 # 5. Check if any changes are actually needed
 # This prevents renaming a file to its own name
 to_rename <- old_files != new_files
 
 # 6. Execute renaming for changed files
 if(any(to_rename)) {
   file.rename(from = old_files[to_rename], to = new_files[to_rename])
   message(paste("Renamed", sum(to_rename), "files."))
 } else {
   message("No files needed renaming.")
 }
 
 # 2. List all files (including the full path to avoid setwd)
 old_files <- list.files(path = folder_path, full.names = TRUE)
 
 # 3. Create new names: find TOMST_ followed by a SINGLE digit and an underscore
 # The ([0-9]) captures that single digit so we can put it back after a zero
 new_files <- gsub(
   pattern = "TOMST_([0-9])_", 
   replacement = "TOMST_0\\1_", 
   x = old_files
 )
 
 # 4. Filter to only rename files that actually changed
 # This ignores files that already have two digits (like TOMST_40)
 to_rename <- old_files != new_files
 
 # 5. Execute the rename
 if(any(to_rename)) {
   file.rename(from = old_files[to_rename], to = new_files[to_rename])
   message(paste("Successfully added leading zeros to", sum(to_rename), "files."))
 } else {
   message("No files needed zero-padding.")
 }
 
 #############################################################################
 folder_path <- "data/2024/"
 
 old_names <- list.files(path = folder_path, full.names = TRUE)
 
 # 2. Use gsub to replace "TOMST" with "TOMST_"
 # This looks for the literal string "TOMST" and adds the underscore
 new_names <- gsub("TOMST", "TOMST_", old_names)
 
 # 3. View the changes before applying them (optional but recommended)
 print(data.frame(Old = old_names, New = new_names))
 
 # 4. Physically rename the files
 file.rename(from = old_names, to = new_names)
 
 new_names <- gsub("_([0-9])_", "_0\\1_", old_names)
 
 # 3. Preview and Rename
 print(data.frame(Old = old_names, New = new_names))
 file.rename(from = old_names, to = new_names)
 
 files <- list.files(path = folder_path, full.names = TRUE)
 sorted_files <- sort(files)
 
 #############

 old_names <- list.files(path = folder_path, full.names = TRUE)
 
 # 2. Define the transformation
 new_names <- sapply(old_names, function(filename) {
   
   # Regex to find: Day (1-2 digits), Month (3 letters), Year (4 digits)
   # Example: "12Aug2024" -> (12)(Aug)(2024)
   pattern <- "([0-9]{1,2})([A-Za-z]{3})([0-9]{4})"
   
   # Extract matches
   matches <- regexec(pattern, filename)
   parts <- regmatches(filename, matches)[[1]]
   
   # Check if a date was found
   if (length(parts) < 4) return(filename)
   
   day <- parts[2]
   month_str <- parts[3]
   year <- parts[4]
   
   # Convert the date components into a standard Date object
   # format = "%d%b%Y" matches day, abbreviated month, and 4-digit year
   temp_date <- as.Date(paste0(day, month_str, year), format = "%d%b%Y")
   
   # Reformat the date to "YYYY_MM_DD"
   new_date_str <- format(temp_date, "%Y_%m_%d")
   
   # Replace the old date string in the filename with the new one
   gsub(pattern, new_date_str, filename)
 })
 
 # 3. Rename the files
 # Recommend: View the mapping first with data.frame(old_names, new_names)
 file.rename(from = old_names, to = new_names) 
 