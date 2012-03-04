-- Query for movies-simple index

CREATE VIEW sphinx_index_movies_simple
(id, title, episode_title, category, is_episode, link_score, occupation_score, rating, votes)
AS
SELECT m.id,m.title_norm,m.episode_name_norm AS episode_title,
CASE WHEN m.title_category IS NULL THEN 1
     WHEN m.title_category = 'TVS' THEN 0
     WHEN m.title_category = 'TV'  THEN 2
     WHEN m.title_category = 'V'   THEN 3
     WHEN m.title_category = 'VG'  THEN 4
     ELSE 99
END AS category,
CASE WHEN m.is_episode = false THEN 0
     ELSE 1
END AS is_episode,
sc.link_score,
sc.occupation_score,
rt.rating,
rt.votes
FROM (
  SELECT id,title_norm,episode_name_norm,title_category,is_episode FROM movies
  UNION
  SELECT ma.movie_id,ma.title_norm,m1.episode_name_norm,m1.title_category,m1.is_episode FROM movies m1
  INNER JOIN movie_akas ma
  ON ma.movie_id = m1.id
) m
LEFT OUTER JOIN sphinx_movies_score sc
ON sc.movie_id = m.id
LEFT OUTER JOIN ratings rt
ON rt.movie_id = m.id
;

-- Query for movies index

CREATE VIEW sphinx_index_movies
(id, title, episode_title, category, is_episode, link_score, occupation_score, rating, votes,
 genre, genre_ids, keyword, keyword_ids,
 language, language_ids, "cast",
 character, year, decade, year_attr, decade_attr, cast_ids,
 producer, producer_ids, director, director_ids, writer, writer_ids)
AS
SELECT sims.id AS id,title,episode_title,category,is_episode, link_score, occupation_score,
       rating, votes, 
       genre, genre_ids, keyword, keyword_ids, 
       language, language_ids, mcast AS "cast",
       character,year, decade, year_attr, decade_attr, mcast_ids AS cast_ids,
       mproducer AS producer, mproducer_ids AS producer_ids,
       mdirector AS director, mdirector_ids AS director_ids,
       mwriter AS writer, mwriter_ids AS writer_ids
FROM sphinx_index_movies_simple sims
FULL OUTER JOIN sphinx_genre sg ON sg.movie_id = sims.id
FULL OUTER JOIN sphinx_keyword sk ON sk.movie_id = sims.id
FULL OUTER JOIN sphinx_language sl ON sl.movie_id = sims.id
FULL OUTER JOIN sphinx_mcast sp ON sp.movie_id = sims.id
FULL OUTER JOIN sphinx_mproducer spr ON spr.movie_id = sims.id
FULL OUTER JOIN sphinx_mdirector sdr ON sdr.movie_id = sims.id
FULL OUTER JOIN sphinx_mwriter swr ON swr.movie_id = sims.id
FULL OUTER JOIN sphinx_mcharacter sc ON sc.movie_id = sims.id
FULL OUTER JOIN sphinx_year sy ON sy.movie_id = sims.id
;

CREATE VIEW sphinx_index_movies_plot
(id, title, episode_title, category, is_episode, link_score, occupation_score, rating, votes,
 genre, genre_ids, keyword, keyword_ids,
 language, language_ids, "cast",
 character, year, decade, year_attr, decade_attr, cast_ids, plot,
 producer, producer_ids, director, director_ids, writer, writer_ids)
AS
SELECT sims.id AS id,title,episode_title,category,is_episode, link_score, occupation_score,
       rating, votes, 
       genre, genre_ids, keyword, keyword_ids, 
       language, language_ids, mcast AS "cast",
       character,year, decade, year_attr, decade_attr, mcast_ids AS cast_ids,
       plot,
       mproducer AS producer, mproducer_ids AS producer_ids,
       mdirector AS director, mdirector_ids AS director_ids,
       mwriter AS writer, mwriter_ids AS writer_ids
