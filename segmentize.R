library(sf)
library(lwgeom)
library(tidyverse)
library(here)

# read in data
ssm <- read_csv(here("data", "ssm.csv")) %>% 
  
  # remove any points where geometry is NA
  drop_na(longitude, latitude) %>% 
  st_as_sf(coords = c("longitude", "latitude"),
           crs = 4326)

westport_geo <- read_sf(here("data/westport_geo.geojson"))

#........................create segments.........................

# transform to projected crs
ssm_proj <- st_transform(ssm, crs = 3857)
westport_geo_proj <- st_transform(westport_geo, crs = 3857)

# snap ssm points to be directly on top of the lines
snapped <- st_snap(ssm_proj, westport_geo_proj, tolerance = 4.75) # this tolerance captures all of them

# extract line strings from result
split_result <- st_split(westport_geo_proj, snapped)  |> 
  st_collection_extract("LINESTRING") 

#.................add ssm values to each segment.................

# make sure segments are in projected crs
split_result <- st_transform(split_result, crs = 3857)

# join ssm values with segments
joined <- split_result %>%
  
  # group by year so that ssm values are accurate to each year
  group_by(year) %>%
  group_split() %>%
  
  # iterate over each year
  map_dfr(function(df_year) {
    yr <- unique(df_year$year) # list of unique years
    
    # filter for each year
    snapped_yr <- snapped %>% filter(year == yr)
    
    # join(based on nearest geometry) the ssm points to river geos, from each year
    st_join(df_year, snapped_yr, join = st_nearest_feature)
  }) %>% 
  
  # join produces column name discrepancy, so replace
  rename(year = year.x)

# switch back to geographic crs, which leaflet requires
joined <- st_transform(joined, crs = 4326)

# save file
st_write(joined, "data/ssm_segments.geojson")
