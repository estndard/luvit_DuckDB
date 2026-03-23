-- 5장 고급 SQL로 EPL 데이터 분석하기

-- 5.1 날짜와 시간 함수로 분석하는 EPL 경기 결과

-- P163
SELECT '2025-01-01'::DATE;

-- P165
SELECT strptime('01-march-2025', '%d-%B-%Y')::DATE AS "DATE";

-- P165
SELECT strptime('11:30:00.123456', '%H:%M:%S.%n')::TIME AS "TIME";

-- P166
SELECT '2025-03-20 11:30:00.123456789'::TIMESTAMP AS "TIMESTAMP";

-- P167
SELECT INTERVAL 1 YEAR as '1 Year', INTERVAL (random() * 10) YEAR AS 'Random Year',
INTERVAL '1 month 1 day' AS 'String Interval', '16 months'::INTERVAL AS 'Inverval conversion';

-- P168
SELECT
    DATE '2025-03-31' + 10 AS 'AFTER 10 DAYS',
    DATE '2025-03-31' + INTERVAL 10 months AS 'AFTER 10 MONTHS',
    DATE '2025-03-31' - 5 AS 'BEFORE 5 DAYS',
    DATE '2025-03-31' - DATE '2025-02-28' AS 'DIFFERENCE TWO DATES',
    DATE '2025-03-31' - INTERVAL 10 months AS 'BEFORE 10 MONTHS',
    DATE '2025-03-31' + INTERVAL 5 DAY + INTERVAL 2 MONTH + INTERVAL 1 YEAR - INTERVAL 200 days
AS 'INTERVAL'

-- P169
FROM fixtures
SELECT date_part('year', "date") AS 연도, date_part('month', "date") AS 월,
   count(*) AS "경기 수", sum(homeTeamScore) AS "홈팀 골", sum(awayTeamScore) AS "원정팀 골"
WHERE seasonType = '12654'
GROUP BY 연도, 월
ORDER BY #1, #2;

-- P170
FROM fixtures
SELECT extract('dayofweek' from "date") AS 요일,
   count(*) AS "경기 수", sum(homeTeamWinner) AS "홈팀 승", sum(awayTeamWinner) AS "원정팀 승",
   round("홈팀 승" / "경기 수", 2) AS "홈팀 승률", 
   round("원정팀 승" / "경기 수", 2) AS "원정팀 승률"
WHERE seasonType = '12654'
GROUP BY 요일
ORDER BY #1;

-- 5.2 서브쿼리로 분석하는 EPL순위와 득점

-- P173
FROM playerStats_2024_EPL
   JOIN players USING (athleteId)
SELECT positionName, count()
WHERE totalGoals_value > (
   FROM playerStats_2024_EPL
   SELECT avg(totalGoals_value)
   WHERE totalGoals_value > 0 AND seasonType = '12654')
AND seasonType = '12654'
GROUP BY positionName;

-- P174
FROM teams
WHERE teamId IN (
   FROM standings
   SELECT teamId
   WHERE seasonType = '12654' and teamRank <= 4);

-- P175
FROM (FROM standings
   SELECT teamId, gf
   WHERE seasonType = '12654') AS goal_for
JOIN (FROM teamstats
   SELECT teamId, sum(penaltyKickGoals) AS penaltyKickGoals
   WHERE seasonType = '12654'
   GROUP BY teamId) AS penalty USING (teamId)
JOIN (FROM teams
   SELECT teamId, displayName) AS team USING (teamId)
SELECT displayName, gf AS 전체골, penaltyKickGoals AS 페널티골, 
   round(penaltyKickGoals/gf*100, 1)||'%' AS 패털티골비율
ORDER BY penaltyKickGoals/gf DESC, #3 DESC, #2 DESC;

-- P176
SELECT displayName, sum(gf) AS Goals,
   (FROM standings
      SELECT sum(gf)
      WHERE seasonType = '12654') AS League_Total, round(AVG(gf / (
         FROM standings
         SELECT sum(gf)
         WHERE seasonType = '12654') * 100), 2) AS PCT_Goals
