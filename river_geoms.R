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
library(nngeo)

# read in geometry data
westport_1 <- read_sf(here("data", "geoms", "westport_attempt1.geojson"))
pussy_willow <- read_sf(here("data", "geoms", "Pussy Willow.geojson"))
stony_brook_1 <- read_sf(here("data", "geoms", "Stony Brook 1.geojson"))
stony_brook_2 <- read_sf(here("data", "geoms", "Stony Brook 2.geojson"))
west_branch <- read_sf(here("data", "geoms", "West Branch Saugatuck River.geojson"))
greens_farms <- read_sf(here("data", "geoms", "Greens Farms Brook (Westport)-01.geojson"))


# read in bacteria data
ssm <- read_csv(here("data", "ssm.csv"))
max <- read_csv(here("data", "max.csv"))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                              prepare geometries                          ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# combine all geoms into one file
westport_geo <- rbind(westport_1, pussy_willow, stony_brook_1, stony_brook_2, west_branch, greens_farms)

# ensure geometry type is consistent throughout - cast to LINESTRING
westport_geo <- st_cast(westport_geo, "MULTILINESTRING")

# extract the coordinates along the entire line segment
westport_coords <- sf::st_coordinates(westport_geo) %>% as.data.frame() %>% 
  
  mutate(seq_id = row_number()) %>% 
  
  # convert coordinates to an sf object
  st_as_sf(coords = c("X", "Y"), crs = st_crs(westport_geo)) 

# convert westport_geo to project crs for nearest calculations
westport_coords <- st_transform(westport_coords, crs = 6433)

# convert ssm to sf object, with same crs as westport river geoms
ssm_sf <- ssm %>% 
  
  # st_as_sf cannot have NA coords, so remove those
  filter(!is.na(longitude), !is.na(latitude)) %>% 
  
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs(westport_coords))

# convert max to sf object, with same crs as westport river geoms
max_sf <- max %>% 
  
  # st_as_sf cannot have NA coords, so remove those
  filter(!is.na(longitude), !is.na(latitude)) %>% 
  
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs(westport_coords))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                add % exceeded ssm to each coordinate point               ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# for loop based on year
years <- unique(ssm_sf$year) # save list of years

# create empty list of dfs to combine later
dflist <- list()

filtered <- ssm_sf %>% filter(year == 2005)
nearest <- st_nn(westport_coords, filtered, maxdist = 830, k = 1, returnDist = FALSE)


for (i in 1:length(years)){
  
  # take only the rows of the df that correspond to that year
  filtered <- ssm_sf %>% filter(year == years[i])
  
  # # find the nearest sample to the midpoints; for each mid, the nearest point in ssm
  # nearest now has indices of ssm that match up to new_creek_coords
  nearest <- st_nn(westport_coords, filtered, k = 1, maxdist = 830, returnDist = FALSE, sparse = FALSE)
  
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
  nearest <- st_nn(westport_coords, filtered, k = 1, maxdist = 830, returnDist = FALSE)
  
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

# warning: these will not overwrite OLD files -- have to delete old versions first

st_write(westport_ssm_coords, "data/westport_ssm_coords.geojson")
st_write(westport_max_coords, "data/westport_max_coords.geojson")
