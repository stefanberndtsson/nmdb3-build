ALTER TABLE movies ADD COLUMN parent_id INT;
UPDATE movies SET parent_id = t.parent_id 
       FROM 
       (SELECT m.id AS parent_id,e.id AS episode_id FROM movies m
        INNER JOIN movies e ON e.episode_parent_title = m.full_title) t
       WHERE id = t.episode_id;

CREATE INDEX movies_idx_parent_id ON movies (parent_id);
