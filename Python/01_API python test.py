#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
flightradar API

@author: liutzuli
"""
# ==================================
# flightradar24
# ==================================


import flightradar24          # pip install flightradar24
fr = flightradar24.Api()

# Getting airports list
airports = fr.get_airports()


# Getting flights list
airline = 'THY' # Turkish Airlines
flights = fr.get_flights(airline)

# Getting flight details

flight = fr.get_flight("CI61")

fr.get_flight("CI61")



# ==================================
# pyflightdata
# ==================================

from pyflightdata import FlightData  # pip install pyflightdata

# The main interface to pyflightdata is the FlightData class
f = FlightData()
# This abstracts all the data access mechanism 
# and also maintains the authenticated session to flightradar24 for users who have a paid membership.
f.login("crab6v8521@gmail.com","xu.6y3xu4b04801015")
f.logout()

# search flight
f.get_flights("CI61")

# Flight history by flight number
f.get_history_by_flight_number('CI61')[-5:]
f.get_flights_from_to(origin="FRA" , destination="TPE")

# Flight history by registration
History_B18007 = f.get_history_by_tail_number("B-18007")
History_B18918 = f.get_all_available_history_by_tail_number("B-18918")

History_B18007[0].keys()
History_B18918[0]["identification"]       # flight number
History_B18918[0]["status"]               # live? 
History_B18918[0]["aircraft"]
History_B18918[0]["owner"]
History_B18918[0]["aircraft"]
History_B18918[0]["airport"]              # origin, destination 
History_B18918[0]["time"]                 # scheduled, actual time of departure/ arrival




# Information about the aircraft (like age)
f.get_info_by_tail_number("B-16701")
f.get_info_by_tail_number("B-16711")



# get countries
f.get_countries()[:5]
# get airlines
airlines = f.get_airlines()
airlines[0]["title"]

# get airports
f.get_airports('Taiwan')
# get airport arrivals and departures
TSA_arrivals = f.get_airport_arrivals("TSA")
len(TSA_arrivals)
TSA_departures = f.get_airport_departures("TSA")
TSA_departures[0]
# get airport onground
f.get_airport_onground("TSA")
# get airport details 
f.get_airport_details("TSA")
f.get_airport_metars("TSA")
f.get_airport_metars_hist("TSA")
f.get_airport_weather("TSA")


# get fleet  (pass the airline-code from get_airlines)
f.get_fleet('ci-cal')





