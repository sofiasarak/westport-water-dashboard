##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                    global (loading data and wrangling)                   ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary packages
library(tidyverse)
library(here)
library(sf)
library(shiny)
library(leaflet)
library(dplyr)
library(shinyWidgets)
library(DT)
library(plotly)
library(shinydashboard)
library(fresh)

#..........................read in data..........................
# static segments
static_segments <- read_sf(here("data", "static_segments.geojson"))

# segments w yearly data
ssm_segments <- read_sf(here("data", "ssm_segments.geojson"))

# bacteria summary (ssm)
ssm <- read_csv(here("data", "ssm.csv")) 

# all bacteria (for table)
all_westport <- read_csv(here("data", "all_westport.csv")) 

# geometries
westport_1 <- read_sf(here("data", "geoms", "westport_attempt1.geojson"))
pussy_willow <- read_sf(here("data", "geoms", "Pussy Willow.geojson"))
stony_brook_1 <- read_sf(here("data", "geoms", "Stony Brook 1.geojson"))
stony_brook_2 <- read_sf(here("data", "geoms", "Stony Brook 2.geojson"))
west_branch <- read_sf(here("data", "geoms", "West Branch Saugatuck River.geojson"))
greens_farms <- read_sf(here("data", "geoms", "Greens Farms Brook (Westport)-01.geojson"))


# read in sampling years
sampling_years <- read_csv(here("data", "westport_sampling_years.csv"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                              prepare geometries                          ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# combine all geoms into one file
westport_geo <- rbind(westport_1, pussy_willow, stony_brook_1, stony_brook_2, west_branch, greens_farms)

# ensure geometry type is consistent throughout - cast to LINESTRING
westport_geo <- st_cast(westport_geo, "MULTILINESTRING")

#........add variable denoting which river geo belongs to........

westport_geo <- westport_geo %>% 
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

#......................join sampling years.......................

westport_geo <- sampling_years %>% 
  
  # join on river name
  left_join(westport_geo, by = c("river" = "river_name"),
            relationship = "many-to-many") %>% 
  
  st_as_sf()

# remove geometyr "names" -- necessary for plotting 
names(st_geometry(westport_geo)) = NULL


#...................create sampling site order...................
site_order <- list(
  
  # most leftmost site will show up on TOP of table
  "Indian River" = c("Indian 3.1", "Indian 3", "Indian 2", "Indian 1.75", "Indian 1.5", "Indian 1"),
  "Saugatuck River" = c("West Saug 1.5", "West Saug 1", "Saugatuck 2", "Saugatuck 1", "SG1", "Saugatuck 0.75", "Saugatuck 0.5", "Saugatuck 0.25", "Poplar 4", "Poplar 3", "Poplar 2", "Poplar 1.5", "Poplar 1"),
  "Pussy Willow Brook" = c("Pussy Willow 5", "Pussy Willow 4", "Pussy Willow 3", "Pussy Willow 2.5", "Pussy Willow 2", "Pussy Willow 1", "Lamplight 1"),
  "Muddy Brook" = c("Muddy 6", "Muddy 5", "Muddy 4", "Muddy 3", "Muddy 2", "Muddy 1"),
  "Sasco Brook" = c("Sasco 9", "Hunt Club 5", "Hunt Club 4", "Hunt Club 3", "Hunt Club 2", "Hunt Club 1", "Sasco 8", "Sasco 7", "Sasco 6", "Sasco 5", "Sasco 4", "Sasco 3", "Sasco 2", "Sasco 1"),
  "Deadman Brook" = c("Deadman 9", "Deadman 8", "Deadman 7.3", "Deadman 7.1", "Deadman 7", "Deadman 6", "Deadman 5", "Deadman 4", "Deadman 3.5", "Deadman 3", "Deadman 2", "Deadman 1", 'Deadman 0.5'),
  "Greens Farms Brook" = c("New 4", "New 3", "New 2", "New 1.5", "New 1", "New 0.5"),
  "Stony Brook" = c("Stony 5", "Stony 4", "Stony 3", "Stony 2", "Stony 1", "Stony 1.5")
)