FROM standings
   JOIN teams USING (teamId)
WHERE seasonType = '12654'
GROUP BY displayName
ORDER BY PCT_Goals DESC;

-- P178
FROM fixtures
   JOIN teams ON teamId = homeTeamId
SELECT displayName, count()
WHERE homeTeamScore > (
   FROM standings
      JOIN teams USING (teamId)
   SELECT round(gf/gamesPlayed, 2) AS AVG_Goal
   WHERE seasonType = '12654' AND fixtures.homeTeamId = standings.teamId)
   AND seasonType = '12654'
GROUP BY displayName
ORDER BY #2 DESC;


--5.3 CTE로 구조화하는 EPL 득좀, 순위 분석

-- P181
WITH goal_for AS (
   FROM standings
   SELECT teamId, gf
   WHERE seasonType = '12654'),
penalty AS (
   FROM teamstats
   SELECT teamId, sum(penaltyKickGoals) AS penaltyKickGoals
   WHERE seasonType = '12654'
   GROUP BY teamId),
team AS (
   FROM teams
   SELECT teamId, displayName)
FROM goal_for
JOIN penalty USING (teamId)
JOIN team USING (teamId)
SELECT displayName, gf AS 전체골, penaltyKickGoals AS 페널티골, 
   round(penaltyKickGoals/gf*100, 1)||'%' AS 패털티골비율
ORDER BY penaltyKickGoals/gf DESC, #3 DESC, #2 DESC;

-- P182
WITH goal_sum AS(
   FROM standings
   SELECT sum(gf)
   WHERE seasonType = '12654')
SELECT displayName, sum(gf) AS Goals,
(FROM goal_sum)
AS League_Total, round(AVG(gf / (FROM goal_sum) * 100), 2) AS PCT_Goals
FROM standings
   JOIN teams USING (teamId)
WHERE seasonType = '12654'
GROUP BY displayName
ORDER BY PCT_Goals DESC;

-- P183
WITH CTE AS (
   FROM standings
   SELECT teamId
   WHERE seasonType = '12654' AND teamRank <= 4)
FROM teams
WHERE teamId IN (FROM CTE);

-- P184
WITH goal_sum AS MATERIALIZED (
   FROM standings
   SELECT sum(gf)
   WHERE seasonType = '12654')
SELECT displayName, sum(gf) AS Goals, (FROM goal_sum) AS League_Total, 
   round(AVG(gf / (FROM goal_sum) * 100), 2) AS PCT_Goals
FROM standings
   JOIN teams USING (teamId)
WHERE seasonType = '12654'
GROUP BY displayName
ORDER BY PCT_Goals DESC;

-- P186
WITH RECURSIVE factorial AS
(SELECT 1 AS n, 1 AS fact -- Anchor 질의
   UNION ALL
   SELECT n + 1, (n+1)*fact, -- 반복 질의
   FROM factorial WHERE n < 10 -- 반복 질의
)
SELECT * FROM factorial;

-- 5.4 CASE로 구분하는 EPL 경기 결과와 수익

-- P189
FROM fixtures
SELECT extract('dayofweek' from "date") AS DOW,
   CASE extract('dayofweek' from "date")
      WHEN 0 THEN '일요일'
      WHEN 1 THEN '월요일'
      WHEN 2 THEN '화요일'
      WHEN 3 THEN '수요일'
      WHEN 4 THEN '목요일'
      WHEN 5 THEN '금요일'
      ELSE '토요일' END AS 요일,
   count(*) AS "경기 수", sum(homeTeamWinner) AS "홈팀 승", sum(awayTeamWinner) AS "원정팀 승",
   round("홈팀 승" / "경기 수", 2) AS "홈팀 승률", round("원정팀 승" / "경기 수", 2) AS "원정팀 승률"
