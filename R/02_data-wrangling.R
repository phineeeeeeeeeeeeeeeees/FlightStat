#####################################################################################################
# FlightStat
# 02 data wrangling from raw API outputs 
# 2021-01-17
#####################################################################################################

library(dplyr) ; library(lubridate)

# =====================================
# configure python
# =====================================
# set python to virtual environment
Sys.setenv(RETICULATE_PYTHON = "Python/bin/python")
library(reticulate)

# verify that you are using the python version you expect
py_config()


# =====================================
# connect to API "pyflightdata"
# =====================================
# py_install("pyflightdata" , pip = TRUE)
FlightData <- import("pyflightdata")$FlightData            # `from pyflightdata import FlightData`

# initiate class object FlightData; login to flightradar24 API
FlightData.API <- FlightData()
FlightData.API$login("crab6v8521@gmail.com" , "xu.6y3xu4b04801015")

FlightData.API$logout()

# =====================================
# by registration: all available flight history
# =====================================

History_B18918 <- FlightData.API$get_all_available_history_by_tail_number("B-18918")

# API回傳一個nested dictionary
History_B18918[[145]]
History_B18918[[145]]$identification
History_B18918[[145]]$status
History_B18918[[145]]$airport
History_B18918[[145]]$time

names(unlist(History_B18918[[1]]))


RegHistory_df <- History_B18918 %>% 
  # transform nested list (nested dictionary in python) to data frame (without nesting)
  plyr::ldply(data.frame, .id = "Name") %>% 
  as_tibble %>% 
  # select only columns of interest
  select(time.scheduled.departure , time.scheduled.arrival , 
         identification.number.default , identification.callsign ,
         owner.name , airline.code.iata , 
         airport.origin.code.iata , airport.destination.code.iata , airport.origin.timezone.abbr , airport.destination.timezone.abbr ,
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
         airline = owner.name , 
         airline.code = airline.code.iata , 
         origin = airport.origin.code.iata , 
         dest = airport.destination.code.iata , 
         origin_tz = airport.origin.timezone.abbr , 
         dest_tz = airport.destination.timezone.abbr ,
         ATD = time.real.departure , 
         ATA = time.real.arrival , 
         ETD = time.estimated.departure , 
         ETA = time.estimated.arrival , 
         status.type = status.generic.status.text) %>% 
  # datetime (STD, STA, ATD, ATA, ETD, ETA)
  mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as.integer)) %>% 
  mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as_datetime))


# =====================================
# by flight number: all available flight history
# =====================================

History_CI61 <- FlightData.API$get_all_available_history_by_flight_number("CI61")
# API回傳一個nested dictionary
History_CI61[[1]]

FlightHistory_df <- History_CI61 %>% 
  # transform nested list (nested dictionary in python) to data frame (without nesting)
  plyr::ldply(data.frame, .id = "Name") %>% 
  #as_tibble %>% 
  # select only columns of interest
  select(time.scheduled.departure , time.scheduled.arrival , 
         identification.number.default , identification.callsign , 
         aircraft.registration , aircraft.model.code , 
         status.live , status.text , status.generic.status.text , 
         airport.origin.code.iata , airport.destination.code.iata , airport.origin.timezone.abbr , airport.destination.timezone.abbr , 
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
         origin_tz = airport.origin.timezone.abbr , 
         dest_tz = airport.destination.timezone.abbr ,
         ATD = time.real.departure , 
         ATA = time.real.arrival , 
         ETD = time.estimated.departure , 
         ETA = time.estimated.arrival)%>% 
  # datetime (STD, STA, ATD, ATA, ETD, ETA)
  mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as.integer)) %>% 
  mutate(across(c(STD , STA , ATD , ATA , ETD , ETA) , .fns = as_datetime))


