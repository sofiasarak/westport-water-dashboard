##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##------------- WRANGLING RAW EARTHPLACE DATA FOR PLOTLY FORMAT-----------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary libraries
library(readxl)
library(here)
library(tidyverse)
library(janitor)

# read in data (downloaded from www.earthplace.org/data-projects/)
raw <- read_excel(here("data", "Harbor-Watch-Long-Term-Analysis-Data-File.xlsx"), sheet = "All Data (May-Sept)") %>% 
  
  # change column names to all lowercase
  clean_names()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##              select necessary columns and filter for westport            ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# create vector that contains westport sampling site names
westport_sites <- c("Indian", "Stony", "SG1", "Saugatuck", "West Saug",
                    "Poplar", "Deadman", "Apetuck 1", "Apetuck 2", "Apetuck 3",
                    "Muddy", "New", "Lamplight", "Pussy Willow", "Sasco", "Hunt Club")

# towns are listed in the variable `towns` - we will select rows where "Westport is listed as one of the towns"
westport <- raw %>% 
  
  filter(str_detect(towns, "Westport")) %>% 
  
  # select for only westport sampling site names (removes trackdown projects, etc)
  filter(str_detect(site_name, paste(str_escape(westport_sites), collapse = "|")))

# select only the variables we need for our plotly
westport <- westport %>% 
  
  select(site_name, date, year, month,
         actual_and_estimated_e_coli_100m_l,
         enterococci_100_m_l, latitude, longitude)

# pivot to long former
westport  <- westport %>% 
  
  # shorten column names
  rename("e.coli" = actual_and_estimated_e_coli_100m_l,
         "entero" = enterococci_100_m_l) %>% 
  
  pivot_longer(cols = c(e.coli, entero),
               names_to = "indicator",
               values_to = "conc") 

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                         find when ssm was exceeded                       ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

westport <- westport %>% 
  
  # create binary column for exceeded or not (1 = exceeded)
  mutate(exceed_ssm = case_when(
    indicator == "e.coli" & conc > 126 ~ 1,
    indicator == "entero" & conc > 35 ~ 1,
    .default = 0
  ))

# summarize by summing the number of times SSM was exceeded for each site, for each year
ssm <- westport %>% 
  group_by(year, site_name) %>% 
  
  # create a times exceeded column as well as
  summarize(times_exceeded = sum(exceed_ssm),
            
            # percent of times exceeded         
            percent_exceeded = times_exceeded / n())

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                            find site max by year                         ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

max <- westport %>% 
  
  group_by(year, site_name) %>% 
  
  summarize(max = max(conc, na.rm = TRUE))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 add coordinates back in based on site name               ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# select only site_names and their coords
westport_coords <- westport %>% 
  
  select(site_name, latitude, longitude)

# joining removed lat and long columns so we are able to plot sites
ssm <- ssm %>% 
  
  left_join(westport_coords, by = "site_name") %>% 
  
  # keep only unique rows
  distinct()

max <- max %>% 
  
  left_join(westport_coords, by = "site_name") %>% 
  distinct()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                  save files                              ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

write_csv(ssm, "data/ssm.csv")
write_csv(max, "data/max.csv")
