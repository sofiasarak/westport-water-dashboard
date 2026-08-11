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
      
      tabName = "dashboard", # will know that everything I build here should show up on dashboard tab
      
     # top block (map, text, and inputs)
      fluidRow(
        
        # left-hand column ----
        column(
        
        width = 8,
        
        # leaflet map
        box(width = NULL, # tells it to inheret the width of the column
            
            title = tagList(icon("water"), strong("Westport Stream Quality")),
            
           
           # leaflet map
           leafletOutput("map", height = 700),
           
           
           # map disclaimer
           div(style = "font-size: 12px;", includeMarkdown("text/map_disclaimer.Rmd"))
        )  # END leaflet box
        
      ), # END lefthand column
      
      # right-hand column ----
      column(width = 4,
             
             # input intro text
             div(style = "font-size: 14.5px;", includeMarkdown("text/inputs_intro.Rmd")),
             
             # data filter inputs box ----
             box(width = NULL,
                 
                 # year slider
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
             div(style = "font-size: 14.5px;", includeMarkdown("text/about_ssm.Rmd"))
           
             
      ) # END right-hand column
      ), # END first fluid row
     
     # row with table output
     fluidRow(
       
       # set column size so that it is centered but doesn't occupy entire page
       column(
         width = 11,
         offset = 0.5,  # (12 - 11) / 2, centers it
       
       # data table box ----
       box(
         width = NULL,
         
         # text telling user to click on points
         div(style = "font-size: 14px;", includeMarkdown("text/table_output_intro.Rmd")),
         
         # header
         h4(strong(textOutput("table_heading"))),
         
         # bacteria units
         div(style = "font-size: 14px;", includeMarkdown("text/bacteria_units_table.Rmd")),
         
         # table
         DTOutput("table")
       ) # END data table box
       
       ) # end column
       
     ) # END second fluid row
      
    ), # END welcome tabItem
    
    # about tabItem ----
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