#####################################################################################################
# FlightStat
# 03 registration-airport statistic
# 2021-01-19
#####################################################################################################

# =====================================
# required packages
# =====================================
# basics
library(dplyr) ; library(lubridate) ; library(tidyr)
# API functions
source("R/F01_API.R")

FlightData.API$logout()

# =====================================
# example
# =====================================
OI_registration <- "B-18007"
OI_airport <- "TPE"

# get flight history of the aircraft
OI_RegHist_df <- get_RegHistory_df(OI_registration , all = FALSE)


# filter the particular airport of interest
OI_RegHist_df %>% 
  # 如果這架飛機這班是從該機場起飛 我就只關心起飛時間；如果是降落，我就只關心抵達時間
  # --> 將起飛／降落時間資訊合併
  unite(col = "origin" , origin , origin_tz , STD , ATD , ETD , sep = "____") %>% 
  unite(col = "dest" , dest , dest_tz , STA , ATA , ETA,  , sep = "____") %>% 
  # pivot_longer
  pivot_longer(cols = c(origin , dest) , names_to = "type") %>% 
  separate(value , into = c("airport" , "airport_tz" , "ST" , "AT" , "ET") , sep = "____") %>% 
  mutate(across(.cols = c(ST , AT , ET) , .fns = as_datetime)) %>% 
  # filter only the particular airport of interest
  filter(airport == OI_airport) %>% 
  # 飛機實際在機場的時間：先看ETD(/ETA) 若為NA 看ATD(/ETD)。 STD/STA則好像實際上沒有太大參考價值？
  mutate(present_time = ifelse(!is.na(ET) , ET , AT) %>% as_datetime) %>% 
  # 轉換時區到當地時間
  mutate(present_time_local = with_tz(present_time , tzone = unique(airport_tz))) %>% 
  # select relevant columns
  select(present_time_local , FlightNum , type , reg , status.type) %>% 
  # get time predictor variables: weekday, hour (時段)
  mutate(wday = wday(present_time_local) , 
         hour = hour(present_time_local)) %>% 
  # 計算時段 可參考matrix(c(1:24 , findInterval(1:24 , c(7, 14, 18))) , ncol = 2)
  mutate(hour.seg = cut(hour , c(0, 7 , 14 , 18 , 24)) ) %>% 
  #mutate(hour.seg = findInterval(hour , vec = c(7 , 14 , 18)) ) %>% 
  #mutate(hour.seg = ifelse(hour.seg == 3 , 0 , hour.seg) %>% as.character ) %>% 
  # cross table
  xtabs(~hour.seg + wday + type , data = .)

