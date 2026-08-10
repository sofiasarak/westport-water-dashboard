library(sf)
library(lwgeom)
library(tidyverse)
library(here)

# read in data
ssm <- read_csv(here("data", "ssm.csv")) %>% 
  drop_na(longitude, latitude) %>% 
  st_as_sf(coords = c("longitude", "latitude"),
           crs = 4326)

westport_geo <- read_sf(here("data/westport_geo"))


# transform to projected crs
ssm_proj <- st_transform(ssm, crs = 3857)
westport_geo_proj <- st_transform(westport_geo, crs = 3857)

# snap points to be directly on top of the lines
snapped <- st_snap(ssm_proj, westport_geo_proj, tolerance = 4.75)

split_result <- st_split(westport_geo_proj, snapped)  |> 
  st_collection_extract("LINESTRING") 

split_result_trial <- st_transform(split_result, crs = 4326)
st_write(split_result_trial, "data/checkpoint.geojson")

# attempt without seg_id
split_result <- st_transform(split_result, crs = 3857)
joined <- split_result %>%
  group_by(year) %>%
  group_split() %>%
  map_dfr(function(df_year) {
    yr <- unique(df_year$year)
    snapped_yr <- snapped %>% filter(year == yr)
    st_join(df_year, snapped_yr, join = st_nearest_feature)
  }) %>% 
  rename(year = year.x)

joined <- st_transform(joined, crs = 4326)

st_write(joined, "data/checkpoint3.geojson")
st_write(joined, "data/checkpoint2.geojson")

# segments <- st_sf(seg_id = seq_len(nrow(split_result)), geometry = split_result$geometry)
# 
# # get the start point of each segment
# starts <- st_line_sample(split_result$geometry, sample = 0) |> st_sfc(crs = st_crs(split_result))
# starts <- st_sf(seg_id = segments$seg_id, geometry = starts)
# 
# # join snapped points that are exactly at (or within tiny tolerance of) the segment start
# joined <- st_join(starts, snapped, join = st_is_within_distance, dist = 4.75) |> 
#   st_drop_geometry()
# 
# segments <- left_join(segments, joined, by = "seg_id")
# 
# # back to geographic crs
# segments <- st_transform(segments, crs = 4326)

st_write(segments, "data/ssm_segments.geojson")
