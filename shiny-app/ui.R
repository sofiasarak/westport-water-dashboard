##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                               user interface                             ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ---- dashboard header ----
header <- dashboardHeader(
  
  title = tagList(
    tags$img(
      src = "westport_logo.png",
      height = "45px",
      style = "vertical-align: middle; padding-right: 15px; padding-left: 15px;"
    ),
    tags$span(
      "Conservation Department",
      style = "font-weight: bold;
               color: #04367B;
               font-size: 18px;
               line-height: 20px;
               vertical-align: middle"
    )
  )
)


# --- dashboard sidebar ----
sidebar <-  dashboardSidebar(
  
  # remove sidebar
 disable = TRUE
 
) # END dashboardSidebar


# ---- dashboard body ----

# create list of years, for slider choices
years <- sort(unique(ssm$year))

body <- dashboardBody( # theme always goes into body of the dashboard!
  
  tags$head(
    tags$style(HTML("
      .main-header .logo {
        height: 60px !important;
        display: flex !important;
        align-items: center !important;
        width: 350px !important;
      }

      .main-header .navbar {
        height: 60px !important;
        display: flex !important;
        align-items: center !important;
        margin-left: 350px !important;
      }
      
       /* Blue area to the right */
      .main-header .navbar {
        margin-left: 350px !important;
        background-color: #3C546B !important;
      }

      /* Make sure the whole header is blue */
      .main-header {
        background-color: #3C546B !important;
      }
      
      /* Slider year popup */
    .irs-single {
      background-color: #04367B !important;
      color: white !important;
    }

    /* Triangle underneath popup */
    .irs-single:before {
      border-top-color: #04367B !important;
    }
      
    /* Slider selected portion */
      .irs-bar {
        background-color: #3C546B !important;
        border-top-color: #3C546B !important;
        border-bottom-color: #3C546B !important;
      }

    /* Small part at the beginning of the selected bar */
      .irs-bar-edge {
        background-color: #3C546B !important;
        border-color: #3C546B !important;
}
      
      /* Hyperlink color */
      
      a {
      color: #E24C17 !important;
    }
      
    "))
  ),
  
  use_theme("westport-theme.css"),
  
      fluidRow(
        
        h2("Explore the health of Westport streams over time",
           style = "color: #3C546B;
                    font-weight: bold;
                    margin-left: 30px;"),
        
        br(),
        
        # left-hand column ----
        column(
        
        width = 8,

        
        # leaflet map
        box(width = NULL, # tells it to inheret the width of the column
            
            title = tagList(
              tags$span(
                "Pan and click around the map to view data.",
                style = "font-weight: normal;
                         color: #000000"
              )
            ),
            
           
           # leaflet map
           leafletOutput("map", height = 700),
           
           br(),
           
           # map disclaimer
           div(style = "font-size: 13px;", includeMarkdown("text/map_disclaimer.Rmd"))
        )  # END leaflet box
        
      ), # END lefthand column
      
      # right-hand column ----
      column(width = 4,
             
             # input intro text
             div(style = "font-size: 16.5px;", includeMarkdown("text/inputs_intro.Rmd")),
             
             # data filter inputs box ----
             box(width = NULL,
                 
                 # year slider
                 sliderInput("year", "Year", min = min(years), max = max(years),
                             value = min(years), step = 1, sep = "", animate = animationOptions(interval = 500)),
                 
                # dropdown to pick river
                 pickerInput(
                   inputId  = "river_name",
                   label    = "Stream(s)",
                   choices  = unique(westport_geo$river),
                   multiple = TRUE,
                   options  = pickerOptions(liveSearch = TRUE, actionsBox = TRUE))
                 
             ), # end data filter inputs box
             
             # text about using ssm
             div(style = "font-size: 16.5px;", 
             
                 # change color of heading
             tags$style("
    h3 {
      color: #3C546B;
      font-weight: bold;
    }
  "),
             includeMarkdown("text/about_ssm.Rmd"))
           
             
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
         div(style = "font-size: 16.5px;", includeMarkdown("text/table_output_intro.Rmd")),
         
         # header
         h4(strong(textOutput("table_heading")),
            style = "color: #3C546B;
                    font-weight: bold;"),
         
         # bacteria units
         div(style = "font-size: 16.5px;", includeMarkdown("text/bacteria_units_table.Rmd")),
         
         # table
         DTOutput("table")
       ) # END data table box
       
       ) # end column
       
     ), # END second fluid row

  
  # initialize third fluid row (for GitHub info and source)
  fluidRow(
    
    br(),
    
    div(style = "font-size: 13px;
                margin-left: 800px;", includeMarkdown("text/source_and_code.Rmd"))
  )
      
) # END dashboardBody


# --- combine all into dashboardPage ----
dashboardPage(header, sidebar, body)