#####################################################################################################
# FlightStat
# 01 reticulate 
# 2021-01-16
#####################################################################################################

library(reticulate)
use_virtualenv("r-reticulate")

# =====================================
# test API "flightradar24"
# =====================================
# py_install("flightradar24" , pip = TRUE)                 # `pip install flightradar24`
py_fr24 <- import("flightradar24")                         # `import flightradar24`
py_fr24.API <- py_fr24$Api()                               # `fr = flightradar24.Api()`  
                                                           # 這裡要有括號才會初始化object 不然只是呼叫module而已

# # Getting airports list                                  # an example
airports <- py_fr24.API$get_airports()                     # 利用`$`來呼叫class中的instance function
airports$rows[1]                                           # 可以看到第一個機場的資訊 python的dictionary到R中以list儲存
airports_df <- data.frame(matrix(unlist(airports$rows) , nrow = length(airports$rows), byrow = TRUE))
head(airports_df)                                          # 將list的儲存格式改為data frame

# =====================================
# test API "pyflightdata"
# =====================================
# py_install("pyflightdata" , pip = TRUE)
py_FlightData <- import("pyflightdata")$FlightData()       # `from pyflightdata import FlightData`

B18007 <- py_FlightData$get_history_by_tail_number(tail_number = "B-18007")
