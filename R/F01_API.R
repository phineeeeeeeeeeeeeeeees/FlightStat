#####################################################################################################
# FlightStat
# function 01 API
# 2021-01-17
#####################################################################################################

library(dplyr) ; library(lubridate)

# =====================================
# configure python
# =====================================
# set python to virtual environment
Sys.setenv(RETICULATE_PYTHON = "Python/bin/python")
library(reticulate)

# =====================================
# connect to API "pyflightdata"
# =====================================
# py_install("pyflightdata" , pip = TRUE)
FlightData <- import("pyflightdata")$FlightData            # `from pyflightdata import FlightData`

# initiate class object FlightData; 
FlightData.API <- FlightData()

# login to flightradar24 API
source("R/F00_FR24-login.R")             # master login mode 
# FR24.id <- "crab6v8521@gmail.com"
# FR24.pw <- askpass::askpass(paste0("Enter the password for flightradar24 subscription (ID: " , FR24.id , ")"))
FlightData.API$login(FR24.id , FR24.pw)


# =====================================
# search by registration: all available flight history
# =====================================
get_RegHistory_df <- function(registration , all = FALSE){
  # check registration class
  if(!is.character(registration)) stop("Error: registration must be class 'character', eg. 'B-18918'")
  # download via FlightData API
  if(all){
    RegHistory_nested.list <- FlightData.API$get_all_available_history_by_tail_number(registration)
  }else{
    RegHistory_nested.list <- FlightData.API$get_history_by_tail_number(registration)
  }
  # check availability
  if(length(RegHistory_nested.list) == 0) stop("Warning: no available flight history found or wrong registration")
  # transform to data frame
  RegHistory_df <- RegHistory_nested.list %>% 
    # transform nested list (nested dictionary in python) to data frame (without nesting)
    plyr::ldply(data.frame, .id = "Name") %>% 
    as_tibble %>% 
    # select only columns of interest
    select(time.scheduled.departure , time.scheduled.arrival , 
           identification.number.default , identification.callsign ,
           aircraft.registration , owner.name , airline.code.iata , 
           airport.origin.code.iata , airport.destination.code.iata , airport.origin.timezone.name , airport.destination.timezone.name ,
           time.real.departure , time.real.arrival , time.estimated.departure , time.estimated.arrival , 
           status.live , status.text , status.generic.status.text) %>% 
    # transform every column to character
    mutate(across(.cols = everything() , .fns = as.character)) %>% 
    # datetime==1 or None -> NA
    mutate(across(.cols = starts_with("time") , function(x){ifelse(x == "1" | x == "None" , NA , x)})) %>% 
    # rename columns
    rename(STD =  time.scheduled.departure , 
           STA = time.scheduled.arrival , 
           FlightNum = identification.number.default , 
           callsign = identification.callsign ,
           reg = aircraft.registration , 
           airline = owner.name , 
           airline.code = airline.code.iata , 
           origin = airport.origin.code.iata , 
           dest = airport.destination.code.iata , 
           origin_tz = airport.origin.timezone.name , 
           dest_tz = airport.destination.timezone.name ,
           ATD = time.real.departure , 
           ATA = time.real.arrival , 
           ETD = time.estimated.departure , 
           ETA = time.estimated.arrival , 
           status.type = status.generic.status.text) %>% 
    # datetime (STD, STA, ATD, ATA, ETD, ETA)
    mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as.integer)) %>% 
    mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as_datetime))
  rm(RegHistory_nested.list)
  # return data frame
  return(RegHistory_df)
}



# =====================================
# search by flight number: all available flight history
# =====================================
get_FlightHistory_df <- function(FlightNum , all = FALSE){
  # check registration class
  if(!is.character(FlightNum)) stop("Error: flight number must be class 'character', eg. 'CI62'")
  # download via FlightData API
  if(all){
    FlightHistory_nested.list <- FlightData.API$get_all_available_history_by_flight_number(FlightNum)
  }else{
    FlightHistory_nested.list <- FlightData.API$get_history_by_flight_number(FlightNum)
  }
  # check availability
  if(length(FlightHistory_nested.list) == 0) stop("Warning: no available flight history found or wrong flight number")
  # transform to data frame
  FlightHistory_df <- FlightHistory_nested.list %>% 
    # transform nested list (nested dictionary in python) to data frame (without nesting)
    plyr::ldply(data.frame, .id = "Name") %>% 
    as_tibble %>% 
    # select only columns of interest
    select(time.scheduled.departure , time.scheduled.arrival , 
           identification.number.default , identification.callsign , 
           aircraft.registration , aircraft.model.code , 
           status.live , status.text , status.generic.status.text , 
           airport.origin.code.iata , airport.destination.code.iata , airport.origin.timezone.name , airport.destination.timezone.name , 
           time.real.departure , time.real.arrival , time.estimated.departure , time.estimated.arrival ) %>% 
    # transform every column to character
    mutate(across(.cols = everything() , .fns = as.character)) %>% 
    # datetime==1 or None -> NA
    mutate(across(.cols = starts_with("time") , function(x){ifelse(x == "1" | x == "None" , NA , x)})) %>% 
    # rename columns
    rename(STD =  time.scheduled.departure , 
           STA = time.scheduled.arrival , 
           FlightNum = identification.number.default , 
           callsign = identification.callsign , 
           reg = aircraft.registration , 
           model = aircraft.model.code , 
           status.type = status.generic.status.text , 
           origin = airport.origin.code.iata , 
           dest = airport.destination.code.iata , 
           origin_tz = airport.origin.timezone.name , 
           dest_tz = airport.destination.timezone.name ,
           ATD = time.real.departure , 
           ATA = time.real.arrival , 
           ETD = time.estimated.departure , 
           ETA = time.estimated.arrival)%>% 
    # datetime (STD, STA, ATD, ATA, ETD, ETA)
    mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as.integer)) %>% 
    mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as_datetime))
  # return
  rm(FlightHistory_nested.list)
  return(FlightHistory_df)
}
