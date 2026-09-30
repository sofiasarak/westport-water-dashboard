# Westport Water Dashboard
Creating an interactive dashboard showing changes in Westport's urban stream water quality over time.

*This project is currently in progress. Expect updates in code and file structure.*

## Repository Contents

**data_wrangling.R**: Calculates the percent of sampling sites that exceed the single sample maximum each year, by river.

**river_geoms.R**: Combines Westport river geometries into one and adds associated sampling years.

**segmentize.R**: Creates segments from the Westport river geometries and attaches single sample maximum (percent exceeded) to them.

**shiny-app**: Contains ui.R, server.R, and global.R –– all components of the Shiny Dashboard.

## Data Sources

**Bacteria concentrations**: [Harbor Watch](https://earthplace.org/data-projects/)

**River geometries:** [CT DEEP GIS Open Data](https://deepmaps.ct.gov/maps/07a49654bb1f4a79bc65eafbae7cb8e4/about)

## Acknowledgements

This dashboard was created using content from [Sam Shanny-Csik's Intro to R Shiny course](https://samanthacsik.github.io/courses/eds-296-shiny/), in collaboration with the [Westport Conservation Department](https://www.westportct.gov/government/departments-a-z/conservation-department) with technical advice from Nikki Spiller at [Harbor Watch](https://earthplace.org/harbor-watch/).