FROM sphinx_index_movies_simple sims
FULL OUTER JOIN sphinx_genre sg ON sg.movie_id = sims.id
FULL OUTER JOIN sphinx_keyword sk ON sk.movie_id = sims.id
FULL OUTER JOIN sphinx_language sl ON sl.movie_id = sims.id
FULL OUTER JOIN sphinx_mcast sp ON sp.movie_id = sims.id
FULL OUTER JOIN sphinx_mproducer spr ON spr.movie_id = sims.id
FULL OUTER JOIN sphinx_mdirector sdr ON sdr.movie_id = sims.id
FULL OUTER JOIN sphinx_mwriter swr ON swr.movie_id = sims.id
FULL OUTER JOIN sphinx_mcharacter sc ON sc.movie_id = sims.id
FULL OUTER JOIN sphinx_year sy ON sy.movie_id = sims.id
FULL OUTER JOIN sphinx_plot spl ON spl.id = sims.id
;

CREATE VIEW sphinx_index_movies_quote
(id, title, episode_title, category, is_episode, link_score, occupation_score, rating, votes,
 genre, genre_ids, keyword, keyword_ids,
 language, language_ids, "cast",
 character, year, decade, year_attr, decade_attr, cast_ids, quote, 
 producer, producer_ids, director, director_ids, writer, writer_ids,
 trivia, goofs)
AS
SELECT sims.id AS id,title,episode_title,category,is_episode, link_score, occupation_score,
       rating, votes, 
       genre, genre_ids, keyword, keyword_ids, 
       language, language_ids, mcast AS "cast",
       character,year, decade, year_attr, decade_attr, mcast_ids AS cast_ids,
       quote,
       mproducer AS producer, mproducer_ids AS producer_ids,
       mdirector AS director, mdirector_ids AS director_ids,
       mwriter AS writer, mwriter_ids AS writer_ids,
       trivia, goofs
FROM sphinx_index_movies_simple sims
FULL OUTER JOIN sphinx_genre sg ON sg.movie_id = sims.id
FULL OUTER JOIN sphinx_keyword sk ON sk.movie_id = sims.id
FULL OUTER JOIN sphinx_language sl ON sl.movie_id = sims.id
FULL OUTER JOIN sphinx_mcast sp ON sp.movie_id = sims.id
FULL OUTER JOIN sphinx_mproducer spr ON spr.movie_id = sims.id
FULL OUTER JOIN sphinx_mdirector sdr ON sdr.movie_id = sims.id
FULL OUTER JOIN sphinx_mwriter swr ON swr.movie_id = sims.id
FULL OUTER JOIN sphinx_mcharacter sc ON sc.movie_id = sims.id
FULL OUTER JOIN sphinx_year sy ON sy.movie_id = sims.id
FULL OUTER JOIN sphinx_quote sq ON sq.id = sims.id
FULL OUTER JOIN sphinx_trivia str ON str.id = sims.id
FULL OUTER JOIN sphinx_goofs sgf ON sgf.id = sims.id
;

-- Query for people-simple index

CREATE VIEW sphinx_index_people_simple
(id, name)
AS
SELECT p.id,coalesce(p.name_norm,'') AS "name" FROM people p
UNION
SELECT an.person_id,an.name_norm FROM aka_names an
;

CREATE VIEW sphinx_index_people
(id, name, episode, movie, character, episode_ids, movie_ids)
AS
SELECT id,name,episode,movie,pcharacter AS character, episode_ids, movie_ids
FROM sphinx_index_people_simple
FULL OUTER JOIN sphinx_episode se ON se.person_id = id
FULL OUTER JOIN sphinx_movie sm ON sm.person_id = id
FULL OUTER JOIN sphinx_pcharacter sc ON sc.person_id = id
;

CREATE VIEW sphinx_index_people_biography
(id, name, episode, movie, character, episode_ids, movie_ids, biography)
AS
SELECT id,name,episode,movie,pcharacter AS character, episode_ids, movie_ids, biography
FROM sphinx_index_people_simple
FULL OUTER JOIN sphinx_episode se ON se.person_id = id
FULL OUTER JOIN sphinx_movie sm ON sm.person_id = id
FULL OUTER JOIN sphinx_pcharacter sc ON sc.person_id = id
FULL OUTER JOIN sphinx_biography sb ON sb.person_id = id
;
