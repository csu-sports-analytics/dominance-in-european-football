library(tidyverse)
library(stringi)

#### CLEANING SCHEDULE ####
sched <- read_csv("big5sched.csv")

# Removing first column (indexing)
sched <- sched[,-1]

# Reordering columns
sched <- sched %>%
  select(Date, Day, Comp, Round, Venue, Team, Opp, Result, GF, GA)

# Remove games from other dataframes that slipped through the cracks
# For some reason only happened with 4 Serie A teams
sched <- sched %>%
  filter(!(Comp == ""))

# Games played in international competitions have opponents with country
# codes proceeding the team name. This will remove those.
for(i in 1:nrow(sched)){
  # Identifying first instance of an uppercase letter
  cap_loc <- regexpr("[[:upper:]]", sched$Opp[i])[[1]]
  # Shortening the string to begin at the uppercase letter
  sched$Opp[i] <- str_sub(sched$Opp[i], start = cap_loc)
}

# Some games went to penalty kicks, which are denoted by "#G (#PK)" in GF/A
# This means we can't use numeric class for goals
# Will instead remove penalty kicks and just let a win in pk's by shown
# by a team having a "W" or "L" in Result, rather than falsely adding a goal to a game
# to show a pk winner.

# If a parentheses (penalty kicks) is detected, shorten the string to be just the
# first number (goals in play). 
sched$GF <- ifelse(str_detect(sched$GF, "\\("), str_sub(sched$GF, end = 1), sched$GF)
# Now we can change the class to numeric
sched$GF <- as.numeric(sched$GF)
sched$GA <- ifelse(str_detect(sched$GA, "\\("), str_sub(sched$GA, end = 1), sched$GA)
sched$GA <- as.numeric(sched$GA)

# Adding season for ease of later analysis
sched$Season <- case_when(
  sched$Date > "2014-07-01" & sched$Date < "2015-07-01" ~ "2014-2015",
  sched$Date > "2015-07-01" & sched$Date < "2016-07-01" ~ "2015-2016",
  sched$Date > "2016-07-01" & sched$Date < "2017-07-01" ~ "2016-2017",
  sched$Date > "2017-07-01" & sched$Date < "2018-07-01" ~ "2017-2018",
  sched$Date > "2018-07-01" & sched$Date < "2019-07-01" ~ "2018-2019",
  sched$Date > "2019-07-01" & sched$Date < "2020-08-01" ~ "2019-2020"
) 

#Removing games that are missing scores/haven't been played
sched <- na.omit(sched)

#Changing some variables to factors
sched$Team <- as.factor(sched$Team)
sched$Opp <- as.factor(sched$Opp)
sched$Result <- as.factor(sched$Result)
sched$Season <- as.factor(sched$Season)
sched$Comp <- as.factor(sched$Comp)
sched$Venue <- as.factor(sched$Venue)

#### CLEANING TEAMS ####
teams <- read_csv("big5teams.csv")

# Removing first column (indexing)
teams <- teams[,-1]

# Removing country codes
for(i in 1:nrow(teams)){
  # Identifying first instance of an uppercase letter
  cap_loc <- regexpr("[[:upper:]]", teams$Country[i])[[1]]
  # Shortening the string to begin at the uppercase letter
  teams$Country[i] <- str_sub(teams$Country[i], start = cap_loc)
}


