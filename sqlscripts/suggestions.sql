CREATE TABLE suggest_movies (
       movie_id int,
       norm_title text,
       link_score int,
       occupation_score int
);

-- Adult film naming really disturbs a proper suggestion system, so we exclude those.
-- We also strip leading "the".

INSERT INTO suggest_movies
SELECT m.id AS movie_id,
       regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(LOWER(ma.title), E' \\(....\\)$', ''),E'[^ \ta-z0-9]','','g'),E'[\t ]+',' ','g'), E'^ +',''), E' +$',''), E'^the ','') AS norm_title,
       sms.link_score,
       sms.occupation_score
 FROM movies m
 INNER JOIN movie_akas ma
  ON ma.movie_id = m.id
 INNER JOIN sphinx_movies_score sms
  ON sms.movie_id = m.id
 WHERE sms.link_score > 10
 AND sms.occupation_score > 150
 AND m.id NOT IN (SELECT movie_id FROM movie_genres WHERE genre_id IN (SELECT id FROM genres WHERE genre = 'Adult'));

INSERT INTO suggest_movies
SELECT m.id AS movie_id,
       regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(LOWER(m.title),E'[^ \ta-z0-9]','','g'),E'[\t ]+',' ','g'), E'^ +',''), E' +$',''), E'^the ','') AS norm_title,
       sms.link_score,
       sms.occupation_score
 FROM movies m
 INNER JOIN sphinx_movies_score sms
  ON sms.movie_id = m.id
 WHERE sms.link_score > 10
 AND sms.occupation_score > 150
 AND m.id NOT IN (SELECT movie_id FROM movie_genres WHERE genre_id IN (SELECT id FROM genres WHERE genre = 'Adult'));




CREATE TABLE suggest_people (
       person_id int, 
       norm_name text,
       link_score int, 
       occupation_score int, 
       score_count int
);

INSERT INTO suggest_people
SELECT p.id AS person_id,
       regexp_replace(regexp_replace(regexp_replace(regexp_replace(LOWER(COALESCE(p.first_name,'')||' '||COALESCE(p.last_name,'')),E'[^ \ta-z0-9]','','g'),E'[\t ]+',' ','g'), E'^ +',''), E' +$','') AS norm_name,
       SUM(sms.link_score) AS link_score,
       SUM(sms.occupation_score) AS occupation_score,
       COUNT(sms.occupation_score)
  from people p 
  inner join occupations o 
    on o.person_id = p.id 
  inner join sphinx_movies_score sms 
    on sms.movie_id = o.movie_id 
  where sms.link_score > 30 
  and sms.occupation_score > 250 
  group by p.id,norm_name;

INSERT INTO suggest_people 
SELECT p.id AS person_id,
       regexp_replace(regexp_replace(regexp_replace(regexp_replace((regexp_split_to_array(LOWER(an.name), ', '))[array_upper(regexp_split_to_array(LOWER(an.name), ', '),1)]||' '||array_to_string((regexp_split_to_array(LOWER(an.name), ', '))[1:array_upper(regexp_split_to_array(LOWER(an.name), ', '),1)-1], ', '),E'[^ \ta-z0-9]','','g'),E'[\t ]+',' ','g'), E'^ +',''), E' +$','') AS norm_name,
       SUM(sms.link_score) AS link_score,
       SUM(sms.occupation_score) AS occupation_score,
       COUNT(sms.occupation_score)
  from people p 
  inner join aka_names an
    on an.person_id = p.id
  inner join occupations o 
    on o.person_id = p.id 
  inner join sphinx_movies_score sms 
    on sms.movie_id = o.movie_id 
  where sms.link_score > 30 
  and sms.occupation_score > 250 
  group by p.id,norm_name;

CREATE INDEX suggest_people_idx_occupation_score ON suggest_people(occupation_score);
CREATE INDEX suggest_people_idx_link_score ON suggest_people(link_score);
CREATE INDEX suggest_people_idx_score_count ON suggest_people(score_count);
