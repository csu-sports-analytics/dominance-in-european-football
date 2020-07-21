import requests
from bs4 import BeautifulSoup
import pandas as pd
from h5py.h5o import link
from unittest.mock import inplace

# Start at 2014-15 b/c that is the first year that sports-reference put UCL in Scores/Fixtures
years = ['2014-2015', '2015-2016', '2016-2017', '2017-2018', '2018-2019', '2019-2020']
def getTeams():
    #Initializing the teams data frame
    allTeams = pd.DataFrame()
    for year in years:
        #Adding year to the url and getting the wedpage
        url = "https://fbref.com/en/comps/Big5/" + year + "/Big-5-European-Leagues-Stats"
        page = requests.get(url)
        soup = BeautifulSoup(page.content, 'html.parser')
        #Setting which stats to gather for each team
        stats = ['squad', 'country', 'rank', 'games', 'wins', 'draws', 'losses',
                'goals_for', 'goals_against', 'goal_diff', 'points', 'points_avg']
        #Gathering the stats
        stats_list = [[td.getText() for td in soup.findAll('td', {'data-stat': stat})] for stat in stats]
        #Building the data frame
        year_df = pd.DataFrame(stats_list).T
        #Adding the year to the data frame
        year_df = year_df.assign(Season = year)
        #Adding each year to the overall data frame
        allTeams = pd.concat([allTeams, year_df]) 
        
    return allTeams

def csvTeamDump():
    df = getTeams()
    df = df.set_axis(['Team', 'Country', 'Rank', 'G', 'W', 'D', 'L', 'GF', 'GA', 'GD', 'Pts', 'AvgPts', 'Season'],
                     axis = 1, inplace = False)
    df.to_csv("/Users/quinnjohnson/Desktop/SportStatSummer20/dominance-in-european-football/big5teams.csv")

csvTeamDump()


def getLinks():
    #Initializing the link dictionary
    link_dict = dict()
    count = 0
    for year in years:
        #Adding the year to the link and getting the webpage
        url = "https://fbref.com/en/comps/Big5/" + year + "/Big-5-European-Leagues-Stats"
        page = requests.get(url)
        soup = BeautifulSoup(page.content)
        table = soup.find("tbody")
        #Adding team link to the dictionary
        for row in table.findAll('td', {"data-stat": "squad"}):
            for a in row.find_all('a'):   
                link = a['href'].strip()   
                link_dict[count] = link
                count = count + 1
    
    return link_dict         
    
    
def getSched():
    allTeams = getTeams()
    team_links = getLinks()
    full_sched = pd.DataFrame()
for ind in range(0,1): #range(0, len(team_links)):
    #Setting team
    current_team = allTeams.iloc[ind,0]
    #Gathering link for schedule
    link = team_links.get(ind)
    #Building webpage to be scraped
    url = "https://fbref.com" + link
    page = requests.get(url)
    soup = BeautifulSoup(page.content, 'html.parser')
    #Creating list of stats to be gathered from the schedule
    stats = ['comp', 'round', 'dayofweek', 'venue', 
             'result', 'goals_for', 'goals_against', 'opponent']
    #Gathering those stats from the schedule
    stats_list = [[td.getText() for td in soup.findAll('td', {'data-stat': stat})] for stat in stats]
    #Forming the data frame of the schedule
    team_df = pd.DataFrame(stats_list).T
    #Determining which row ends the "All Competition" tab of the webpage
    for i, row in team_df.iterrows():
        if (i > 20 and team_df.iloc[i, 1] == "Matchweek 1"):
            end_row = i
    #Removing rows that are after the "All Competitions" schedule
    team_df.drop(range(end_row, len(team_df.index)), inplace = True)
    #Getting dates of the games and cleaning them
    dates = pd.DataFrame([th.getText() for th in soup.findAll('th', {'data-stat': 'date'})])
    dates.drop(range(end_row+1, len(dates.index)), inplace = True, axis = 0)
    dates.drop(0, inplace = True, axis = 0)
    #Adding dates to the data frame
    team_df = team_df.assign(date = dates.values)
    #Adding the name of the team to the data frame
    team_df = team_df.assign(team = current_team)
    #Adding the team's data frame to the overall large schedule data frame
    full_sched = full_sched.append(team_df, ignore_index= True)
        
    return full_sched

def csvSchedDump():
    df = getSched()
    df = df.set_axis(['Comp', 'Round', 'Day', 'Venue', 'Result', 'GF', 'GA', 'Opp', 'Date', 'Team'],
                     axis = 1, inplace = False)
    df.to_csv("/Users/quinnjohnson/Desktop/SportStatSummer20/dominance-in-european-football/big5sched.csv")
    
csvSchedDump()
