##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                               user interface                             ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# create list of years, for slider choices
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
  leafletOutput("map", height = 700),
  
  # table heading
  h4(textOutput("table_heading")),
  
  # table
  DTOutput("table")
)