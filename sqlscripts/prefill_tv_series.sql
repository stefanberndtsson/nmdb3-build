-- 684703 == Allo Allo

CREATE LANGUAGE plpgsql;
VACUUM ANALYZE movies;
VACUUM ANALYZE occupations;

CREATE OR REPLACE FUNCTION series_cast_collector(parent_id INT)
RETURNS boolean
AS
$$
DECLARE
 precount INT;
BEGIN
-- SELECT count(*) INTO precount FROM occupations
--  WHERE movie_id = parent_id
--  AND role_id IN (1,2)
--  AND sort_value IS NOT NULL
-- ;
SELECT 0 INTO precount;
IF precount = 0 THEN
INSERT INTO occupations 
SELECT (SELECT max(id) FROM occupations)+scc.row_number,scc.person_id,scc.movie_id,scc.role_id,scc.character,
       scc.row_number::text,NULL AS extras,2 AS occupation_score,
       scc.count,true AS collected
 FROM (
 SELECT m.parent_id AS movie_id,o.role_id,o.person_id,om.character,
        count(*),
        row_number() OVER (ORDER BY (sum(coalesce(o.sort_value, '99999')::integer)::float)/count(*) ASC)
 FROM occupations o
 INNER JOIN movies m
  ON m.id = o.movie_id
 INNER JOIN (
   SELECT oi.person_id,min(oi.character) AS "character" FROM occupations oi
   WHERE oi.movie_id IN (
     SELECT id FROM movies mi
     WHERE mi.parent_id = $1
   )
   GROUP BY oi.person_id
 ) om
  ON om.person_id = o.person_id
 WHERE
  m.parent_id = $1
 AND
  o.role_id IN (1,2)
 GROUP BY m.parent_id,o.role_id,o.person_id,om.character
 HAVING (count(*) > 20) OR (count(*)::float/(SELECT count(*)::float FROM movies m WHERE m.parent_id = $1) > 0.5)
) scc;
RETURN true;
END IF;
RETURN false;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION series_cast_presenter(INT)
RETURNS TABLE (movie_id INT, role_id INT, person_id INT,  "character" TEXT,
	       episode_count BIGINT, sort_value BIGINT)
AS
$$
 SELECT m.parent_id AS movie_id,o.role_id,o.person_id,om.character,
        count(*), row_number() OVER (ORDER BY count(*) DESC) AS sort_value
 FROM occupations o
 INNER JOIN movies m
  ON m.id = o.movie_id
 INNER JOIN (
   SELECT oi.person_id,min(oi.character) AS "character" FROM occupations oi
   WHERE oi.movie_id IN (
     SELECT id FROM movies mi
     WHERE mi.parent_id = $1
   )
   GROUP BY oi.person_id
 ) om
  ON om.person_id = o.person_id
 WHERE
  m.parent_id = $1
 AND
  o.role_id IN (1,2)
 GROUP BY m.parent_id,o.role_id,o.person_id,om.character
 HAVING (count(*) > 20) OR (count(*)::float/(SELECT count(*)::float FROM movies m WHERE m.parent_id = $1) > 0.5)
$$
LANGUAGE SQL;

SELECT series_cast_collector(m.id) FROM movies m
  WHERE is_episode = false
  AND title_category = 'TVS';
