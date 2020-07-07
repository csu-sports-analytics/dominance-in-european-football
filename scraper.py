import requests
from bs4 import BeautifulSoup
import pandas as pd
from h5py.h5o import link
from unittest.mock import inplace

# Start at 2014-15 b/c that is the first year that sports-reference put UCL in Scores/Fixtures
years = ['2014-2015', '2015-2016', '2016-2017', '2017-2018', '2018-2019', '2019-2020']
def getTeams():
    allTeams = pd.DataFrame()
    for year in years:
        url = "https://fbref.com/en/comps/Big5/" + year + "/Big-5-European-Leagues-Stats"
        page = requests.get(url)
        soup = BeautifulSoup(page.content, 'html.parser')
        stats = ['squad', 'country', 'rank', 'games', 'wins', 'draws', 'losses',
                'goals_for', 'goals_against', 'goal_diff', 'points', 'points_avg']
        stats_list = [[td.getText() for td in soup.findAll('td', {'data-stat': stat})] for stat in stats]
        year_df = pd.DataFrame(stats_list).T
        year_df = year_df.assign(Season = year)
        allTeams = pd.concat([allTeams, year_df]) 
        
    return allTeams

def csvTeamDump():
    df = getTeams()
    df = df.set_axis(['Team', 'Country', 'Rank', 'G', 'W', 'D', 'L', 'GF', 'GA', 'GD', 'Pts', 'AvgPts', 'Season'],
                     axis = 1, inplace = False)
    df.to_csv("/Users/quinnjohnson/Desktop/PythonStat/my_project/big5teams.csv")
    
csvTeamDump()


def getLinks():
    link_dict = dict()
    count = 0
    for year in years:
        url = "https://fbref.com/en/comps/Big5/" + year + "/Big-5-European-Leagues-Stats"
        page = requests.get(url)
        soup = BeautifulSoup(page.content)
        table = soup.find("tbody")
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
    for ind in range(0, len(team_links)):
        current_team = allTeams.iloc[ind,0]
        link = team_links.get(ind)
        url = "https://fbref.com" + link
        page = requests.get(url)
        soup = BeautifulSoup(page.content, 'html.parser')
        stats = ['comp', 'round', 'dayofweek', 'venue', 
                 'result', 'goals_for', 'goals_against', 'opponent']
        stats_list = [[td.getText() for td in soup.findAll('td', {'data-stat': stat})] for stat in stats]
        team_df = pd.DataFrame(stats_list).T
        for i, row in team_df.iterrows():
            if (i > 20 and team_df.iloc[i, 1] == "Matchweek 1"):
                end_row = i
        team_df.drop(range(end_row, len(team_df.index)), inplace = True)
        dates = pd.DataFrame([th.getText() for th in soup.findAll('th', {'data-stat': 'date'})])
        dates.drop(range(end_row+1, len(dates.index)), inplace = True)
        dates.drop(0, inplace = True)
        team_df = team_df.assign(date = dates.values)
        team_df = team_df.assign(team = current_team)
        full_sched = full_sched.append(team_df, ignore_index= True)
        
    return full_sched

def csvSchedDump():
    df = getSched()
    df = df.set_axis(['Comp', 'Round', 'Day', 'Venue', 'Result', 'GF', 'GA', 'Opp', 'Date', 'Team'],
                     axis = 1, inplace = False)
    df.to_csv("/Users/quinnjohnson/Desktop/PythonStat/my_project/big5sched.csv")
    
csvSchedDump()