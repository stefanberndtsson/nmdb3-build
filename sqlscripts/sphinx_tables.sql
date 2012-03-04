ALTER TABLE movie_connection_types ADD COLUMN score_movie INT;
ALTER TABLE movie_connection_types ADD COLUMN score_link INT;

UPDATE movie_connection_types SET score_movie=1,score_link=2 WHERE id IN (1,2,4,9,12);
UPDATE movie_connection_types SET score_movie=2,score_link=1 WHERE id IN (3,5,8,13);
UPDATE movie_connection_types SET score_movie=2,score_link=3 WHERE id IN (7);
UPDATE movie_connection_types SET score_movie=3,score_link=2 WHERE id IN (6);
UPDATE movie_connection_types SET score_movie=3,score_link=1 WHERE id IN (10,14);
UPDATE movie_connection_types SET score_movie=1,score_link=3 WHERE id IN (11,15);
UPDATE movie_connection_types SET score_movie=1,score_link=1 WHERE id IN (16);

-- Need to drop views first.

CREATE TABLE sphinx_genre (movie_id INT NOT NULL, genre TEXT, genre_ids TEXT);

INSERT INTO sphinx_genre (movie_id, genre, genre_ids)
SELECT mg.movie_id,
       array_to_string(array(
       SELECT genre FROM genres g1 
         INNER JOIN movie_genres mg1 ON mg1.genre_id = g1.id 
         WHERE mg1.movie_id = mg.movie_id), ' '),
       array_to_string(array(
       SELECT mg2.genre_id FROM movie_genres mg2
         WHERE mg2.movie_id = mg.movie_id), ', ')
  FROM movie_genres mg
  INNER JOIN genres g ON mg.genre_id = g.id
  WHERE mg.movie_id IS NOT NULL
  GROUP BY mg.movie_id
;

CREATE TABLE sphinx_keyword (movie_id INT NOT NULL, keyword TEXT, keyword_ids TEXT);

INSERT INTO sphinx_keyword (movie_id, keyword, keyword_ids)
SELECT mk.movie_id,
       array_to_string(array(
       SELECT keyword FROM keywords k1 
         INNER JOIN movie_keywords mk1 ON mk1.keyword_id = k1.id 
         WHERE mk1.movie_id = mk.movie_id), ' '),
       array_to_string(array(
       SELECT mk2.keyword_id FROM movie_keywords mk2
         WHERE mk2.movie_id = mk.movie_id), ', ')
  FROM movie_keywords mk
  INNER JOIN keywords k ON mk.keyword_id = k.id
  WHERE mk.movie_id IS NOT NULL
  GROUP BY mk.movie_id
;

CREATE TABLE sphinx_language (movie_id INT NOT NULL, language TEXT, language_ids TEXT);

INSERT INTO sphinx_language (movie_id, language, language_ids)
SELECT ml.movie_id,
       array_to_string(array(
       SELECT language FROM languages l1 
         INNER JOIN movie_languages ml1 ON ml1.language_id = l1.id 
         WHERE ml1.movie_id = ml.movie_id), ' '),
       array_to_string(array(
       SELECT ml2.language_id FROM movie_languages ml2
         WHERE ml2.movie_id = ml.movie_id), ', ')
  FROM movie_languages ml
  INNER JOIN languages l ON ml.language_id = l.id
  WHERE ml.movie_id IS NOT NULL
  GROUP BY ml.movie_id
;

CREATE TABLE sphinx_year (movie_id INT, year TEXT, decade TEXT, year_attr TEXT, decade_attr TEXT);

INSERT INTO sphinx_year (movie_id, year, decade, year_attr, decade_attr)
SELECT y.movie_id,
       array_to_string(array(
       SELECT year FROM movie_years y1 
         WHERE y1.movie_id = y.movie_id AND y1.year IS NOT NULL AND y1.year != 'Unknown'), ' '),
       array_to_string(array(
       SELECT distinct 10*(year::int / 10)::int FROM movie_years y1 
         WHERE y1.movie_id = y.movie_id AND y1.year IS NOT NULL AND y1.year != 'Unknown'), ' '),
       array_to_string(array(
       SELECT year FROM movie_years y1 
         WHERE y1.movie_id = y.movie_id AND y1.year IS NOT NULL AND y1.year != 'Unknown'), ', '),
       array_to_string(array(
       SELECT distinct 10*(year::int / 10)::int FROM movie_years y1 
         WHERE y1.movie_id = y.movie_id AND y1.year IS NOT NULL AND y1.year != 'Unknown'), ', ')
  FROM movie_years y
  WHERE y.movie_id IS NOT NULL
  AND y.year IS NOT NULL
  AND y.year != 'Unknown'
  GROUP BY y.movie_id
