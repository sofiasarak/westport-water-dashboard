##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                server/backend (filtering data and plotting)              ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

server <- function(input, output, session) {
  
  # create palette that matches up with percent_exceeded
  pal <- colorFactor(
    palette = c("blue", "red"), 
    domain = ssm$percent_exceeded
  )
  
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
    
    df_geos <- westport_geo
    
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
  
  # # river conc test
  # filtered_leaflet_geos <- reactive({
  #   
  #   df_geos <- river_conc_test
  #   
  #   # year
  #   if(length(input$year) > 0)
  #     df_geos <- df_geos %>% filter(year == input$year)
  #   
  #   # stream name
  #   if(length(input$river_name) > 0)
  #     df_geos <- df_geos %>% filter(river %in% input$river_name)
  #   
  #   df_geos
  # })
  
  #............................basemap.............................
  
  output$map <- renderLeaflet({
    leaflet() %>%
      
      
      addProviderTiles(providers$CartoDB.Positron) %>%
      
      # set initial zoom
      setView(lng = -73.3151, lat = 41.12076, zoom = 13) 
    
    #addLegend("bottomright", pal = pal, values = pal_range, title = "% Exceeded SSM",
    # labFormat = labelFormat(suffix = "%", transform = function(x) x * 100))
  })
  
  # add filtered points ---
  observe({
    
    df <- filtered_leaflet_df_ssm()
    
    leafletProxy("map", data = df) %>%
      
      clearMarkers() %>%    # remove old markers when new selection made
      
      addCircleMarkers(
        lng = ~longitude,
        lat = ~latitude,
        layerId = ~site_name,   # unique per marker
        color = ~pal(percent_exceeded),
        fillColor = ~pal(percent_exceeded),
        popup = ~paste0("<strong>", site_name,"</strong> <br>SSM exceeded: ", round(percent_exceeded * 100), "% of the time")
      ) # popup when hovered over %>% 
    
    df_geos <- filtered_leaflet_geos()
    
    leafletProxy("map", data = df_geos) %>%
      
      clearShapes() %>%  # remove old lines
      
      addPolylines(popup = ~ASSESSMENT_UNIT_NAME)
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
      
      select(-date) %>% 
      
      pivot_wider(names_from = date_no_year, values_from = conc, 
                
                # collapse concentrations from same site, same day to mean
                values_fn = mean)
    
    # initialize table
    datatable(
      
      # select data just for that river
      all_westport[all_westport$river_name == clicked_river(), ] %>% 
        
        select(-c(river_name, year))  %>% 
        
        # remove columns that are entirely NA
        select(where(~ !all(is.na(.)))) ,
      
      # table details
      rownames = FALSE, 
      options = list(pageLength = 9, 
                     dom = 'rtip' # remove search bar and length dropdown
                     
                     # use CSS to assign table header the sector color 
                     ))
  })

  #................add river and year heading based on click and year...............
  
  # sector label heading 
  output$table_heading <- renderText({
    req(clicked_river())
    paste0(clicked_river(),", ", input$year)
  }) 
  
} # end server function