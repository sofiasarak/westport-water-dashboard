##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                              Back to Leaflet                             ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary libraries
library(tidyverse)
library(here)
library(leaflet)
library(sf)

# read in ssm data
ssm <- read_csv(here("data", "ssm.csv")) 

# read in river geometry data
westport_geo <- read_sf(here("data", "westport_ssm_coords.geojson"))  %>% 
  
  # arrange by row id
  arrange(seq_id)

# remove geometries
westport_geo_df <- sf::st_drop_geometry(westport_geo)

# drop rows with NA longitudes, latitudes, and percent_exceeded
ssm <- ssm %>% 
  
  filter(!is.na(longitude), !is.na(latitude), !is.na(percent_exceeded)) %>% 
  
  # create geometry object
  st_as_sf(coords = c("latitude", "longitude"))


#..............................plot..............................

pal <- colorFactor(
  palette = c("blue", "red"), 
  domain = ssm$percent_exceeded
)

leaflet() %>%
  addTiles() %>%
  
  # set default zoom to New 1.5 sampling site
  setView(lng = -73.3151, lat = 41.12076, zoom = 13.4) %>% 
  
  addPolylines(data = westport_geo) %>% 
  
  # add new creek polygon
  addCircleMarkers(data = ssm,
             lng = ~longitude,
             lat = ~latitude,
             color = ~pal(percent_exceeded),       
             fillColor = ~pal(percent_exceeded)) 
  
  