-- 6 DuckDB 전용 SQL로 EPL 데이터 활용하기

-- 6.1 DuckDB용 데이터 타입

-- P 230
CREATE OR REPLACE TEMP TABLE struct AS (
   SELECT {
      'birds': {'yes': 'duck', 'maybe': 'goose', 'huh': NULL, 'no': 'heron'},
      'aliens': NULL,
      'amphibians': {'yes': 'frog', 'maybe': 'salamander', 'huh': 'dragon', 'no': 'toad'}
   } AS s);
FROM struct;

-- P 230
FROM struct
SELECT s.birds.yes, s['amphibians']['huh'];

-- P 230
FROM (
   FROM struct
   SELECT unnest(s))
SELECT unnest(birds);

-- P231
SELECT first_array: [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}],
   second_array:array_value(1, 2, 3);

-- P231
FROM(
   SELECT first_array: [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}], second_array:array_value(1, 2, 3))
SELECT first_array[1].b, second_array[2]

-- P232
CREATE TYPE DOW AS ENUM ('Sun.', 'Mon.', 'Tue.', 'Wed.', 'Thu.', 'Fri.', 'Sat.');

-- P232
ALTER TABLE fixtures ADD COLUMN weekday DOW;
UPDATE fixtures SET
weekday = CASE WHEN extract('dayofweek' from "date") == 0 THEN 'Sun.'
   WHEN extract('dayofweek' from "date") == 1 THEN 'Mon.'
   WHEN extract('dayofweek' from "date") == 2 THEN 'Tue.'
   WHEN extract('dayofweek' from "date") == 3 THEN 'Wed.'
   WHEN extract('dayofweek' from "date") == 4 THEN 'Thu.'
   WHEN extract('dayofweek' from "date") == 5 THEN 'Fri.'
   WHEN extract('dayofweek' from "date") == 6 THEN 'Sat.'
   END;

-- P233
FROM fixtures
SELECT date, weekday;

-- 6.2 DuckDB용 SQL 문법

-- P234
CREATE TABLE tbl (a char(1) PRIMARY KEY, b char(1));
CREATE TABLE tbl (a INTEGER PRIMARY KEY, b INTEGER);

-- P235
CREATE OR REPLACE TABLE tbl (a INTEGER PRIMARY KEY, b INTEGER);

-- P235
INSERT INTO tbl VALUES (1, 300);
INSERT INTO tbl VALUES (1, 500);

-- P235
INSERT OR REPLACE INTO tbl VALUES (1, 500);
FROM tbl;

-- P236
CREATE OR REPLACE TABLE tbl (a INTEGER PRIMARY KEY, b INTEGER, c char(1));
INSERT INTO tbl VALUES ('a', 42, 32);

-- P236
INSERT INTO tbl BY NAME (SELECT 'a' AS c, 42 AS b, 32 AS a);
SELECT * FROM tbl;

-- P237
INSERT OR IGNORE INTO tbl VALUES (32, 84, 'b');
FROM tbl;

-- P237
INSERT INTO tbl VALUES (1, 84, 'a') ON CONFLICT DO NOTHING;

-- P238
DESCRIBE teams;

-- P238
DESC FROM keyEvents_2024_EPL
   JOIN keyEventDescription USING (keyEventTypeId)
WHERE athleteId = 149945

-- P239
SUMMARIZE standings;

-- P241
FROM fixtures
SELECT seasonType, leagueId, homeTeamId, homeTeamWinner, count(*)
WHERE seasonType = 12654
GROUP BY ALL

-- P241
FROM fixtures
SELECT seasonType, leagueId, homeTeamId, homeTeamWinner, count(*)
WHERE seasonType = 12654
GROUP BY seasonType, leagueId, homeTeamId, homeTeamWinner

-- P242
FROM standings
SELECT seasonType, year, leagueId, last_matchDateTime, 'NO.' || teamRank AS teamRank, teamId, gamesPlayed, wins, ties, losses, points, gf, ga, gd, deductions, clean_sheet, form, next_opponent, next_homeAway, next_matchDateTime, timeStamp

-- P242
FROM standings
SELECT * REPLACE 'NO.' || teamRank as teamRank

-- P243
FROM standings
SELECT 순위: teamRank, "경기 수": gamesPlayed, 승: wins, 무: ties, 패: losses, 승점: points, 
   득점: ga, 실점: gf, 득실차: gd
WHERE seasonType = 12654;

-- P243
FROM standings
SELECT teamRank AS 순위, gamesPlayed AS "경기 수", wins AS 승, ties AS 무, losses AS 패, 
   points AS 승점, ga AS 득점, gf AS 실점, gd AS 득실차
WHERE seasonType = 12654;

-- 6.3 DuckDB용 질의 기능

-- P244
FROM fixtures
   JOIN home: teams ON (homeTeamId = home.teamId)
   JOIN away: teams ON (awayTeamId = away.teamId)
SELECT HomeTeam: home.displayname, AwayTeam: away.displayname,
   sum(homeTeamWinner) AS HomeWins, sum(awayTeamWinner) AS AwayWins
WHERE seasonType = 12654 AND HomeTeam = 'Tottenham Hotspur'
GROUP BY HomeTeam, AwayTeam
HAVING HomeWins != 0 OR AwayWins !=0
ORDER BY #2;

-- P245
FROM leagues
SELECT columns(*)||'_EPL_Data',
WHERE seasonType = 12654;

-- P246
SELECT MIN(COLUMNS(*))
FROM leagues;

-- P246
FROM teamRoster
SELECT COLUMNS (* EXCLUDE (seasonType, midsizeName)), seasonType, midsizeName
WHERE seasonType = 12654

-- P247
FROM teamStats
SELECT AVG(COLUMNS (* EXCLUDE (seasonType, eventId, teamId, teamOrder, updateTime))).ROUND(1)
WHERE seasonType = 12654

-- P248
FROM teamStats
SELECT COUNT()
WHERE COLUMNS(*) IS NOT NULL


-- P248
FROM playerStats_2024_EPL
SELECT AVG(COLUMNS('value$')).ROUND(1)

-- P249
FROM playerStats_2024_EPL
   JOIN teams USING (teamId)
   JOIN players USING (athleteId)
SELECT teams.displayName AS "팀 이름", players.displayName AS "선수 이름",
   redCards_value AS 레드카드, (레드카드 * 5) AS R인덱스,
   yellowCards_value AS 옐로카드, R인덱스 + (옐로카드 * 3) AS RY인덱스,
   foulsCommitted_value AS 파울, RY인덱스 + (파울 * 1) AS RYFc인덱스,
   foulsSuffered_value AS 파울유발, RYFc인덱스 + (파울유발 * -1) AS 파울인덱스
WHERE COLUMNS('^foul') !=0
ORDER BY 파울인덱스 DESC










