##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##------------- WRANGLING RAW EARTHPLACE DATA FOR PLOTLY FORMAT-----------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# load necessary libraries and read in data
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

# towns are listed in the variable `towns` - we will select rows where "Westport is listed as one of the towns"
westport <- raw %>% 
  
  filter(str_detect(towns, "Westport"))

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
##                 add coordinates back in based on site name               ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# select only site_names and their coords
westport_coords <- westport %>% 
  
  select(site_name, latitude, longitude)

# grouping removed lat and long columns, so we join them back in to be able to plot
ssm <- ssm %>% 
  
  left_join(westport_coords, by = "site_name") %>% 
  
  # keep only unique rows
  distinct()

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                  save file                               ----
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
write_csv(ssm, "data/ssm.csv")
