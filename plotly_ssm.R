##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##---------------------------- RUNNING PLOTLY MAP-------------------------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary libraries
library(tidyverse)
library(here)
library(plotly)
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
  
  filter(!is.na(longitude), !is.na(latitude), !is.na(percent_exceeded))


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                        manual color scale for lines                      ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(plotly)
library(scales)

# 1. Define your exact 3-point Red-Yellow-Green scale to match your markers
# (Matches the "RdYlGn" palette format you built)
ryg_palette <- c("#a50026", "#ffffbf", "#006837")

# 2. Build a mapping function locked to your global data range (stops dynamic re-scaling)
color_mapper <- col_numeric(
  palette = ryg_palette, 
  domain = range(westport_geo$percent_exceeded, na.rm = TRUE) # Keeps scale locked globally
)

# 3. Create a static character column holding the literal color string
westport_geo$line_color_hex <- color_mapper(westport_geo$percent_exceeded)


# 4. Pass the calculated column using the As-Is 'I()' function in Plotly



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                    plot                                  ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# initialize plotly
plot <- plot_ly()

## RIVER GEO (LINE)

# plot <- plot %>%
#   add_trace(data = westport_geo,
#             lat = ~Y, lon = ~X,
#             split = ~L2, # treats segments differently based on the site they correspond to (can also try L1)
#             frame = ~year,
#             color = ~percent_exceeded, # color by perc site exceeded ssm
#             type = "scattermapbox", mode = "lines",
#             line = list(width = 3), # adjust width
#             showlegend = FALSE, hoverinfo = "skip",
#             showscale = FALSE) # tried to get rid of second "percent_exceeded" - might have to make static legend


plot <- plot %>% 
  add_trace(
    data = westport_geo_df, 
    lat = ~Y, 
    lon = ~X, 
    #split = ~L2, 
    frame = ~year, 
    type = "scattermapbox", 
    mode = "markers", 
    marker = list(
      color = ~percent_exceeded,
      colorscale = list(
      list(0, "rgb(165,0,38)"),      # 0% min value (Dark Red)
      list(0.5, "rgb(255,255,191)"),  # 50% midpoint (Yellow)
      list(1, "rgb(0,104,55)")       # 100% max value (Dark Green)
    ), 
    cauto = FALSE, 
    cmin = min(westport_geo_df$percent_exceeded, na.rm = TRUE), 
    cmax = max(westport_geo_df$percent_exceeded, na.rm = TRUE), 
    showscale = TRUE),
    
    showlegend = FALSE, 
    hoverinfo = "skip"
  )

## LAYER 2: OUTLINE POINTS
plot <- plot |> add_trace(
  data = ssm, 
  lat = ~latitude, 
  lon = ~longitude, 
  frame = ~year, 
  type = "scattermapbox", 
  mode = "markers", 
  marker = list(
    size = 15, 
    color = "DarkSlateGrey"    # Protected by I() to prevent grouping corruption
  ), 
  showlegend = FALSE,
  hoverinfo = "skip"
)

## LAYER 3: SAMPLING POINTS (With Continuous Color Map Matrix)
plot <- plot |> add_trace(
  data = ssm, 
  lat = ~latitude, 
  lon = ~longitude, 
  frame = ~year, 
  type = "scattermapbox", 
  mode = "markers", 
  
  marker = list(
    size = 11, 
    color = ~percent_exceeded, 
    colorscale = list(
      list(0, "rgb(165,0,38)"),      # 0% min value (Dark Red)
      list(0.5, "rgb(255,255,191)"),  # 50% midpoint (Yellow)
      list(1, "rgb(0,104,55)")       # 100% max value (Dark Green)
    ), 
    cauto = FALSE, 
    cmin = min(ssm$percent_exceeded, na.rm = TRUE), 
    cmax = max(ssm$percent_exceeded, na.rm = TRUE), 
    showscale = TRUE 
  ), 
  text = ~paste0("<b>", site_name, "</b><br>% Exceeded SSM: ", round(percent_exceeded, 2) * 100, "%"), 
  hoverinfo = "text", 
  showlegend = FALSE
)



