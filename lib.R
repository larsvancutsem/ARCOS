## libraries

# retrieve github packages
install.packages("devtools")
dev_packages <- c("wpinvestigative/arcos", "UrbanInstitute/urbnmapr")
lapply(dev_packages, devtools::install_github)

# retrieve local functions
source("trycatch.R")

# load packages
packages <- c("tidyverse", "DBI", "RSQLite", "jsonlite", "knitr", "geofacet",
              "scales", "arcos", "urbnmapr", "shiny", "leaflet", "RColorBrewer",
              "raster", "futile.logger", "utils")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
lapply(packages, require, character.only = TRUE)
