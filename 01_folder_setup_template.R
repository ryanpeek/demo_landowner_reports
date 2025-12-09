# This code sets up the folders required for parameterized reports.
# This code simulates names to be used, but assumes a spreadsheet containing:
## FirstName LastName
## PropertyName

## This can be formatted in whatever way works, but should be standardized
## and consistent! These names will be used to generate directories so avoid spaces or punctuation and use consistent formats (i.e., firstname_lastname, usfs_forestname_region, ucd_reservename)

# Library -----------------------------------------------------------------

library(tidyverse)
library(glue)
library(fs)
library(readxl)
library(janitor)
library(purrr)

# Set Paths ---------------------------------------------------------------

# This is an approach to consistently build a path
# to work on multiple users computers (AVOID using setwd() )
userhome <- fs::path_home()
onedrive <- r'(OneDrive - California Department of Fish and Wildlife\)'
cemaf <- "Terrestrial"
yr <- "2025"

# out path: where you want to create the directories
out_path <- glue("photos/{yr}/")

# we can then "glue" the pieces above together to make a working path
#data_path <- glue("{userhome}/{onedrive}/{cemaf}/Landowner_reports/{yr}/")

# THIS IS HOW WE READ IN VIA CEMAF: ------------------

## Read in Metadata

# if metadata lives in a csv or an xlsx spreadsheet, read it in here
meta <- read_csv(glue("data/meta_landowner_example.csv")) |>
  # this formats the column names to make things easier to access
  clean_names()

## Get Distinct Landowner Names
# make a directory name for each owner with subfolders SA and ML
owner_dir_names <- meta |> select(owner) |>
  filter(!is.na(owner)) |>
  arrange(owner) |>
  distinct(.keep_all = TRUE) |>
  mutate(owner_clean = make_clean_names(owner), .after="owner") |>
  select(owner_clean) |> simplify()

# MAKE LIST OF NAMES TO USE ---------------------------

## Example Using Fake Names ---------------------------

# use the randomNames package: install.packages("randomNames")
fake_names <- randomNames::randomNames(10, name.order = "first.last")

# clean spaces for dir naming:
fake_names <- gsub(", ", "_", fake_names)

# make sure they are distinct
owner_dir_names <- fake_names |> sort() |> unique()
owner_dir_names

# Make Directories --------------------------------------------------------

# this is what we use to create a landowner folder for photos
dir_create(glue("{out_path}/{owner_dir_names}"))

# within each one, create "SA" and "ML"
map(owner_dir_names, ~fs::dir_create(c(glue("{out_path}/{.x}/SA"), glue("{out_path}/{.x}/ML"))))

# Check Directories -------------------------------------------------------

# if they are setup already or want to check existing:
# get at tree view of folders
dir_tree(glue("{out_path}/"), type = "directory")

# make a list out dir only
folders <- dir_ls(glue("{out_path}/"), recurse = FALSE, type = "directory")


# Get a Count of Photos per Folder ----------------------------------------

# match names with meta names
owners <- as_tibble(sort(basename(folders)))

owners$value == owner_dir_names # should all be TRUE

# get count of files in each
(photo_counts <- tibble(folders = dir_ls(glue("{out_path}/"), recurse = TRUE, type="directory"))  |>
  rowwise() |>
  mutate(
    subdir = basename(folders),
    n = dir(folders) %>% length) |>
  filter(!subdir %in% owners$value) |>
  mutate(
    owner_name = basename(path_dir(path = folders)), .after=folders) |>
  select(-folders))

# write_csv for easy view
#write_csv(photo_counts, file = glue("{out_path}/photo_counts_per_landowner_{gsub('-', '', Sys.Date())}.csv"))
