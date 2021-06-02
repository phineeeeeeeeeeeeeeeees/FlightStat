#####################################################################################################
# FlightStat
# 01 reticulate 
# 2021-01-16
#####################################################################################################

# =====================================
# configure python
# =====================================
# set python to virtual environment
Sys.setenv(RETICULATE_PYTHON = "Python/bin/python")
library(reticulate)

#virtualenv_create("FlightStat")
#use_virtualenv("FlightStat")

# verify that you are using the python version you expect
py_config()

# =====================================
# python dependencies
# =====================================
pd <- import("pandas")          # py_install("pandas")     # `import pandas as pd`


# =====================================
# test API "flightradar24"
# =====================================
# py_install("flightradar24" , pip = TRUE)                 # `pip install flightradar24`
fr24 <- import("flightradar24")                            # `import flightradar24 as fr24`
fr24.API <- fr24$Api()                                     # `fr24.API = fr24.Api()`  
                                                           # 這裡要有括號才會初始化object 不然只是呼叫module而已

# Getting airports list                                    # an example
airports <- fr24.API$get_airports()                        # 利用`$`來呼叫class中的instance function
airports$rows[1]                                           # 可以看到第一個機場的資訊 python的dictionary到R中以list儲存
airports_df <- pd$DataFrame$from_dict(airports$rows)       # 將list的儲存格式改為data frame


# =====================================
# test API "pyflightdata"
# =====================================
# py_install("pyflightdata" , pip = TRUE)
FlightData <- import("pyflightdata")$FlightData            # `from pyflightdata import FlightData`

# initiate class object FlightData
FlightData.API <- FlightData()

# login to flightradar24 API
source("R/F00_FR24-login.R")
FlightData.API$login(FR24.id , FR24.pw)

# Flight history by registration
History_B18007 <- FlightData.API$get_history_by_tail_number(tail_number = "B-18007")
str(History_B18007[[1]])                                   # 看看資料儲存的結構：list中還有list，identification; status; aircraft; owner; airline; airport; time

History_B18918 <- FlightData.API$get_all_available_history_by_tail_number("B-18918")
History_B18918[[145]]
History_B18918[[145]]$identification
History_B18918[[145]]$status
History_B18918[[145]]$airport
History_B18918[[145]]$time

# Search flights by keywords
FlightData.API$get_flights("CI61")
FlightData.API$get_flight_for_date("CI61" , "20210110")

# Flight history by flight number
History_CI61 <- FlightData.API$get_history_by_flight_number('CI61')

# Information about the aircraft
Info_PHBVA <- FlightData.API$get_info_by_tail_number("PH-BVA")

# get countries
pd$DataFrame$from_dict(FlightData.API$get_countries())

# get airlines 
airlines <- FlightData.API$get_airlines()
airlines_df <- pd$DataFrame$from_dict(airlines)
airlines_df[airlines_df$title == "China Airlines" , ]

# get fleet (pass the airline-code from get_airlines)
Fleet_CI <- FlightData.API$get_fleet("ci-cal")
Fleet_CI_df <- pd$DataFrame$from_dict(Fleet_CI)

# get airports
FlightData.API$get_airports('Taiwan')




