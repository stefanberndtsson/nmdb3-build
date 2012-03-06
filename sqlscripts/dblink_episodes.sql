ALTER TABLE movies ADD COLUMN parent_id INT;
ALTER TABLE movies ADD COLUMN episode_sort_value INT;
UPDATE movies SET parent_id = t.parent_id 
       FROM 
       (SELECT m.id AS parent_id,e.id AS episode_id FROM movies m
        INNER JOIN movies e ON e.episode_parent_title = m.full_title) t
       WHERE id = t.episode_id;

CREATE OR REPLACE FUNCTION first_release_stamp(movie_id INT)
RETURNS INT
AS
$$
SELECT EXTRACT(epoch FROM MIN(release_stamp))::INT FROM release_dates WHERE movie_id = $1
$$
LANGUAGE SQL;

UPDATE movies SET episode_sort_value = first_release_stamp(id) WHERE is_episode = true;

CREATE INDEX movies_idx_parent_id ON movies (parent_id);
