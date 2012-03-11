ALTER TABLE movies ADD COLUMN parent_id INT;
ALTER TABLE movies ADD COLUMN movie_sort_value INT8;
UPDATE movies SET parent_id = t.parent_id 
       FROM 
       (SELECT m.id AS parent_id,e.id AS episode_id FROM movies m
        INNER JOIN movies e ON e.episode_parent_title = m.full_title) t
       WHERE id = t.episode_id;

UPDATE movies m SET movie_sort_value = rd.stamp
       FROM (SELECT movie_id,EXTRACT(epoch FROM MIN(release_stamp)) AS stamp
                    FROM release_dates
                    GROUP BY movie_id) rd
       WHERE m.id = rd.movie_id;

CREATE INDEX movies_idx_parent_id ON movies (parent_id);
