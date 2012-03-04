-- Create table for comparing keywords

CREATE TABLE compare_keywords (movie_id INT NOT NULL, keyword_ids INT[]);
INSERT INTO compare_keywords (movie_id, keyword_ids)
SELECT movie_id,keyword_array
FROM (
SELECT mk.movie_id,
       array(
        SELECT mk1.keyword_id FROM movie_keywords mk1
        INNER JOIN (SELECT mk2.keyword_id,count(mk2.movie_id)
                    FROM movie_keywords mk2
                    GROUP BY mk2.keyword_id
                    HAVING count(mk2.movie_id) > 100
                    AND count(mk2.movie_id) < 1000) k1
        ON k1.keyword_id = mk1.keyword_id
        WHERE mk.movie_id = mk1.movie_id
) AS keyword_array
FROM movie_keywords mk
WHERE mk.movie_id IS NOT NULL
GROUP BY mk.movie_id
) sub
WHERE array_length(keyword_array,1) >= 10
AND keyword_array != '{}'::int[];

CREATE INDEX compare_keywords_idx_movie_id ON compare_keywords(movie_id);
CREATE INDEX compare_keywords_idx_keyword_ids ON compare_keywords USING GIN(keyword_ids);


-- Create table for comparing genres

CREATE TABLE compare_genres (movie_id INT NOT NULL, genre_ids INT[]);
INSERT INTO compare_genres (movie_id, genre_ids)
SELECT mg.movie_id,
       array(
        SELECT mg1.genre_id FROM movie_genres mg1
        WHERE mg.movie_id = mg1.movie_id)
FROM movie_genres mg
WHERE mg.movie_id IN (SELECT movie_id FROM compare_keywords)
GROUP BY mg.movie_id
;

CREATE INDEX compare_genres_idx_movie_id ON compare_genres(movie_id);
CREATE INDEX compare_genres_idx_genre_ids ON compare_genres USING GIN(genre_ids);


-- Create table for comparing languages

CREATE TABLE compare_languages (movie_id INT NOT NULL, language_ids INT[]);
INSERT INTO compare_languages (movie_id, language_ids)
SELECT ml.movie_id,
       array(
        SELECT ml1.language_id FROM movie_languages ml1
        WHERE ml.movie_id = ml1.movie_id)
FROM movie_languages ml
WHERE ml.movie_id IN (SELECT movie_id FROM compare_keywords)
GROUP BY ml.movie_id
;

CREATE INDEX compare_languages_idx_movie_id ON compare_languages(movie_id);
CREATE INDEX compare_languages_idx_language_ids ON compare_languages USING GIN(language_ids);


-- Main table for similarities. Index will be created after data is loaded.

CREATE TABLE compare_overlaps (
  movie_id INT NOT NULL, 
  compare_movie_id INT, 
  normal_normal_count INT,
  normal_strong_count INT,
  strong_normal_count INT,
  strong_strong_count INT,
  genre_overlap_count INT,
  language_overlap_count INT);

-- Create functions

CREATE OR REPLACE FUNCTION convert_to_integer(v_input text)
RETURNS INTEGER AS $$
DECLARE v_int_value INTEGER DEFAULT NULL;
BEGIN
    BEGIN
        v_int_value := v_input::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        RETURN 0;
    END;
RETURN v_int_value;
END;
$$ LANGUAGE plpgsql;
