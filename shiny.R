library(shiny)
library(leaflet)
library(dplyr)
library(shinyWidgets)

years <- sort(unique(ssm$year))

ui <- fluidPage(
  
  # title
  titlePanel("Westport: % of Times SSM was Exceeded"),
  
  # slider to choose year
  sliderInput("year", "Year", min = min(years), max = max(years),
              value = min(years), step = 1, sep = "", animate = animationOptions(interval = 500)),
  
  # dropdown to choose river
  pickerInput(
    inputId  = "river_name",
    label    = "Select Westport Stream",
    choices  = unique(westport_geo$river),
    multiple = TRUE,
    options  = pickerOptions(liveSearch = TRUE, actionsBox = TRUE)
  ), # End species picker input
  
  # map
  leafletOutput("map", height = 700)
)

server <- function(input, output, session) {
  
  pal <- colorFactor(
    palette = c("blue", "red"), 
    domain = ssm$percent_exceeded
  )
  
 # filter data ----
  
  # sampling points
    filtered_leaflet_df_ssm <- reactive({
      
      df <- ssm
      
      if (length(input$year) > 0)
        df <- df %>% filter(year == input$year)
      
      # stream name
      if(length(input$river_name) > 0)
        df<- df %>% filter(river_name %in% input$river_name)
      
      df
      
      }) # end reactive ssm df
    
    
  # river geometries
    filtered_leaflet_geos <- reactive({
      
      df_geos <- westport_geo
      
      # year
      if(length(input$year) > 0)
        df_geos <- df_geos %>% filter(year == input$year)
      
      # stream name
      if(length(input$river_name) > 0)
        df_geos <- df_geos %>% filter(river %in% input$river_name)
      
      df_geos
    })
      
  # basemap ----
      
  output$map <- renderLeaflet({
    leaflet() %>%
      
     
      addProviderTiles(providers$CartoDB.Positron) %>%
      
      # set initial zo
      setView(lng = -73.3151, lat = 41.12076, zoom = 13) 
      #addLegend("bottomright", pal = pal, values = pal_range, title = "% Exceeded SSM",
               # labFormat = labelFormat(suffix = "%", transform = function(x) x * 100))
  })
  
  # add filtered points ---
  observe({
    
    df <- filtered_leaflet_df_ssm()
    
    leafletProxy("map", data = df) %>%
      
       clearMarkers() %>%    # remove old markers
      
      addCircleMarkers(
                       lng = ~longitude,
                       lat = ~latitude,
                       color = ~pal(percent_exceeded),       
                       fillColor = ~pal(percent_exceeded),
                       
                       popup = ~site_name) # popup when hovered over %>% 
    
    df_geos <- filtered_leaflet_geos()
    
    leafletProxy("map", data = df_geos) %>%
      
      clearShapes() %>%  # remove old lines
      
    addPolylines(popup = ~ASSESSMENT_UNIT_NAME)
})
} # end server function

shinyApp(ui, server)
