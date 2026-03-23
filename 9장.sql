-- 9. DuckDB로 인기 영상 분석하기

-- 9.1 유튜브 데이터셋 다운로드 및 불러오기

-- P343
CREATE OR REPLACE TABLE youtube AS (
   FROM read_csv('trending_yt_videos_113_countries.csv'));

-- P343
FROM youtube
LIMIT 5;

-- 9.2 유튜브 데이터 검토
-- P344
FROM youtube
SELECT count();

-- P344
FROM duckdb_columns()
SELECT * EXCLUDE (database_name, database_oid, schema_name, schema_oid, table_oid)
WHERE table_name = 'youtube';

-- P345
DESC youtube;

-- P346
FROM youtube
SELECT *, Duplicated:count()
GROUP BY ALL
HAVING Duplicated > 1;

-- P346
SELECT video_id, snapshot_date, country, dup_count:count()
FROM youtube
GROUP BY ALL
HAVING dup_count > 1;

-- P347
FROM youtube
SELECT *
WHERE title IS NULL;

-- P347
SELECT COUNT(*) AS total_rows,
   (COUNTIF(title IS NULL)/total_rows*100).round(1)||'%' AS title_nulls,
   (COUNTIF(channel_id IS NULL)/total_rows*100).round(1)||'%' AS channel_nulls,
   (COUNTIF(description IS NULL)/total_rows*100).round(1)||'%' AS description_nulls
FROM youtube;

-- P348
FROM (
   FROM youtube
   SELECT COUNT(*) AS total_rows,
      (COUNTIF(COLUMNS(*) IS NULL)/total_rows*100).round(1))
UNPIVOT (null_pct FOR column_name IN (COLUMNS(*)))
WHERE null_pct <> 0

-- P349
FROM(
   FROM youtube
   SELECT COUNT(DISTINCT COLUMNS(*)))
UNPIVOT (distinct_count FOR column_name IN (COLUMNS(*)))

-- P349
ALTER TABLE youtube DROP COLUMN kind;

-- 9.3 유튜브 데이터 파생 변수 생성

-- P350
ALTER TABLE youtube ADD COLUMN tag_list STRING[];

-- P350
UPDATE youtube SET tag_list = string_split(video_tags, ',');

-- P351
FROM youtube
SELECT video_tags, tag_list
WHERE video_tags IS NOT NULL
LIMIT 5;

-- P351
FROM (FROM youtube
   SELECT tag_list, len(tag_list) AS tags
   WHERE tag_list IS NOT NULL)
SELECT tags, COUNT()
GROUP BY ALL
ORDER BY tags DESC;

-- P352
ALTER TABLE youtube ADD COLUMN comment_rate DECIMAL(10,3);

-- P352
UPDATE youtube
SET comment_rate = CASE WHEN view_count = 0 THEN 0 ELSE ((comment_count/view_count)*100) END;

-- P352
FROM youtube
SELECT title, snapshot_date, comment_rate, comment_count, view_count
ORDER BY comment_rate DESC
LIMIT 5;

-- P353
ALTER TABLE youtube ADD COLUMN like_rate FLOAT;
UPDATE youtube
SET like_rate = CASE WHEN view_count = 0 THEN 0 ELSE like_count/view_count*100 END;

-- P353
FROM youtube
SELECT title, snapshot_date, like_rate, like_count, view_count
ORDER BY like_rate DESC
LIMIT 5;

-- P354
CREATE TYPE DOW AS ENUM ('일', '월', '화', '수', '목', '금', '토');
ALTER TABLE youtube ADD COLUMN DOW_publish_date DOW;

-- P354
UPDATE youtube SET
DOW_publish_date = CASE WHEN date_part('dayofweek', "publish_date") == 0 THEN '일'
   WHEN date_part('dayofweek', "publish_date") == 1 THEN '월'
   WHEN date_part('dayofweek', "publish_date") == 2 THEN '화'
   WHEN date_part('dayofweek', "publish_date") == 3 THEN '수'
   WHEN date_part('dayofweek', "publish_date") == 4 THEN '목'
   WHEN date_part('dayofweek', "publish_date") == 5 THEN '금'
   WHEN date_part('dayofweek', "publish_date") == 6 THEN '토'
   END;

-- P355
FROM youtube
SELECT title, publish_date, DOW_publish_date
LIMIT 5;

-- P355
ALTER TABLE youtube ADD COLUMN DOW_snapshot_date DOW;
UPDATE youtube SET
   DOW_snapshot_date = CASE WHEN date_part('dayofweek', "snapshot_date") == 0 THEN '일'
      WHEN date_part('dayofweek', "snapshot_date") == 1 THEN '월'
      WHEN date_part('dayofweek', "snapshot_date") == 2 THEN '화'
      WHEN date_part('dayofweek', "snapshot_date") == 3 THEN '수'
      WHEN date_part('dayofweek', "snapshot_date") == 4 THEN '목'
      WHEN date_part('dayofweek', "snapshot_date") == 5 THEN '금'
      WHEN date_part('dayofweek', "snapshot_date") == 6 THEN '토'
     END;

-- P356
FROM youtube
SELECT title, snapshot_date, DOW_snapshot_date
LIMIT 5;

