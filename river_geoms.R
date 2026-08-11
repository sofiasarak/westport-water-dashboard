library(tidyverse)
library(here)
library(sf)
library(nngeo)

# Data source: deepmaps.ct.gov

# read in geometry data
westport_1 <- read_sf(here("data", "geoms", "westport_attempt1.geojson"))
pussy_willow <- read_sf(here("data", "geoms", "Pussy Willow.geojson"))
stony_brook_1 <- read_sf(here("data", "geoms", "Stony Brook 1.geojson"))
stony_brook_2 <- read_sf(here("data", "geoms", "Stony Brook 2.geojson"))
west_branch <- read_sf(here("data", "geoms", "West Branch Saugatuck River.geojson"))
greens_farms <- read_sf(here("data", "geoms", "Greens Farms Brook (Westport)-01.geojson"))

# read in sampling years
sampling_years <- read_csv(here("data", "westport_sampling_years.csv"))

#.......................prepare geometries.......................

# combine all geoms into one file
westport_geo <- rbind(westport_1, pussy_willow, stony_brook_1, stony_brook_2, west_branch, greens_farms)

# ensure geometry type is consistent throughout - cast to LINESTRING
westport_geo <- st_cast(westport_geo, "MULTILINESTRING")

#........add variable denoting which river geo belongs to........

# this fixes discrepeancy between geometries names and sampling names

westport_geo <- westport_geo %>% 
  
  # add new river_name column
  mutate(river_name = case_when(
    
    # indian river
    ASSESSMENT_UNIT_NAME %in% c("Indian River (Westport)-01","Indian River (Westport)-02") ~ "Indian River",
    
    # saugatuck
    ASSESSMENT_UNIT_NAME %in% c("Poplar Plains Brook (Westport)-01", "Aspetuck River (Westport-Easton)-01","Saugatuck River (Westport)-01", "West Branch Saugatuck River (Westport/Weston)-01") ~ "Saugatuck River",
    
    # pussy willow
    ASSESSMENT_UNIT_NAME == "Unnamed tributary Sherwood Millpond LIS (Westport)-01" ~ "Pussy Willow Brook",
    
    # muddy 
    ASSESSMENT_UNIT_NAME == "Muddy Brook (Westport)-01" ~ "Muddy Brook",
    
    #sasco
    ASSESSMENT_UNIT_NAME %in% c("Sasco Brook (Westport/Fairfield)-01",  "Sasco Brook (Westport/Fairfield)-02") ~ "Sasco Brook",
    
    # deadman
    ASSESSMENT_UNIT_NAME == "Deadman Brook (Westport/Fairfield)-01" ~ "Deadman Brook",
    
    # greens farms/new
    ASSESSMENT_UNIT_NAME == "Greens Farms Brook (Westport)-01" ~ "Greens Farms Brook",
    
    # stony
    ASSESSMENT_UNIT_NAME %in% c("Stony Brook (Westport)-01", "Stony Brook (Westport/Norwalk/Wilton)-02") ~ "Stony Brook",
    
    .default = NA
  ))

st_write(westport_geo, "data/static_segments.geojson")

#......................join sampling years.......................

westport_geo <- sampling_years %>% 
  
  # join on river name
  left_join(westport_geo, by = c("river" = "river_name"),
            
            # ensures that geometries repeat for each year that river was sampled
            relationship = "many-to-many") %>% 
  
  st_as_sf()

names(st_geometry(westport_geo)) = NULL

# save complete westport as geo
st_write(westport_geo, "data/westport_geo.geojson")