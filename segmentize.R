library(sf)
library(lwgeom)
library(tidyverse)


# transform to projected crs
ssm_proj <- st_transform(ssm, crs = 3857)
westport_geo_proj <- st_transform(westport_geo, crs = 3857)

# snap points to be directly on top of the lines
snapped <- st_snap(ssm_proj, westport_geo_proj, tolerance = 0.5)

split_result <- st_split(westport_geo_proj, snapped) |> 
  st_collection_extract("LINESTRING")

# assign ssm value

segments <- st_sf(seg_id = seq_len(nrow(split_result)), geometry = split_result$geometry)

# get 0.4-points (for upstream matching) of each segment for matching
mids <- st_line_sample(split_result, sample = 0.4) |> st_cast("POINT")
mids <- st_sf(seg_id = segments$seg_id, geometry = mids)

# join nearest point's attributes onto each segment
joined <- st_join(mids, ssm_proj, join = st_nearest_feature) |> st_drop_geometry()

segments <- left_join(segments, joined, by = "seg_id")

# back to geographic crs
segments <- st_transform(segments, crs = 4326)

st_write(segments, "data/ssm_segments.geojson")