-- P356
FROM youtube
SELECT title, snapshot_date, view_count, 
   view_daily_change: view_count - 
      lag(view_count) OVER (PARTITION BY (video_id, channel_id, country) ORDER BY snapshot_date),
   like_count, 
   like_daily_change: like_count - 
      lag(like_count) OVER (PARTITION BY (video_id, channel_id, country) ORDER BY snapshot_date),
   comment_count, 
   comment_daily_change: comment_count - 
      lag(comment_count) OVER (PARTITION BY (video_id, channel_id, country) ORDER BY snapshot_date)
WHERE video_id = 'yebNIHKAC4A' and country = 'KR'
ORDER BY ALL
LIMIT 5

-- 9.4 유튜브 데이터 탐색적 분석

-- P360
DROP TABLE youtube;
CREATE OR REPLACE VIEW youtube AS (FROM read_parquet('./youtube.parquet'));

-- P360
SUMMARIZE youtube;

-- 9.6 <케이팝 데몬 헌터스> 유튜브 트렌드 분석

-- P396
CREATE OR REPLACE TABLE k_de_hun AS (
   FROM youtube
   WHERE (title ILIKE '%saja boys%' OR -- 대소문자 관계없이 saja boys이 포함된 제목
      title ILIKE '%kpop demon%' OR -- 대소문자 관계없이 kpop demon이 포함된 제목
      title LIKE '%케이팝%데몬%' OR -- 케이팝과 데몬이 포함된 제목
      title LIKE '%케데헌%' OR -- 케데헌이 포함된 제목
      title ILIKE '%golden%cover%' OR -- 대소문자 관계없이 golden과 cover가 포함된 제목
      title ILIKE '%cover%golden%' OR -- 대소문자 관계없이 cover와 golden
      title ILIKE '%huntrix%' OR -- 대소문자 관계없이 huntrix가 포함된 제목
      title ILIKE '%HUNTR/X%' OR -- 대소문자 관계없이 HUNT/X가 포함된 제목
      title LIKE '%헌트릭스%' OR -- 헌트릭스가 포함된 제목
      title LIKE '%사자%보이%'));

-- P397
FROM k_de_hun
SELECT "최초 등록일" : min(publish_date)::DATE, "최후 등록일" : max(publish_date)::DATE

-- P397
FROM k_de_hun
SELECT DISTINCT publish_date
ORDER BY ALL
LIMIT 5;

-- P398
FROM k_de_hun
SELECT DISTINCT title
WHERE publish_date::DATE = '2025-05-28';

-- P398
DELETE FROM k_de_hun
WHERE publish_date::DATE <= '2025-05-28';

-- P399
FROM k_de_hun
SELECT country, count(distinct video_id)
GROUP BY ALL
ORDER BY #2 DESC
LIMIT 10

-- P400
FROM k_de_hun
SELECT 국가:country, "영상 수": COUNT(DISTINCT video_id),
   "채널 수": COUNT(DISTINCT channel_id),
   "1위 영상 수": count(DISTINCT video_id) filter (daily_rank = 1),
   "전체 재생 수":sum(view_count),
   "전체 좋아요 수":sum(like_count), "비율":round("전체 좋아요 수"/"전체 재생 수"*100, 2)
GROUP BY ALL
ORDER BY "영상 수" DESC
LIMIT 10;

-- P400
FROM k_de_hun
SELECT country, title
WHERE daily_rank = 1
GROUP BY ALL
ORDER BY #1 DESC;

-- P401
FROM k_de_hun
SELECT country, title, COUNT(*) AS "차트 일수"
GROUP BY CUBE (title, country)
HAVING country IN ('US', 'KR')
QUALIFY
   ROW_NUMBER() OVER (PARTITION BY country ORDER BY "차트 일수" DESC) <= 5;

-- P402
FROM k_de_hun
SELECT country, "차트 일수":count(), "최고 순위":min(daily_rank), 시작:min(snapshot_date),
   종료:max(snapshot_date)
WHERE video_id = 'yebNIHKAC4A'
GROUP BY ALL
ORDER BY #2 DESC
LIMIT 10

-- P403
FROM k_de_hun
SELECT 국가:country, "차트 최종일":snapshot_date,
   "조회 수":view_count, "좋아요 수":like_count,
   "조회 대비 좋아요 비율":round(like_count/view_count*100, 2),
WHERE video_id = 'yebNIHKAC4A'
QUALIFY ROW_NUMBER() OVER (PARTITION BY country ORDER BY snapshot_date DESC) = 1
ORDER BY #5 DESC
LIMIT 10;

-- P405
FROM k_de_hun
SELECT title, "차트 일수":count(),
   게시일:min(publish_date), 종료:max(snapshot_date),
   "최종 조회 수":MAX(view_count), "최종 좋아요 수":MAX(like_count),
   "최종 댓글 수":MAX(comment_count),
WHERE country = 'KR'
GROUP BY title
HAVING "차트 일수" >= 4
ORDER BY "최종 조회 수" DESC;

-- P406
FROM k_de_hun
SELECT title, duration:max(snapshot_date)::DATE - min(publish_date)::DATE + 1,
   평균조회:round(max(view_count)/(duration), 0),
   평균좋아요:round(max(like_count)/(duration), 0),
   평균댓글:round(max(comment_count)/(duration), 0)
WHERE country = 'KR'
GROUP BY video_id, title
ORDER BY #3 desc
LIMIT 10;
