WHERE seasonType = '12654'
GROUP BY DOW, 요일
ORDER BY #1;

--P190
FROM fixtures
   JOIN teams AS home ON fixtures.homeTeamId = home.teamId
   JOIN teams AS away ON fixtures.awayTeamId = away.teamId
SELECT home.displayName AS 홈팀, away.displayName AS 원정팀,
   homeTeamScore AS 홈팀골, awayTeamScore AS 원정팀골,
CASE
   WHEN homeTeamScore > awayTeamScore THEN '홈팀승'
   WHEN homeTeamScore < awayTeamScore THEN '원정팀승'
   ELSE '무승부' END AS 경기결과
WHERE leagueId = 700 and statusId <> 1

-- P191
FROM fixtures
   JOIN teams AS home on fixtures.homeTeamId = home.teamId
   JOIN venues ON venues.venueId = fixtures.venueId
SELECT date::DATE AS 경기일, home.displayName AS 홈팀,
   venues.fullName AS "경기장 이름", attendance AS "관객 수"
   CASE
      WHEN home.displayName = 'Arsenal' THEN attendance * 194
      WHEN home.displayName = 'Chelsea' THEN attendance * 209
      WHEN home.displayName = 'Liverpool' THEN attendance * 279
      WHEN home.displayName = 'Tottenham Hotspur' THEN attendance * 172
   END AS “입장권 수익”
WHERE leagueId = 700 and
   home.displayName in ('Arsenal', 'Chelsea', 'Liverpool', 'Tottenham Hotspur')
ORDER BY 경기일;

-- P192
ALTER TABLE fixtures ADD COLUMN result varchar;
UPDATE fixtures SET result =
   CASE
      WHEN homeTeamScore > awayTeamScore THEN '홈팀승'
      WHEN homeTeamScore < awayTeamScore THEN '원정팀승'
      ELSE '무승부' END;

-- P192
FROM fixtures
SELECT homeTeamScore, awayTeamScore, result
LIMIT 5;

-- P193
FROM fixtures
SELECT avg(CASE WHEN homeTeamScore > awayTeamScore
      THEN homeTeamScore END).round(2) AS Home_Win_Goal_Home,
   avg(CASE WHEN homeTeamScore > awayTeamScore
      THEN awayTeamScore END).round(2) AS Home_Win_Goal_Away,
   avg(CASE WHEN homeTeamScore < awayTeamScore
      THEN awayTeamScore END).round(2) AS Away_Win_Away,
   avg(CASE WHEN homeTeamScore < awayTeamScore
      THEN homeTeamScore END).round(2) AS Away_Win_Home,
   avg(CASE WHEN homeTeamScore = awayTeamScore
      THEN awayTeamScore END).round(2) AS Draw_Goal
WHERE seasonType = '12654' and statusId <> 1;

-- 5.5 GROUP BY 확장으로 요약하는 EPL 공격 지표

-- P 196
FROM playerStats_2024_EPL
LEFT JOIN players USING (athleteId)
LEFT JOIN teams USING (teamId)
SELECT players.positionName, teams.displayName,
   sum(shotsOnTarget_value) AS 유효슛,
   sum(totalShots_value) AS 전체슛,
   sum(totalGoals_value) AS 전체골,
   round(전체골 / 유효슛, 2) AS 유효슛대비골수, round(전체골 / 전체슛, 2) AS 전체슛대비골수
WHERE seasonType = '12654' AND positionName IS NOT NULL AND
   teams.displayName in ('Liverpool', 'Tottenham Hotspur')
GROUP BY GROUPING SETS ((teams.displayName, players.positionName),
   (teams.displayName), (players.positionName), ())
HAVING 전체골 <> 0
ORDER BY players.positionName, teams.displayName

