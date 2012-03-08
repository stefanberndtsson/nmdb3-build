\a
\f '	'
\t
\o movies_ids.dat
SELECT id,full_title FROM movies WHERE suspended IS NULL;
\o people_ids.dat
SELECT id,full_name FROM people;
\o imdb_ids.dat
SELECT id,imdb_id FROM movies WHERE imdb_id IS NOT NULL;