;

CREATE TABLE sphinx_mcharacter (movie_id INT, character TEXT);

INSERT INTO sphinx_mcharacter (movie_id, character)
SELECT o.movie_id,textcat_all(distinct o.character_norm || '  ') as character
        FROM occupations o
        WHERE o.role_id IN (1,2)
        AND o.character IS NOT NULL
        GROUP BY o.movie_id
;

CREATE TABLE sphinx_mcast (movie_id INT, mcast TEXT, mcast_ids TEXT);

INSERT INTO sphinx_mcast (movie_id, mcast, mcast_ids)
SELECT o.movie_id,
       textcat_all(distinct (COALESCE(p.name_norm,'')) || '  ') 
         as mcast,
       array_to_string(array(SELECT DISTINCT oi.person_id FROM occupations oi 
                    WHERE oi.movie_id = o.movie_id AND oi.role_id IN (1,2)), ', ') as mcast_ids
        FROM occupations o
        INNER JOIN people p
        ON o.person_id = p.id
        WHERE o.role_id IN (1,2)
        GROUP BY o.movie_id
;

CREATE TABLE sphinx_mdirector (movie_id INT, mdirector TEXT, mdirector_ids TEXT);

INSERT INTO sphinx_mdirector (movie_id, mdirector, mdirector_ids)
SELECT o.movie_id,
       textcat_all(distinct (COALESCE(p.name_norm,'')) || '  ') 
         as mdirector,
       array_to_string(array(SELECT DISTINCT oi.person_id FROM occupations oi 
                    WHERE oi.movie_id = o.movie_id AND oi.role_id IN (6)), ', ') as mdirector_ids
        FROM occupations o
        INNER JOIN people p
        ON o.person_id = p.id
        WHERE o.role_id IN (6)
        GROUP BY o.movie_id
;

CREATE TABLE sphinx_mproducer (movie_id INT, mproducer TEXT, mproducer_ids TEXT);

INSERT INTO sphinx_mproducer (movie_id, mproducer, mproducer_ids)
SELECT o.movie_id,
       textcat_all(distinct (COALESCE(p.name_norm,'')) || '  ') 
         as mproducer,
       array_to_string(array(SELECT DISTINCT oi.person_id FROM occupations oi 
                    WHERE oi.movie_id = o.movie_id AND oi.role_id IN (9)), ', ') as mproducer_ids
        FROM occupations o
        INNER JOIN people p
        ON o.person_id = p.id
        WHERE o.role_id IN (9)
        GROUP BY o.movie_id
;

CREATE TABLE sphinx_mwriter (movie_id INT, mwriter TEXT, mwriter_ids TEXT);

INSERT INTO sphinx_mwriter (movie_id, mwriter, mwriter_ids)
SELECT o.movie_id,
       textcat_all(distinct (COALESCE(p.name_norm,'')) || '  ') 
         as mwriter,
       array_to_string(array(SELECT DISTINCT oi.person_id FROM occupations oi 
                    WHERE oi.movie_id = o.movie_id AND oi.role_id IN (11)), ', ') as mwriter_ids
        FROM occupations o
        INNER JOIN people p
        ON o.person_id = p.id
        WHERE o.role_id IN (11)
        GROUP BY o.movie_id
;


CREATE TABLE sphinx_movies_score (movie_id INT, link_score INT, occupation_score INT);

INSERT INTO sphinx_movies_score (movie_id, link_score, occupation_score)
SELECT m.id,COALESCE(sc.link_score,0),COALESCE(sco.occupation_score,0)
FROM movies m
LEFT OUTER JOIN (SELECT m1.movie_id,m1.link_score+m2.link_score AS link_score
 FROM (SELECT movie_id,SUM(COALESCE(mct.score_movie,0)) AS link_score
  FROM movie_connections mc 
  INNER JOIN movie_connection_types mct
    ON mct.id = mc.movie_connection_type_id
  GROUP BY 1) m1
 INNER JOIN (SELECT linked_movie_id,SUM(COALESCE(mct.score_link,0)) AS link_score
  FROM movie_connections mc 
  INNER JOIN movie_connection_types mct
    ON mct.id = mc.movie_connection_type_id
  GROUP BY 1) m2
   ON m1.movie_id = m2.linked_movie_id
) sc
ON m.id = sc.movie_id
LEFT OUTER JOIN (SELECT oc.movie_id,(1000*SUM(COALESCE(oc.occupation_score,0)*COALESCE(oc.episode_count,1)))::float/SUM(o.episode_count)::INT AS occupation_score
 FROM occupations oc
 INNER JOIN occupations o
  ON oc.movie_id = o.movie_id
 GROUP BY oc.movie_id) sco
 ON m.id = sco.movie_id
