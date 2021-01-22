#####################################################################################################
# FlightStat
# 03 registration-airport statistic
# 2021-01-19
#####################################################################################################

# =====================================
# required packages
# =====================================
# basics
library(dplyr) ; library(lubridate) ; library(tidyr) ; library(ggplot2)
# API functions
source("R/F01_API.R")

# 在結束階段之後記得執行：
FlightData.API$logout()
rm(FlightData , FlightData.API , get_RegHistory_df , get_FlightHistory_df)   # 下一次load才不會有問題

# =====================================
# example
# =====================================
OI_registration <- "JA873A"
OI_airport <- "NRT"

# get flight history of the aircraft
#OI_RegHist_df <- get_RegHistory_df(OI_registration , all = FALSE)
OI_RegHist_df_all <- get_RegHistory_df(OI_registration , all = TRUE)

#B18918_RegHist_df_all <- OI_RegHist_df_all     OI_RegHist_df_all <- B18918_RegHist_df_all
#B18007_RegHist_df_all <- OI_RegHist_df_all     OI_RegHist_df_all <- B18007_RegHist_df_all
#B16331_RegHist_df_all <- OI_RegHist_df_all     OI_RegHist_df_all <- B16331_RegHist_df_all
#save(B18007_RegHist_df_all , B18918_RegHist_df_all , B16331_RegHist_df_all , file = "data/03_RegHist_df_all_test.RData")

# =====================================
# filter the particular airport of interest
# =====================================
OI_RegHist_airport <- OI_RegHist_df_all %>% 
  # 如果這架飛機這班是從該機場起飛 我就只關心起飛時間；如果是降落，我就只關心抵達時間
  # --> 將起飛／降落時間資訊合併
  unite(col = "origin" , origin , origin_tz , STD , ATD , ETD , sep = "____") %>% 
  unite(col = "dest" , dest , dest_tz , STA , ATA , ETA , sep = "____") %>% 
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
  select(present_time_local , FlightNum , type , reg , status.type , airport_tz)

# =====================================
# cross table: count ~ weekday + cross table
# =====================================
# 通用的區間表示法中，圓括號表示排除，方括號表示包括。
hour_intervals_break <- c(0, 7 , 14 , 18 , 24)
OI_RegHist_airport %>% 
  # get time predictor variables: weekday, hour (時段)
  mutate(wday = wday(present_time_local) , 
         hour = hour(present_time_local)) %>% 
  # 計算時段 可參考matrix(c(1:24 , findInterval(1:24 , c(7, 14, 18))) , ncol = 2)
  mutate(hour.seg = cut(hour , hour_intervals_break , right = FALSE) ) %>% 
  #mutate(hour.seg = findInterval(hour , vec = c(7 , 14 , 18)) ) %>% 
  #mutate(hour.seg = ifelse(hour.seg == 3 , 0 , hour.seg) %>% as.character ) %>% 
  # cross table
  xtabs(~hour.seg + wday + type , data = .)

# =====================================
# presence/absence history at the airport 
# =====================================
OI_airport_reg_history <- OI_RegHist_airport %>% 
  # 由available history中距離現在最久的一天到今天建立date sequence
  select(present_time_local) %>% 
  unlist %>% 
  range(na.rm = TRUE) %>% 
  as_datetime() %>% 
  as_date() %>% 
  {seq.Date(from = .[1] , to = .[2] , by = "day")} %>%        # {}避免 %>% 中的參數直接傳遞到函數裡
  # 建立好date sequence後每一天加入各時段
  merge(cut(hour_intervals_break , hour_intervals_break , right = FALSE)) %>% 
  # 兩個vector排列組合建立而成的data frame：日期與小時。rename column
  rename(date = x , hour.seg = y) %>% 
  # 時段的下界(24點)cut後會是NA，移除
  filter(!is.na(hour.seg)) %>% 
  arrange(date) %>% 
  # 建立星期
  mutate(wday = wday(date)) %>% 
  left_join({
    OI_RegHist_airport %>% 
      # date, hour.seg (for joining)
      mutate(date = as_date(present_time_local) ,
             hour = hour(present_time_local)) %>% 
      filter(!is.na(hour)) %>% 
      # 時段
      mutate(hour.seg = cut(hour , hour_intervals_break , right = FALSE))
  } , by = c("date" , "hour.seg")) %>% 
  # response: type (absence/dest/origin)
  mutate(type = ifelse(is.na(type) , "absence" , type)) %>% 
  # binary response: present at the airport or not
  mutate(presence = ifelse(type == "absence" , "0" , "1")) %>% 
  # weekday integer -> factor
  mutate(wday = factor(wday)) %>% 
  # remove duplicate rows
  distinct()

# =====================================
# presence/absence history at the airport: hourly time series
# =====================================
# 不是依照時段而是hourly
Reg_presence_ts <- OI_RegHist_airport %>% 
  # 由available history中距離現在最久的一天到今天建立date sequence
  select(present_time_local) %>% 
  unlist %>% 
  range(na.rm = TRUE) %>% 
  as_datetime() %>% 
  as_date() %>% 
  {seq.Date(from = .[1] , to = .[2] , by = "day")} %>%
  merge(0:23) %>% 
  rename(date = x , hour = y) %>% 
  arrange(date , hour) %>% 
  left_join({
    OI_RegHist_airport %>% 
      # date, hour (for joining)
      mutate(date = as_date(present_time_local) ,
             hour = hour(present_time_local)) %>% 
      filter(!is.na(hour))
  } , by = c("date" , "hour")) %>% 
  distinct() %>% 
  # binary response: present at the airport or not
  mutate(presence = ifelse(is.na(type) , 0 , 1)) %>% 
  # datetime column for time series
  mutate(hour = ifelse(nchar(hour) == 1 , paste0("0" , hour) , hour)) %>% 
  mutate(datetime = as_datetime(paste(date , hour) , format = "%Y-%m-%d %H")) %>% 
  mutate(datetime = as.POSIXct(datetime)) 
# time series visualization
Reg_presence_ts %>% 
  ggplot(aes(x = datetime , y = presence)) +
  geom_line()
# autospectrum
Reg_presence_ts %>% 
  select(presence) %>% 
  unlist %>% 
  ts() %>% 
  # spectral density
  astsa::mvspec(spans = 5) 

# =====================================
# Naive Bayes model (binaary presence)
# =====================================
nb_airport_reg <- OI_airport_reg_history %>% 
  naive_bayes(presence ~ wday + hour.seg , data = .)
# predicted presence
merge(factor(1:7) , 
      cut(hour_intervals_break , hour_intervals_break , right = FALSE)) %>% 
  rename(wday = x , hour.seg = y) %>% 
  filter(!is.na(hour.seg)) %>% 
  # model prediction
  mutate(p_presence = predict(nb_airport_reg , . , type = "prob")[,"1"]) %>% 
  # transform variables for visualization
  mutate(hour.seg = factor(hour.seg , levels = rev(levels(hour.seg)))) %>% 
  ggplot(aes(x = wday , y = hour.seg , fill = p_presence)) +
  geom_raster() +
  scale_fill_gradient2(low = "hotpink2" , mid = "white" ,  high = "dodgerblue3" , 
                       midpoint = 0.5 , limits = c(0,1)) +
  labs(x = "week of the day" , y = "hour (interval)" , fill = "presence \nprobability" , 
       title = paste("Expected presence probability of" , OI_registration , "at" , OI_airport) , 
       subtitle = "Probability estimated with conditional probability \nby Naive Bayes model") +
  theme_minimal() 
  


