# data retrieval


# focus setting
params <-  county_list(key="WaPo") %>% 
  #filter(BUYER_STATE %in% c("FL", "AL", "GA", "MS", "SC", "LA")) %>%
  dplyr::select(c("BUYER_COUNTY", "BUYER_STATE"))


# initial database creation
if(!file.exists("washpo.db")){
  
  # just set up db connection
  db <- dbConnect(RSQLite::SQLite(), "washpo.db")
  
  # initial api request
  init <- summarized_county_monthly(county = "AUTAUGA", 
                                    state = "AL", 
                                    key = "WaPo")
  
  # population data
  pop <- county_population(county = "AUTAUGA", 
                           state = "AL", 
                           key = "WaPo")
  
  # add population data
  init$population <- pop[1, 10]
  
  # create init db
  dbCreateTable(db, "data", init)
  
} else {
  
  # just set up db connection
  db <- dbConnect(RSQLite::SQLite(), "washpo.db")
}


# function to create API requests
API_request <- function(params){
  message(paste0("Retrieving data for county: ", 
                 params$county, ", and state: ",
                 params$state))
  result <- summarized_county_monthly(county = params$county, 
                                      state = params$state, 
                                      key = "WaPo") 
  pop <- county_population(county = params$county,
                           state = params$state,
                           key = "WaPo")
  result$population <- pop$population[match(result$year, pop$year)]
  result %>% return()
}


# function to write input to database
write_to_db <- function(input){
  dbWriteTable(db, "data", input, append = T)
  message("Successfully written to database!\n")
}


# function to populate database
populate_db <- function(){
  
  # determine state-counties to retrieve
  required <- params
  in_db <- dbGetQuery(db, "select distinct BUYER_COUNTY, BUYER_STATE from data")
  to_retrieve <- required[!(as.data.frame(t(required)) %in% as.data.frame(t(in_db))), ]
  
  # loop API request
  for(x in 1:nrow(to_retrieve)){
    settings <- list(county = to_retrieve$BUYER_COUNTY[x],
                     state = to_retrieve$BUYER_STATE[x])
    Sys.sleep(1)
    temp <- retry(API_request(settings))
    if(length(temp)>1){
      retry(write_to_db(temp))
    }
  }
}

# populate the database
populate_db()
