##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##---------------------------- RUNNING PLOTLY MAP-------------------------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary libraries
library(tidyverse)
library(here)
library(plotly)

# read in ssm data
ssm <- read_csv(here("data", "ssm.csv"))

# read in river geometry data
westport_geo <- read_sf(here("data", "westport_ssm_coords.geojson"))  %>% 
  
  # arrange by row id
  arrange(seq_id)

# drop rows with NA longitudes, latitudes, and percent_exceeded
ssm <- ssm %>% 
  
  filter(!is.na(longitude), !is.na(latitude), !is.na(percent_exceeded))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                    plot                                  ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# initialize plotly
plot <- plot_ly()

## RIVER GEO (LINE)

plot <- plot %>%
  add_trace(data = westport_geo,
            lat = ~Y, lon = ~X,
            split = ~L2, # treats segments differently based on the site they correspond to
            frame = ~year,
            color = ~percent_exceeded, # color by perc site exceeded ssm
            type = "scattermapbox", mode = "lines",
            line = list(width = 3), # adjust width
            showlegend = FALSE, hoverinfo = "skip",
            showscale = FALSE) # tried to get rid of second "percent_exceeded" - might have to make static legend

## OUTLINE POINTS 
# add dark gray outline to markers

plot <- plot |>
  add_trace(data = ssm, lat = ~latitude, lon = ~longitude, frame = ~year,
            type = "scattermapbox", mode = "markers",
            marker = list(size = 18, color = "DarkSlateGrey"),
            showlegend = FALSE)

## SAMPLING POINTS
# add markers that change color based on perc exceeded (similar to lines)

plot <- plot |>
  add_trace(data = ssm, lat = ~latitude, lon = ~longitude, frame = ~year,
            type = "scattermapbox", mode = "markers",
            color = ~percent_exceeded,
            colors = colorRamp(c("white", "darkred")), # colormap does not work :(
            marker = list(size = 14),
            
            # add hover
            text = ~paste0("<b>", site_name, "</b><br>% Exceeded SSM: ", percent_exceeded),
            hoverinfo = "text", showlegend = FALSE)


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
      style = "open-street-map",
      center = list(lat = 41.12076, lon = -73.3151),
      zoom = 13
    ),
    
    # background color and font color
    paper_bgcolor = "white",
    font = list(color = "black")
  ) %>% 
  
  # changes speed of animation when "play" is hit
  animation_opts(frame = 1000)

# call plot
plot