-- P 198
FROM playerStats_2024_EPL
LEFT JOIN players USING (athleteId)
LEFT JOIN teams USING (teamId)
SELECT players.positionName, teams.displayName,
   sum(shotsOnTarget_value) AS 유효슛,
   sum(totalShots_value) AS 전체슛,
   sum(totalGoals_value) AS 전체골,
   round(전체골 / 유효슛, 2) AS 유효슛대비골수, round(전체골 / 전체슛, 2) AS 전체슛대비골수
WHERE seasonType = '12654' and positionName IS NOT NULL AND
   teams.displayName IN ('Liverpool', 'Tottenham Hotspur')
GROUP BY CUBE (teams.displayName, players.positionName) HAVING 전체골 <> 0
ORDER BY players.positionName, teams.displayName

-- P199
FROM playerStats_2024_EPL
LEFT JOIN players USING (athleteId)
LEFT JOIN teams USING (teamId)
SELECT players.positionName, teams.displayName,
   sum(shotsOnTarget_value) AS 유효슛,
   sum(totalShots_value) AS 전체슛,
   sum(totalGoals_value) AS 전체골,
   round(전체골 / 유효슛, 2) AS 유효슛대비골수, round(전체골 / 전체슛, 2) AS 전체슛대비골수
WHERE seasonType = '12654' and positionName IS NOT NULL AND
   teams.displayName IN ('Liverpool', 'Tottenham Hotspur')
GROUP BY ROLLUP (players.positionName, teams.displayName)
HAVING 전체골 <> 0
ORDER BY players.positionName, teams.displayName

-- 5.6 윈도우 함수로 계산하는 EPL 득점, 순위, 누적 기록

-- P205
FROM standings
   JOIN teams USING (teamId)
SELECT displayName, sum(gf) over () AS total_goals,
   sum(gf) OVER (PARTITION BY teamId) AS team_goals,
   (team_goals / total_goals*100).round(2) AS PCT_goals
WHERE seasonType = 12654
ORDER BY #4 DESC;

-- P 205
WITH Hotspurs_games AS (
   FROM fixtures
   SELECT 367 AS teamId, date, homeTeamScore AS score
   WHERE homeTeamId = 367 and seasonType = 12654 AND statusId <> 1
   UNION
   FROM fixtures
   SELECT 367 AS teamId, date, awayTeamScore AS score
   WHERE awayTeamId = 367 and seasonType = 12654 AND statusId <> 1
   )
FROM Hotspurs_games
   JOIN teams USING (teamId)
SELECT teamId, date, score, displayName,
   sum(score) OVER (ORDER BY date) AS cum_sum_score
ORDER BY date;

-- P 207
FROM playerStats_2024_EPL
   JOIN players USING(athleteId)
   JOIN teams USING (teamId)
SELECT players.displayName,
   (totalGoals_value/shotsOnTarget_value*100).round(0) AS Goals_per_SOT,
   row_number() OVER (PARTITION BY teamId ORDER BY Goals_per_SOT DESC) AS row_num,
   rank() OVER (PARTITION BY teamId ORDER BY Goals_per_SOT DESC) AS rank,
   dense_rank() OVER (PARTITION BY teamId ORDER BY Goals_per_SOT DESC) as rank_dense,
WHERE seasonType = 12654 and totalGoals_value <> 0 and teams.displayName ilike 'liverpool'
ORDER BY #2 DESC, #3 DESC;

-- P209
FROM standings
SELECT teamRank, teamId, wins,
   (first_value(wins) OVER (ORDER BY teamRank)) as First,
   (lag(wins) OVER (ORDER BY teamRank)) AS before,
   (lead(wins) OVER (ORDER BY teamRank)) AS after,
   (last_value(wins) OVER (ORDER BY teamRank)) AS last,
   (nth_value(wins,2) OVER (ORDER BY teamRank)) AS second
WHERE seasonType = 12654;

-- P212
FROM standings
SELECT teamRank, teamId, wins,
   first_value(wins) OVER entire AS First_entire,
   last_value(wins) OVER entire AS last_entire,
   first_value(wins) OVER three AS First_three,
   last_value(wins) OVER three AS last_three,
