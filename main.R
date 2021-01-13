# ARCOS data showcase


# set relative working directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))


# libraries
source("lib.R")


# set up database
source("data.R")


# Shiny server application
source("ui.R"); shinyApp(ui, server)


# Publish markdown file
rmarkdown::run("README.Rmd")
