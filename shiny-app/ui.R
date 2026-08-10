##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                               user interface                             ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---- dashboard header ----
header <- dashboardHeader(
  
  # title ----
  title = "Westport Conservation Department",
  titleWidth = 400 # adjust width of title box, ensuring complete text fits
  
)

# --- dashboard sidebar ----
sidebar <-  dashboardSidebar(
  
  # sidebarMenu ----
  sidebarMenu(
    
    menuItem(text = "Dashboard", 
             tabName = "dashboard"), # identifier, how content will be linked
             #icon = icon("star")), # from font awesome library
    
    menuItem(text = "About", tabName = "about") 
             #icon = icon("gauge"))
    
  ) # END sidebarMenu
  
) # END dashboardSidebar


# ---- dashboard body ----

# create list of years, for slider choices
years <- sort(unique(ssm$year))

body <- dashboardBody( # theme always goes into body of the dashboard!
  
  #use_theme("dashboard-fresh-theme.css"),
  
  tabItems(
    
    # welcome tabItem ----
    tabItem(
      
      tabName = "dashboard", # will know that everything I build here should show up on welcome tab above
      
     # top block (map, text, and inputs)
      fluidRow(
        
        # left-hand column ----
        column(
        
        width = 8,
        
        # leaflet map
        box(width = NULL, # tells it to inheret the width of the column
            
            title = tagList(icon("water"), strong("Westport Stream Quality")),
            
           
           # leaflet map
           leafletOutput("map", height = 700)
        )  # END background box
        
      ), # END lefthand column
      
      # right-hand column ----
      column(width = 4,
             
             div(style = "font-size: 14px;", includeMarkdown("text/inputs_intro.Rmd")),
             
             # data filter inputs box ----
             box(width = NULL,
                 sliderInput("year", "Select year", min = min(years), max = max(years),
                             value = min(years), step = 1, sep = "", animate = animationOptions(interval = 500)),
                 
                 # dropdown to pick river
                 pickerInput(
                   inputId  = "river_name",
                   label    = "Select stream",
                   choices  = unique(westport_geo$river),
                   multiple = TRUE,
                   options  = pickerOptions(liveSearch = TRUE, actionsBox = TRUE))
                 
             ), # end data filter inputs box
             
             # text about using ssm
             div(style = "font-size: 14px;", includeMarkdown("text/about_ssm.Rmd"))
           
             
      ) # END right-hand column
      ), # END first fluid row
     
     # row with table output
     fluidRow(
       
       column(
         width = 10,
         offset = 1,  # (12 - 8) / 2, centers it
       
       # data table box ----
       box(
         width = NULL,
         # header
         h4(textOutput("table_heading")),
         
         # table
         DTOutput("table")
       ) # END data table box
       
       ) # end column
       
     ) # END second fluid row
      
    ), # END welcome tabItem
    
    # dashboard tabItem ----
    tabItem(
      
      tabName = "about",
      
      # input box ----
      box(
        
        width = 4, # screens are broken up into units of 12, so this is always out of 12
        
        title = tags$strong("About") # strong = bold
        
            ) # END input box
      
    ) # END dashboard tabItem
    
  ) # END tabItems
  
) # END dashboardBody


# --- combine all into dashboardPage ----
dashboardPage(header, sidebar, body)