\a
\f '	'
\t
\o movies_ids.dat
SELECT id,full_title FROM movies WHERE suspended IS NULL;
\o people_ids.dat
SELECT id,full_name FROM people;
