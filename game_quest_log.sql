SELECT
	"public".tbl_game_quest_log.char_level,
	SUM (
		CASE "public".tbl_game_quest_log.main_type
		WHEN 6001 THEN
			1
		ELSE
			0
		END
	) AS X6001,
	SUM (
		CASE "public".tbl_game_quest_log.main_type
		WHEN 6002 THEN
			1
		ELSE
			0
		END
	) AS X6002,
	SUM (
		CASE "public".tbl_game_quest_log.main_type
		WHEN 6003 THEN
			1
		ELSE
			0
		END
	) AS X6003
FROM
	"public".tbl_game_quest_log
WHERE
	(
		DATE (log_time) >= '2016-03-25' :: DATE
	)
AND (
	DATE (log_time) < '2016-03-28' :: DATE
)
AND "public".tbl_game_quest_log.main_type IN ('6001', '6002', '6003')
GROUP BY
	"public".tbl_game_quest_log.char_level
ORDER BY
	"public".tbl_game_quest_log.char_level ASC;