WHERE seasonType = 12654 AND teamRank <= 10
WINDOW
   entire AS (
      PARTITION BY seasonType ORDER BY teamRank
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),
   three AS (
      PARTITION BY seasonType ORDER BY teamRank
      ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

--P214
FROM playerStats_2024_EPL
   JOIN players USING(athleteId)
   JOIN teams USING (teamId)
SELECT teams.displayName, players.displayName AS displayName_1,
   totalGoals_value, shotsOnTarget_value,
   (totalGoals_value/shotsOnTarget_value*100).round(2) AS Goals_per_SOT,
   sum(totalGoals_value) OVER group_frame AS frame_sum_goal,
   sum(shotsOnTarget_value) OVER group_frame AS frame_sum_SOT,
WHERE seasonType = 12654 and totalGoals_value <> 0 AND
   teams.displayName ilike ‘Manchester City’
WINDOW group_frame AS (
   ORDER BY Goals_per_SOT DESC GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING);

-- P215
FROM playerStats_2024_EPL
   JOIN players USING(athleteId)
   JOIN teams USING (teamId)
SELECT teams.displayName, players.displayName AS displayName_1,
   totalGoals_value,
   sum(totalGoals_value) OVER group_frame as frame_sum_goal,
WHERE seasonType = 12654 AND totalGoals_value <> 0 AND
   teams.displayName ILIKE 'Manchester City'
WINDOW group_frame AS (
   ORDER BY totalGoals_value DESC RANGE BETWEEN 2 PRECEDING AND 2 FOLLOWING);

-- 5.7 피벗으로 변환하는 EPL 팀 로스트 표

-- P219
WITH pivot_CTE AS (
   FROM teamroster
   WHERE seasonType = 12654)
FROM pivot_CTE
PIVOT (
   count()
   FOR "position" IN ('Goalkeeper', 'Defender', 'Midfielder', 'Forward')
   GROUP BY teamName);

-- P220
WITH pivot_CTE as (
   FROM teamroster
   WHERE seasonType = 12654)
FROM (FROM pivot_CTE
PIVOT (
   count()
   FOR "position" IN ('Goalkeeper', 'Defender', 'Midfielder', 'Forward')
   GROUP BY teamName))
UNPIVOT (
   player_num FOR "position" IN ('Goalkeeper', 'Defender', 'Midfielder', 'Forward'));

-- 5.8 고급 SQL로 분류하고 실행하는 EPL 데이터

-- P223
WITH gf_grade AS (
   FROM standings
   SELECT teamId, gf, ntile(3) OVER (ORDER BY gf DESC) AS gf_grade
   WHERE seasonType = 12654
)
FROM gf_grade
   JOIN teams USING (teamId)
SELECT
   list(displayName) FILTER (gf_grade = 1) AS 'HIGH_GRADE',
   list(displayName) FILTER (gf_grade = 2) AS 'MIDDLE_GRADE',
   list(displayName) FILTER (gf_grade = 3) AS 'LOW_GRADE';

-- P 224
PREPARE player_info AS
   FROM players
      JOIN playerStats_2024_EPL USING (athleteId)
   SELECT displayName, displayHeight, displayWeight, dateOfBirth, citizenship, positionName,
      appearances_value, subIns_value, yellowCards_value, redCards_value, shotsFaced_value, 
      totalShots_value
   WHERE displayName ILIKE ?;

--P225
EXECUTE player_info('Son Heung-Min');

-- P225
SET VARIABLE playerName = 'Son Heung-Min';

-- P 226
FROM players
   JOIN playerStats_2024_EPL USING (athleteId)
SELECT displayName, displayHeight, displayWeight, dateOfBirth, citizenship,
   positionName, appearances_value, subIns_value, yellowCards_value, redCards_value,
   shotsFaced_value, totalShots_value
WHERE displayName LIKE getvariable('playerName');
















