library(fresh)

create_theme(
  theme = "default",
  
  # header color
  adminlte_color(
    light_blue = "#FFFFFF"),
  
  # 1. Handle all structural and text styling together
  adminlte_vars(
    main_header_bg = "#3C546B",       # Sets header color
    main_header_logo_bg = "#FFFFFF",  # Sets brand/logo background color to white
    `body-bg` = "#FFFFFF",            # Sets fallback structural background
    `text-color` = "#000000"          # Safely sets main text body color
  ),
  
  # 2. Set the global main body canvas canvas area
  adminlte_global(
    content_bg = "#FFFFFF"            # Background color
  ),
  
  # 3. Optional: Uncomment to safely add your sidebar layout later
  # adminlte_sidebar(
  #   width = "400px",
  #   dark_bg = "#3C546B",
  #   dark_hover_bg = "#2C3E50",
  #   dark_color = "#FFFFFF"
  # ),
  
  output_file = here::here("shiny-app", "www", "westport-theme.css")
)

