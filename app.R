# Shiny server application


# just set up db connection
db <- dbConnect(RSQLite::SQLite(), "washpo.db")


# US geographical data
counties <- urbnmapr::counties
states <- urbnmapr::states


ui <- fluidPage(
  titlePanel("ARCOS Wash Post Dataset"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId = "year",
                  label = "Specify year:",
                  min = 2006,
                  max = 2014,
                  value = 2006),
      sliderInput(inputId = "month",
                  label = "Specify month:",
                  min = 1,
                  max = 12,
                  value = 1),
      checkboxInput(inputId = "popscale", 
                    label = "Scale by population:", 
                    value = FALSE, 
                    width = NULL),
      selectInput(inputId = "columns",
                  label = "Specify states:",
                  choices = unique(states$state_name),
                  selected = "Florida",
                  multiple = TRUE)
    ),
    mainPanel(
      plotOutput(outputId = "distPlot", width='100%', height="800px")
    )
  )
)


server <- function(input, output) {
  output$distPlot <- renderPlot({

    year <- input$year
    month <- input$month
    scale <- input$popscale
    columns <- input$columns
    
    query <- paste0("select * from data where year == '", year, "' and month == '", sprintf("%02d", month), "';")
    message(paste0(year, " - ", month))
    temp <- dbGetQuery(db, query)
    names(temp)[7] <- "county_fips"
    
    data <- left_join(temp, counties, by = "county_fips") %>% 
      filter(BUYER_STATE %in% states$state_abbv[states$state_name %in% columns])
    agg.data <- aggregate(cbind(long, lat, group, DOSAGE_UNIT, population) ~ state_name, data = data, mean)

    
    if(scale){
      data$DOSAGE_UNIT <- data$DOSAGE_UNIT/data$population
    }
    
    data %>%
      ggplot(aes(long, lat, group = group, fill = DOSAGE_UNIT)) +
      geom_polygon(color = "#ffffff", size=.05) +
      scale_fill_gradient(guide = guide_colorbar(title.position = "top"),
                          low = "#ffffff", high = "#ff6961") +
      geom_polygon(data = states[states$state_abbv %in% data$BUYER_STATE, ], 
                   mapping = aes(long, lat, group = group),
                   fill = NA, color = "black", size=.5) +
      geom_label(data = agg.data, aes(long, lat, label = state_name), size = 5, 
                 fontface = "bold", fill="#ffffff") +
      coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
      theme(legend.title = element_text(),
            legend.key.width = unit(.5, "in")) +
      labs(fill = "Units") +
      ggtitle("US Opioids") +
      theme(panel.grid.major = element_line(color = gray(0.5), linetype = "dashed", 
                                            size = 0.5), 
            panel.background = element_rect(fill = "aliceblue"))
    
  })
}
