##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                server/backend (filtering data and plotting)              ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

server <- function(input, output, session) {
  
  # create palette that matches up with percent_exceeded
  pal <- colorNumeric(palette = c("forestgreen", "red"), domain = c(0, 1)) 
  
  #..........filter data based on slider/dropdown choices..........
  
  # ssm --
  filtered_leaflet_df_ssm <- reactive({
    
    df <- ssm
    
    # year
    if (length(input$year) > 0)
      df <- df %>% filter(year == input$year)
    
    # stream name
    if(length(input$river_name) > 0)
      df<- df %>% filter(river_name %in% input$river_name)
    
    df
    
  }) # end reactive ssm df
  
  
  # river geometries --
  filtered_leaflet_geos <- reactive({
    
    df_geos <- ssm_segments
    
    # year
    if(length(input$year) > 0)
      df_geos <- df_geos %>% filter(year == input$year)
    
    # stream name
    if(length(input$river_name) > 0)
      df_geos <- df_geos %>% filter(river %in% input$river_name)
    
    df_geos
    
  }) # end reactive stream geos
  
  
  # river table --
  filtered_table_df <- reactive({
    
    df_all <- all_westport
    
    # year
    if(length(input$year) > 0)
      df_all <- df_all %>% filter(year == input$year)
    
    df_all
    
  }) # end reactive df for river table

  
  #............................basemap.............................
  
  output$map <- renderLeaflet({
    
    leaflet() %>%
      
      addProviderTiles(providers$CartoDB.Positron) %>%
      
      # set initial zoom
      setView(lng = -73.33419, lat = 41.16502, zoom = 12) 
    
  })
  
  # add filtered points ---
  observe({
    
    df <- filtered_leaflet_df_ssm()
    
    leafletProxy("map", data = df) %>%
      
      clearMarkers() %>%    # remove old markers when new selection made
      
      clearControls() %>%   # remove old legend before adding new one
      
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        layerId = ~site_name,   # unique per marker, ensures proper plotting
        color = ~pal(percent_exceeded),
        fillColor = ~pal(percent_exceeded),
        
        # shows sampling site name and % exceeded when clicked on
        popup = ~paste0("<strong>", site_name,"</strong> <br>SSM exceeded: ", round(percent_exceeded * 100), "% of the time")
      ) %>% 
      
      # add legend
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~percent_exceeded,
        title = "% Exceeded",
        
        # label format: multiplies by 100 and adds % suffix
        labFormat = labelFormat(suffix = "%", transform = function(x) x * 100) 
      )
    
    #......................add river geometries......................
    
    df_geos <- filtered_leaflet_geos()
    
    leafletProxy("map", data = df_geos) %>%
      
      clearShapes() %>%  # remove old lines
      
      addPolylines(popup = ~river, # show river name when clicked
                   color = ~pal(percent_exceeded)) 
  })
  
  
  #...........set up clicked output to match river name (for table) ...........
  
  clicked_river <- reactive({
    d <- input$map_marker_click  # or _shape_click if using polylines
    req(d)
    
    # look up river_name from the site that was clicked
    df <- filtered_leaflet_df_ssm()
    df$river_name[df$site_name == d$id][1] # layerId comes back as $id
  })
  
  
  #..........................river table...........................
  
  output$table <- renderDT({
    req(clicked_river())
    
    # reassign filtered df
    all_westport <- filtered_table_df()
    
    # pivot to table format (dates in columns, sites in rows)
    all_westport <- all_westport %>% 
      
      # remove date column
      select(-date) %>% 
      
      # pivot so that each column is a date
      pivot_wider(names_from = date_no_year, values_from = conc, 
                
                # collapse concentrations from same site, same day to mean
                values_fn = mean)
    
    table_data <- # select data just for that river
      all_westport[all_westport$river_name == clicked_river(), ] %>% 
      
      # remove river name and year once filtered for -- displayed in header instead
      select(-c(river_name, year))  %>% 
      
      # remove columns that are entirely NA
      select(where(~ !all(is.na(.)))) %>% 
      
      # order date columns numerically
      select(site_name, indicator, sort(names(.)[-c(1,2)])) %>% 
      
      # clean up header names
      rename("Sampling\nSite" = site_name,
             "Indicator" = indicator) %>% 
      
      # change date formatting (from 05-08 to 5/08)
      rename_with(~ str_replace(., "^0(\\d+)-", "\\1/"), .cols = -(1:2))
    
    # initialize table
    datatable(
      
      table_data,
      
      # table details
      rownames = FALSE, # remove row numbers
      width = "100%",
      options = list(scrollX = TRUE, # scroll to see additional columns
                     pageLength = 15,  # removes need to click onto other page to see all sites
                     dom = 'rtip', # remove search bar and length dropdown
                     
                     # code to color table data conditionally, based on if SSM is exceeded
                     rowCallback = JS(sprintf(
                       "function(row, data) {
    var dateCols = [%s];
    var indicator = data[1];
    var threshold = indicator === 'e.coli' ? 126 : 35;
    dateCols.forEach(function(i) {
      var val = parseFloat(data[i]);
      if (val > threshold) $('td:eq(' + i + ')', row).css('color', 'red');
    });
  }",
                       paste((3:ncol(table_data)) - 1, collapse = ",")
                     ))) 
     
                     ) 
  })

  #................add river and year heading based on click and year...............
  
  # river and year label heading 
  output$table_heading <- renderText({
    req(clicked_river()) # sourced from point that is clicked
    paste0(clicked_river(),", ", input$year)
  }) 
  
} # end server function