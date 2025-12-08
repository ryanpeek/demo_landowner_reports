# quarto render!
# Render all reports at once based on a list of property names

# Libraries ---------------------------------------------------------------

library(tidyverse)
library(janitor)
library(glue)
library(readxl)
library(sf)
library(quarto)

# Set Parameters ----------------------------------------------------------

year_sel <- 2024

## Landowner Metadata ---------------------------------------------------------------


meta_landowner <- read_csv("data/meta_landowner_example.csv") |>
  clean_names() |>
  filter(year==year_sel)

# make a clean owner list
owner_clean <- meta_landowner |> select(owner) |>
  distinct() |>
  mutate(owner_clean = make_clean_names(owner), .after="owner")

# join back
meta_landowner <- meta_landowner |> left_join(owner_clean) |> relocate(owner_clean, .after=owner)

# make an alphabetical list of clean landowner names
landowner_uniq <- sort(unique(meta_landowner$owner_clean))

## Site Metadata ----------------------------------------------------------

# need to check how many properties have multiple sites:
lo_sites <- read_csv("data/site_locations_example.csv") |>
  st_as_sf(coords=c("longitude", "latitude"), crs=4326, remove=FALSE) |>
  filter(year==2024) |>
  mutate(site_id_rev = coalesce(site_id_new, site_id), .after=site_id)

# join back to landowners to better evaluate
meta_landowner_sf <- left_join(meta_landowner,
                               lo_sites |>
                                 select(-c(year, private_data, private_data_agreement)),
                               by="site_id")

# how many owners have multiple sites?
meta_landowner_sf |> group_by(site, site_id, huc12_name, owner_clean) |>
  tally() |> filter(n>1) #|> View()

# how many owners have multiple watersheds?
meta_landowner_sf |> select(owner_clean, huc12_name, site) |>
   distinct() |>
   group_by(owner_clean) |> tally() |> arrange(desc(n)) |>  filter(n>1) #|>  View()

# These all will need to be dealt with differently because the span multiple watersheds (so either we drop the map from these, or we create different report for each watershed/owner)

# Make Landowner List to Run ----------------------------------------------

# shrink list to process single watersheds
(landowners_sel <- owner_clean |>
   arrange(owner_clean) |>
   # remove the multiple watersheds
   filter(!owner_clean %in%
            c("blm_ukiah_office",
              "california_department_of_parks_and_recreation",
              "tahoe_national_forest_usfs")
          ))

# Render Single -----------------------------------------------------------

# use this to test and make sure this works for one single report
# can also use to rerun just a single report if needed

landowners_sel$owner_clean # check existing list for spelling/punctuation
lo_sel <- "uc_sagehen_reserve"
doc_type <- "html"

# render single watershed
quarto::quarto_render(
  input = "cemaf_annual_report_template.qmd",
  output_format = doc_type,
  output_file = glue("cemaf_terrestrial_report_{lo_sel}_{year_sel}"),
  execute_params = list(
    landowner = glue("{lo_sel}")))

# Render All: --------------------------------------------------------

# make a big list (example here is duplicated but you get idea)
landowners_all <- bind_rows(landowners_sel, landowners_sel, landowners_sel)

# loop through
for (i in 1:nrow(landowners_all)) {
  landowner <- landowners_all[i,] # Each row is a unique landowner
  # use the various pieces
  quarto::quarto_render(
    # input is the template or qmd file used to make the reports
    input = "cemaf_annual_report_template.qmd",
    # add a timestamp to every file so it's unique no matter what
    output_file = glue("cemaf_terrestrial_report_{landowner$owner_clean}_{year_sel}_{format(Sys.time(), '%H%M%S')}"),
    # this is where the individual landowner names are used
    execute_params = list(
      landowner = landowner$owner_clean
    )
  )
}

# note! this will make all the formats that are specified in the template yaml header!
# so if you have docx, pdf, and html all uncommented, we would get all three for each
# property/landowner name.