WHERE m.id IS NOT NULL;
;


CREATE TABLE sphinx_pcharacter (person_id INT, pcharacter TEXT);

INSERT INTO sphinx_pcharacter (person_id, pcharacter)
SELECT o.person_id,textcat_all(distinct o.character_norm || ' ') AS pcharacter
        FROM occupations o
        WHERE o.role_id IN (1,2)
        AND o.character IS NOT NULL
        GROUP BY o.person_id
;

CREATE TABLE sphinx_movie (person_id INT, movie TEXT, movie_ids TEXT);

INSERT INTO sphinx_movie (person_id, movie, movie_ids)
SELECT o.person_id,textcat_all(distinct m.title_norm || ' ') AS movie,
       array_to_string(array(SELECT DISTINCT oi.movie_id FROM occupations oi 
                    WHERE oi.person_id = o.person_id AND oi.role_id IN (1,2)), ', ') as movie_ids
        FROM occupations o
        INNER JOIN movies m
        ON o.movie_id = m.id
        WHERE o.role_id IN (1,2)
        AND m.is_episode = false
        GROUP BY o.person_id
;

CREATE TABLE sphinx_episode (person_id INT, episode TEXT, episode_ids TEXT);

INSERT INTO sphinx_episode (person_id, episode, episode_ids)
SELECT o.person_id,textcat_all(distinct m.episode_name_norm || ' ') AS episode,
       array_to_string(array(SELECT DISTINCT oi.movie_id FROM occupations oi 
       				    INNER JOIN movies mi
				    	  ON oi.movie_id = mi.id
			            WHERE oi.person_id = o.person_id
				    AND mi.is_episode = true
				    AND oi.role_id IN (1,2)), ', ') as episode_ids
        FROM occupations o
        INNER JOIN movies m
        ON o.movie_id = m.id
        WHERE o.role_id IN (1,2)
        AND m.is_episode = true
        GROUP BY o.person_id
;

CREATE TABLE sphinx_plot (id INT, plot TEXT);

INSERT INTO sphinx_plot (id, plot)
SELECT DISTINCT pl.movie_id,
                array_to_string(array(SELECT plot_norm FROM plots 
                                       WHERE movie_id = pl.movie_id), 
                                      '    ') 
       FROM plots pl;


CREATE TABLE sphinx_trivia (id INT, trivia TEXT);

INSERT INTO sphinx_trivia (id, trivia)
SELECT DISTINCT t.movie_id,
                array_to_string(array(SELECT trivia_norm FROM trivia 
                                       WHERE movie_id = t.movie_id), 
                                      '    ') 
       FROM trivia t;


CREATE TABLE sphinx_goofs (id INT, goofs TEXT);

INSERT INTO sphinx_goofs (id, goofs)
SELECT DISTINCT gf.movie_id,
                array_to_string(array(SELECT goof_norm FROM goofs 
                                       WHERE movie_id = gf.movie_id), 
                                      '    ') 
       FROM goofs gf;


CREATE TABLE sphinx_quote (id INT, quote TEXT);

INSERT INTO sphinx_quote (id, quote)
SELECT DISTINCT q.movie_id, 
                array_to_string(array(SELECT qd.value_norm FROM quote_data qd 
                                      WHERE qd.quote_id IN 
                                        (SELECT id FROM quotes WHERE movie_id = q.movie_id)), 
                                '    ') 
       FROM quotes q;


CREATE TABLE sphinx_biography (person_id INT, biography TEXT);

INSERT INTO sphinx_biography (person_id, biography)
SELECT DISTINCT p.person_id,array_to_string(array(SELECT mp.value_norm FROM person_metadata mp 
                                                  WHERE mp.person_id = p.person_id 
 					          AND mp.key in ('RN', 'NK', 'BG', 'TR', 'QU')), 
                                            '    ')
       FROM person_metadata p;
