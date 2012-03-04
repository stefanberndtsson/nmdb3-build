\t on
\a
\pset fieldsep '	'
\o full_keyword.dat
SELECT movie_id,ARRAY(SELECT keyword 
                       FROM keywords k 
                       INNER JOIN movie_keywords mk
                        ON k.id = mk.keyword_id
                       WHERE mk.movie_id = ck.movie_id)
 FROM compare_keywords ck;

\o active_keywords.dat
SELECT k.keyword 
 FROM movie_keywords mk
 INNER JOIN keywords k
  ON k.id = mk.keyword_id
 GROUP BY k.keyword 
 HAVING count(*) < 1000 
  AND count(*) > 100;

\o full_genre.dat
SELECT movie_id,ARRAY(SELECT genre 
                       FROM genres g
                       INNER JOIN movie_genres mg
                        ON g.id = mg.genre_id
                       WHERE mg.movie_id = ck.movie_id)
 FROM compare_keywords ck;

\o full_language.dat
SELECT movie_id,ARRAY(SELECT language 
                       FROM languages l
                       INNER JOIN movie_languages ml
                        ON l.id = ml.language_id
                       WHERE ml.movie_id = ck.movie_id)
 FROM compare_keywords ck;

\o full_plot.dat
SELECT movie_id,plot_norm FROM plots
  WHERE movie_id IN (SELECT movie_id FROM compare_keywords);
