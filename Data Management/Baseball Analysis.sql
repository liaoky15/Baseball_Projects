-------- Phase 4 --------

-- Which player hit the most HR for each team?
WITH MostHR AS(
	SELECT t.TeamName, p.name as Name, HR, max(HR) over(partition by t.TeamID) as MostHRinTeam
	FROM player_batting pb JOIN players p ON pb.PlayerID = p.PlayerID
	JOIN teams t ON pb.TeamID = t.TeamID
)
SELECT TeamName, Name, HR FROM MostHR
WHERE HR = MostHRinTeam
ORDER BY MostHRinTeam DESC;


-- Who is the most frequently traded player in the 2023 season?
SELECT *, TeamCount - 1 as TradeCount
FROM (
    SELECT p.playerID, p.Name, count(p.PlayerID) as TeamCount
    FROM players p JOIN player_batting pb ON p.PlayerID = pb.PlayerID
    GROUP BY p.playerID, p.Name
    UNION
    SELECT p.playerID, p.Name, count(p.PlayerID) as Count
    FROM players p JOIN player_pitching pp ON p.PlayerID = pp.PlayerID
    GROUP BY p.playerID, p.Name
) AS combined_data
WHERE TeamCount >= 3
ORDER BY TeamCount DESC;

-- Who has the highest hitting percentage in each age level? List out the leaders and the average of each age level.
WITH highestBA AS(
	SELECT age, name, BA, max(BA) over(partition by age) as highestBA
	FROM player_batting pb JOIN players p ON p.PlayerID = pb.PlayerID
	ORDER BY age
)
SELECT age, name, highestBA
FROM highestBA
WHERE BA = highestBA;

-- Does successful rate of challenges by the managers translate to wins? List out number of wins and calculate the rate.
SELECT Name, TeamID, (wines/games) as WinRate, (Overturned/Challenges) as SuccessRate,
	RANK() OVER (ORDER BY Overturned/Challenges DESC) as SuccessRateRanking,
    RANK() OVER (ORDER BY wines/games DESC) as WinRateRanking
FROM manager_records mr JOIN managers m ON mr.managerID = m.ManagerID
WHERE (Overturned/Challenges) IS NOT NULL
ORDER BY SuccessRateRanking;

-- Does lower Batting Park Factor really tie with lower batting averages? (higher the BPF, more a hitter's park)
-- this is a bad question as BA contains both home and away games, so its not a good way to compare.
SELECT tmo.teamID, BattingParkFactor,
	rank() over(order by BattingParkFactor) as BPF_low_Ranking,
    BA, rank() over(order by BA desc) as BA_ranking,
    HR, rank() over(order by HR desc) as HR_ranking
FROM team_operations tmo JOIN team_batting tb ON tmo.teamID = tb.teamID
ORDER BY BattingParkFactor;

-- Do more fielding errors lead to more losses?
SELECT r.teamID, errors, 
	rank() over(order by errors) as error_rankings,
    wins/r.games as WinRate,
    rank() over(order by wins/r.games desc) as WinRate_rankings
FROM team_fielding tf JOIN (
	SELECT teamID, sum(games) as Games, sum(Wines) as Wins, sum(losses) as Losses
	FROM manager_records
	GROUP BY TeamID
) r ON tf.teamID = r.TeamID
Order by error_rankings;

-- List out each team’s Runs per game and Runs allowed per game. How does this margin impact the result of games?
SELECT tp.teamID, RunScoresPerGame, RunsAgainstPerGame, round(RunScoresPerGame - RunsAgainstPerGame,2) as PointDiff,
	r.Wins, r.Losses, r.wins/r.games as WinRate,
    rank() over(order by wins/r.games desc) as WinRate_rankings
FROM team_pitching tp JOIN team_batting tb ON tp.TeamID = tb.TeamID JOIN (
	SELECT teamID, sum(games) as Games, sum(Wines) as Wins, sum(losses) as Losses
	FROM manager_records
	GROUP BY TeamID
) r ON tp.teamID = r.TeamID
ORDER BY PointDiff DESC;

-- Does Runners Left On Base impact Runs scored per game? List these two columns out for each team.
SELECT teamID, RunScoresPerGame, LOB,
	rank() over(order by RunScoresPerGame desc) as score_rankings
FROM team_batting
ORDER BY LOB DESC;

-- Which player (non-pitcher) played the most game not starting?
SELECT Name, pf.TeamID, pf.Games - GameStarted as gamesNotStarting, pf.Pos_Summary
FROM player_fielding pf JOIN players p ON pf.PlayerID = p.PlayerID
WHERE Pos_Summary <> 'P' AND Pos_Summary <> '1'
ORDER BY gamesNotStarting DESC
LIMIT 1;

-- List out any player who has appeared as both batter and pitcher and their stats(with minimun AB or IP).
SELECT Name, pp.TeamID, AB, BA, IP, ERA, Pos_Summary FROM player_batting pb JOIN player_pitching pp ON pb.PlayerID = pp.PlayerID AND pb.TeamID = pp.TeamID
JOIN players p ON pp.PlayerID = p.PlayerID
WHERE BA IS NOT NULL
AND (AB > 100 OR IP > 50)
ORDER BY AB DESC, IP DESC;


