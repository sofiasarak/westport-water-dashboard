##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##------------------- WRANGLING WESTPORT'S RIVER GEOMETRIES---------------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Data source: deepmaps.ct.gov

# load necessary libraries
library(tidyverse)
library(here)
library(sf)

# read in geometry data
westport_geo <- read_sf(here("data", "westport_attempt1.geojson"))

# read in bacteria data
ssm <- read_csv(here("data", "ssm.csv"))
max <- read_csv(here("data", "max.csv"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                              prepare geometries                          ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# convert westport geom to smooth segments
westport_seg <- st_segmentize(westport_geo, dfMaxLength = 50)

# extract the coordinates along the entire line segment
westport_coords <- sf::st_coordinates(westport_geo) %>% as.data.frame() %>% 
  
  # convert coordinates to an sf object
  st_as_sf(coords = c("X", "Y"), crs = st_crs(westport_geo)) 

# convert ssm to sf object, with same crs as westport river geoms
ssm_sf <- ssm %>% 
  
  # st_as_sf cannot have NA coords, so remove those
  filter(!is.na(longitude), !is.na(latitude)) %>% 
  
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs(westport_geo))

# convert max to sf object, with same crs as westport river geoms
max_sf <- max %>% 
  
  # st_as_sf cannot have NA coords, so remove those
  filter(!is.na(longitude), !is.na(latitude)) %>% 
  
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs(westport_geo))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                add % exceeded ssm to each coordinate point               ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# for loop based on year
years <- unique(ssm_sf$year) # save list of years

# create empty list of dfs to combine later
dflist <- list()

for (i in 1:length(years)){
  
  # take only the rows of the df that correspond to that year
  filtered <- ssm_sf %>% filter(year == years[i])
  
  # # find the nearest sample to the midpoints; for each mid, the nearest point in ssm
  # nearest now has indices of ssm that match up to new_creek_coords
  nearest <- st_nearest_feature(westport_coords, filtered)
  
  # create temporary coords df (used for appending)
  westport_coords_temp <- westport_coords
  
  # add a column for bacteria concentration based on the index of the nearest sample site
  westport_coords_temp$percent_exceeded <- filtered$percent_exceeded[nearest]
  
  # add column for which site it corresponds to
  westport_coords_temp$site_name <- filtered$site_name[nearest]
  
  # add coordinates as columns, alongside year
  westport_coords_temp <- cbind(westport_coords_temp, st_coordinates(westport_coords_temp), year = years[i])
  
  # append the temporary coord df to the empty list
  dflist[[i]] <- westport_coords_temp
  
}

# combine list of temporary data frames into one (long format)
westport_ssm_coords <- do.call(rbind, dflist)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                do the same but with yearly max concentration             ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# for loop based on year
years <- unique(max_sf$year) # save list of years

# create empty list of dfs to combine later
dflist <- list()

for (i in 1:length(years)){
  
  # take only the rows of the df that correspond to that year
  filtered <- max_sf %>% filter(year == years[i])
  
  # # find the nearest sample to the midpoints; for each mid, the nearest point in ssm
  # nearest now has indices of ssm that match up to new_creek_coords
  nearest <- st_nearest_feature(westport_coords, filtered)
  
  # create temporary coords df (used for appending)
  westport_coords_temp <- westport_coords
  
  # add a column for bacteria concentration based on the index of the nearest sample site
  westport_coords_temp$max <- filtered$max[nearest]
  
  # add column for which site it corresponds to
  westport_coords_temp$site_name <- filtered$site_name[nearest]
  
  # add coordinates as columns, alongside year
  westport_coords_temp <- cbind(westport_coords_temp, st_coordinates(westport_coords_temp), year = years[i])
  
  # append the temporary coord df to the empty list
  dflist[[i]] <- westport_coords_temp
  
}

# combine list of temporary data frames into one (long format)
westport_max_coords <- do.call(rbind, dflist)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                           save coordinates files                         ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

st_write(westport_ssm_coords, "data/westport_ssm_coords.geojson")
st_write(westport_max_coords, "data/westport_max_coords.geojson")