# legend
# for (lvl in 1:10) {
#   plot <- plot |>
#     add_trace(lat = 0, lon = 0, type = "scattermapbox", mode = "markers",
#               marker = list(size = 14, color = ~percent_exceeded, colors = "Reds"),
#               name = as.character(lvl), showlegend = TRUE, hoverinfo = "skip")
# }

## BACKGROUND, BASEMAP

plot <- plot %>% 
  layout(
    title = "Westport: % of Times SSM was Exceeded",
    
    # add plot spacing
    margin = list(
      t = 150,  
      b = 50,  
      l = 50,   
      r = 50   
    ),
    
    # set basemap, initial zoom
    mapbox = list(
      style = "carto-positron", # original basemap was "open-street-map"
      center = list(lat = 41.12076, lon = -73.3151),
      zoom = 13
    ),
    
    # background color and font color
    paper_bgcolor = "white",
    font = list(color = "black")
  ) %>% 
  
  # changes speed of animation when "play" is hit
  animation_opts(frame = 500)

# call plot
plot

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                  attempt                                 ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Correctly split and reconstruct the data frame with safe NA structural breaks
westport_geo_clean <- westport_geo %>%
  group_split(year, L2) %>%
  map_df(~ {
    # Keep the original segment rows, then append an explicit NA row at the tail end
    # containing the identical time frame so it does not drop out of the canvas engine
    bind_rows(.x, tibble(
      Y = NA_real_, 
      X = NA_real_, 
      year = unique(.x$year), 
      line_color_hex = unique(.x$line_color_hex)
    ))
  })

plot <- plot_ly()

## LAYER 1: GEOGRAPHIC LINES
plot <- plot %>% add_trace(
  data = westport_geo_clean,      # Fully preserved coordinate rows
  lat = ~Y, 
  lon = ~X, 
  frame = ~year, 
  type = "scattermapbox", 
  mode = "lines", 
  connectgaps = FALSE,            # Separates L2 segments without using split=~L2
  
  line = list(
    width = 3,
    color = ~I(line_color_hex)    # R-mapped hex palette colors safely apply now
  ), 
  showlegend = FALSE, 
  hoverinfo = "skip"
)

## LAYER 2: OUTLINE POINTS
plot <- plot |> add_trace(
  data = ssm, 
  lat = ~latitude, 
  lon = ~longitude, 
  frame = ~year, 
  type = "scattermapbox", 
  mode = "markers", 
  marker = list(
    size = 15, 
    color = I("DarkSlateGrey")    # Protected by I() to prevent grouping corruption
  ), 
  showlegend = FALSE,
  hoverinfo = "skip"
)

## LAYER 3: SAMPLING POINTS (With Continuous Color Map Matrix)
plot <- plot |> add_trace(
  data = ssm, 
  lat = ~latitude, 
  lon = ~longitude, 
  frame = ~year, 
  type = "scattermapbox", 
  mode = "markers", 
  
  marker = list(
    size = 11, 
    color = ~percent_exceeded, 
    colorscale = list(
      list(0, "rgb(165,0,38)"),      # 0% min value (Dark Red)
      list(0.5, "rgb(255,255,191)"),  # 50% midpoint (Yellow)
      list(1, "rgb(0,104,55)")       # 100% max value (Dark Green)
    ), 
    cauto = FALSE, 
    cmin = min(ssm$percent_exceeded, na.rm = TRUE), 
    cmax = max(ssm$percent_exceeded, na.rm = TRUE), 
    showscale = TRUE 
  ), 
  text = ~paste0("<b>", site_name, "</b><br>% Exceeded SSM: ", round(percent_exceeded, 2) * 100, "%"), 
  hoverinfo = "text", 
  showlegend = FALSE
)

plot
