# clean jfif to jpg
# Commonly we may save photos in a "jfif" format
# This can sometimes cause issues during the knitting stage, even though
# jfif is equivalent to jpg. The easy fix is simply to rename all jfif to jpg.

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(glue)
library(janitor)
library(fs)

## Set Paths
username <- Sys.getenv("USERNAME")
drive <- r'(C:\Users\)'
onedrive <- r'(OneDrive - California Department of Fish and Wildlife\)'
year_sel <- 2024
# check what your One Drive Terrestrial path
cemaf <- "Terrestrial"

# create path to database location:
dat_path <- glue("{drive}/{username}/{onedrive}/{cemaf}/Data/")

# path to photos
photo_dir <- glue("{drive}/{username}/{onedrive}/{cemaf}/Landowner_reports/{year_sel}/Landowner_data/")

# full photo paths
photo_paths <- dir_ls(path = glue("{photo_dir}/"), recurse = TRUE, type = "file")

# just the filenames (easier to view)
photo_filenames <- fs::path_file(photo_paths)

# filter to any that have "jfif"
ph_jfif <- grepl("jfif$", photo_paths)

photo_paths_to_fix <- photo_paths[ph_jfif]
photo_filenames_to_fix <- fs::path_file(photo_paths_to_fix)

# gsub out jfif with jpg
photo_paths_fixed <- gsub("jfif$", "jpg", photo_paths_to_fix, ignore.case = TRUE)
(photo_filenames_fixed <- fs::path_file(photo_paths_fixed))

# rename in place
fs::file_move(path = photo_paths_to_fix, new_path = photo_paths_fixed)
