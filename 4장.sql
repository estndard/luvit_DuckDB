-- 4장 DuckDB SQL로 EPL 데이터 조작하기

-- 4.2 DML로 다루는 선수, 팀, 경기 데이터 조회


-- P116
FROM players
SELECT firstName AS 이름, lastName AS 성, displayHeight AS 신장, displayWeight AS 몸무게;

-- P116
FROM teams;

-- P117
FROM teams
SELECT * EXCLUDE (teamId, abbreviation);

-- P118
FROM teams
SELECT * EXCLUDE (teamId, abbreviation) RENAME (location AS 위치, name AS 이름);

-- P119
FROM venues
SELECT DISTINCT country, city;

-- P121
FROM standings
WHERE teamRank = 1;

--P122
FROM teamroster
WHERE position = 'Forward' and teamName = 'Tottenham Hotspur' and seasonType = 12654;

-- P122
FROM fixtures
WHERE seasonType = 12654 and attendance BETWEEN 10000 and 20000;

-- P123
FROM venues
WHERE venueId IN ('8480', '6020');

-- P124
FROM players
WHERE citizenship ILIKE '%south korea%';

-- P126
FROM lineup_2024_EPL
SELECT formation, winner, count(DISTINCT eventId)
WHERE seasonType = 12654 AND teamId = 367 AND starter = 1
GROUP BY ALL;

-- P127
FROM teamroster
SELECT teamName, position, count(*)
WHERE seasonType = 12654
GROUP BY ALL
HAVING teamName IN ('Manchester United', 'Tottenham Hotspur');

-- P128
FROM teamroster
SELECT teamName, position, count(*) AS "선수 수"
WHERE seasonType = 12654
GROUP BY ALL
HAVING teamName in ('Manchester United', 'Tottenham Hotspur')
ORDER BY teamName, "선수 수" DESC;

-- P130
FROM playerStats_2024_EPL
    JOIN players USING (athleteId)
SELECT displayName, 유효슛: shotsOnTarget_value, 골: totalGoals_value, "골 성공률":round
(골/유효슛, 2)
WHERE seasonType = 12654
ORDER BY 골 DESC, 유효슛 DESC
LIMIT 5;

-- P131
INSERT INTO playerStats_2024_EPL
    FROM ‘.\playerStats_data\playerStats_2024_UEFA.CHAMPIONS.csv’;

-- P132
CREATE TABLE tbl (title VARCHAR, first VARCHAR, second VARCHAR);
INSERT INTO tbl BY POSITION (SELECT 'BY POSITION' AS title, 'SECOND' AS second, 'FIRST' AS first);
INSERT INTO tbl BY NAME (SELECT 'BY NAME' AS TITLE, 'SECOND' AS second, 'FIRST' AS first);
SELECT * FROM tbl;

-- P133
ALTER TABLE standings ADD COLUMN teamName varchar;
UPDATE standings SET teamName = teams.displayName
FROM teams
WHERE standings.teamId = teams.teamId;

-- P133
SELECT teamName, * EXCLUDE teamName
FROM standings
LIMIT 5;

-- P 134
DELETE FROM playerStats_2024_EPL WHERE seasonType IN (12885, 12783);

-- P136
FROM duckdb_tables
SELECT sql
WHERE table_name = 'leagues';

-- P136
CREATE TABLE leagues(seasonType BIGINT, "year" BIGINT, seasonName VARCHAR, seasonSlug VARCHAR, 
leagueId BIGINT, midsizeName VARCHAR, leagueName VARCHAR, leagueShortName VARCHAR);

-- P137
CREATE TABLE leagues AS (
FROM './base_data/leagues.csv');

-- P137
CREATE OR REPLACE TABLE leagues AS (
FROM './base_data/leagues.csv');

-- P138
CREATE OR REPLACE VIEW playerstats AS (
    FROM playerStats_2024_EPL
        JOIN players USING (athleteId)
        JOIN teams USING (teamId)
        JOIN leagues USING (seasonType)
    SELECT teams.displayName as teamName, players.displayName as playerName,
        leagues.leagueName, playerStats_2024_EPL.* EXCLUDE (seasonType, teamId, athleteId, league)
);

-- P 139
FROM playerstats
SELECT #1, #2, ownGoals_value, redCards_value, yellowCards_value
WHERE leagueName = 'English Premier League'
ORDER BY ownGoals_value DESC, redCards_value DESC, yellowCards_value DESC
LIMIT 5;

-- P140
CREATE OR REPLACE VIEW diamonds_view AS (
    FROM read_parquet('./diamonds.parquet'));

-- P140
FROM diamonds_view
SELECT cut, color, "평균 캐럿":avg(carat).round(2), "평균 가격":avg(price).round(2)
WHERE depth < 58 AND price > 320
GROUP BY cut, color
ORDER BY cut, color

-- P141
ALTER TABLE standings DROP COLUMN teamName;


-- P142
ALTER TABLE standings ALTER COLUMN year TYPE varchar;
FROM standings;

-- P 142
ALTER VIEW playerstats RENAME TO ENG_24_playerstats;

-- P 142
FROM playerstats;

-- P143
DROP TABLE diamonds;

-- P143
FROM diamonds;

-- P146
FROM keyevents_2024_EPL
JOIN keyEventDescription USING (keyEventTypeId)
SELECT period, keyEventName, count() as Goals
WHERE keyEventName ILIKE '%goal%'
GROUP BY ALL
ORDER BY #1, #3 DESC;

--p148
FROM playerStats_2024_EPL
LEFT JOIN players USING (athleteId)
SELECT count()

-- P148
FROM playerStats_2024_EPL
LEFT JOIN players USING (athleteId)
SELECT athleteId
WHERE fullName IS NULL;

-- P150
FROM players
RIGHT JOIN lineup_2024_EPL USING (athleteId)
SELECT * RENAME lineup_2024_EPL.jersey AS jersey_1;

-- P 151
FROM teams
FULL JOIN teamroster using (teamId);

-- P152
FROM standings
NATURAL JOIN teams;

-- P152
DESC (FROM standings
    NATURAL JOIN teams);

-- P153
FROM standings
SEMI JOIN teams USING (teamId);

-- P153
DESC (FROM standings
    SEMI JOIN teams USING (teamId));

--P154
FROM playerStats_2024_EPL
ANTI JOIN players USING (athleteId)
SELECT count();

-- P156
FROM './playerStats_data/playerStats_2024_UEFA.CHAMPIONS.CSV'
SELECT seasonType, year, league, teamId
UNION
FROM './playerStats_data/playerStats_2024_UEFA.EURO.CSV'
SELECT seasonType, year, league, teamId;

--P157
(FROM './playerStats_data/playerStats_2024_UEFA.CHAMPIONS.CSV'
SELECT seasonType, year, league, teamId
LIMIT 5)
UNION ALL BY NAME
(FROM './playerStats_data/playerStats_2024_UEFA.EURO.CSV'
SELECT teamId, league, year, seasonType
LIMIT 5);

-- P157
FROM './playerStats_data/playerStats_2024_UEFA.CHAMPIONS.CSV'
SELECT seasonType, year, league, teamId
UNION ALL
FROM './playerStats_data/playerStats_2024_UEFA.EURO.CSV'
SELECT teamId, league, year, seasonType, athleteId;

-- P158
(FROM './playerStats_data/playerStats_2024_UEFA.CHAMPIONS.CSV'
SELECT seasonType, year, league, teamId
LIMIT 5)
UNION ALL BY NAME
(FROM './playerStats_data/playerStats_2024_UEFA.EURO.CSV'
SELECT teamId, league, year, seasonType, athleteId
LIMIT 5);

-- P159
FROM lineup_2024_EPL
SELECT athleteId
WHERE seasonType = '12654'
INTERSECT
FROM players
SELECT athleteId
WHERE citizenship = 'South Korea';

-- P160
FROM players
JOIN teamroster USING (athleteId)
SELECT DISTINCT athleteId, teamId
WHERE seasonType = '12654'
EXCEPT
FROM lineup_2024_EPL
SELECT DISTINCT athleteId, teamId
WHERE seasonType = '12654';
