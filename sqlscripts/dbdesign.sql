DROP AGGREGATE IF EXISTS textcat_all(text);

CREATE AGGREGATE textcat_all(
       basetype    = text,
       sfunc       = textcat,
       stype       = text,
       initcond    = ''
);

CREATE TABLE movies (
       id INT PRIMARY KEY,
       full_title TEXT,
       episode_parent_title TEXT,
       title TEXT,
       full_year TEXT,
       year_open_end BOOLEAN,
       title_year VARCHAR(200),
       title_category VARCHAR(200),
       is_episode BOOLEAN,
       episode_name TEXT,
       episode_season INT,
       episode_episode INT,
       suspended TEXT,
       title_norm TEXT,
       episode_name_norm TEXT
);

CREATE TABLE movie_akas (
       id INT PRIMARY KEY,
       movie_id INT,
       title TEXT,
       info TEXT,
       title_norm TEXT
);

CREATE TABLE movie_years (
       id INT PRIMARY KEY,
       movie_id INT,
       year VARCHAR(200)
);

CREATE TABLE people (
       id INT PRIMARY KEY,
       full_name TEXT,
       first_name TEXT,
       last_name TEXT,
       name_count TEXT,
       name_norm TEXT
);

CREATE TABLE occupations (
       id INT PRIMARY KEY,
       person_id INT,
       movie_id INT,
       role_id INT,
       "character" TEXT,
       sort_value VARCHAR(200),
       extras TEXT,
       occupation_score INT,
       episode_count INT,
       collected BOOLEAN,
       character_norm TEXT
);

CREATE TABLE roles (
       id INT PRIMARY KEY,
       "group" INT,
       "role" VARCHAR(200)
);

CREATE TABLE person_metadata (
       id INT PRIMARY KEY,
       person_id INT,
       key TEXT,
       value TEXT,
       sort_order INT,
       author TEXT,
       value_norm TEXT
);

CREATE TABLE movie_genres (
       id INT PRIMARY KEY,
       movie_id INT,
       genre_id INT
);

CREATE TABLE genres (
       id INT PRIMARY KEY,
       genre VARCHAR(200)
);

CREATE TABLE movie_keywords (
       id INT PRIMARY KEY,
       movie_id INT,
       keyword_id INT
);

CREATE TABLE keywords (
       id INT PRIMARY KEY,
       keyword VARCHAR(200)
);

CREATE TABLE movie_languages (
       id INT PRIMARY KEY,
       movie_id INT,
       language_id INT,
       info TEXT
);

CREATE TABLE languages (
       id INT PRIMARY KEY,
       language VARCHAR(200)
);

CREATE TABLE ratings (
       id INT PRIMARY KEY,
       movie_id INT,
       rating FLOAT,
       votes INT,
       distribution VARCHAR(200)
);

CREATE TABLE running_times (
       id INT PRIMARY KEY,
       movie_id INT,
       running_time TEXT,
       location TEXT,
       info TEXT
);

CREATE TABLE goofs (
       id INT PRIMARY KEY,
       movie_id INT,
       category VARCHAR(200),
       spoiler BOOLEAN,
       goof TEXT,
       goof_norm TEXT
);

CREATE TABLE trivia (
       id INT PRIMARY KEY,
       movie_id INT,
       spoiler BOOLEAN,
       trivia TEXT,
       trivia_norm TEXT
);

CREATE TABLE plots (
       id INT PRIMARY KEY,
       movie_id INT,
       plot TEXT,
       author TEXT,
       plot_norm TEXT
);

CREATE TABLE complete_cast_statuses (
       id INT PRIMARY KEY,
       status TEXT
);

CREATE TABLE complete_casts (
       id INT PRIMARY KEY,
       movie_id INT,
       complete_cast_status_id INT
);

CREATE TABLE complete_crew_statuses (
       id INT PRIMARY KEY,
       status TEXT
);

CREATE TABLE complete_crews (
       id INT PRIMARY KEY,
       movie_id INT,
       complete_crew_status_id INT
);

CREATE TABLE movie_connection_types (
       id INT PRIMARY KEY,
       connection_type TEXT,
       sort_order INT
);

CREATE TABLE movie_connections (
       id INT PRIMARY KEY,
       movie_id INT,
       linked_movie_id INT,
       movie_connection_type_id INT
);

CREATE TABLE release_dates (
       id INT PRIMARY KEY,
       movie_id INT,
       country TEXT,
       release_date TEXT,
       release_stamp TIMESTAMP,
       info TEXT
);

CREATE TABLE soundtrack_titles (
       id INT PRIMARY KEY,
       movie_id INT,
       title TEXT,
       sort_order INT
);

CREATE TABLE soundtrack_title_data (
       id INT PRIMARY KEY,
       soundtrack_title_id INT,
       value TEXT,
       sort_order INT
);

CREATE TABLE taglines (
       id INT PRIMARY KEY,
       movie_id INT,
       tagline TEXT,
       sort_order INT
);

CREATE TABLE technicals (
       id INT PRIMARY KEY,
       movie_id INT,
       key TEXT,
       value TEXT,
       info TEXT
);

CREATE TABLE alternate_versions (
       id INT PRIMARY KEY,
       movie_id INT,
       parent_id INT,
       spoiler BOOLEAN,
       alternate_version TEXT       
);

CREATE TABLE aka_names (
       id INT PRIMARY KEY,
       person_id INT,
       name TEXT,
       sort_order INT,
       name_norm TEXT
);

CREATE TABLE certificates (
       id INT PRIMARY KEY,
       movie_id INT,
       country TEXT,
       certificate TEXT,
       info TEXT
);

CREATE TABLE color_infos (
       id INT PRIMARY KEY,
       movie_id INT,
       color TEXT,
       info TEXT
);

CREATE TABLE crazy_credits (
       id INT PRIMARY KEY,
       movie_id INT,
       spoiler BOOLEAN,
       credit TEXT
);

CREATE TABLE quotes (
       id INT PRIMARY KEY,
       movie_id INT,
       sort_order INT
);

CREATE TABLE quote_data (
       id INT PRIMARY KEY,
       quote_id INT,
       value TEXT,
       sort_order INT,
       value_norm TEXT
);

CREATE TABLE users (
       id SERIAL,
       username TEXT,
       password TEXT,
       name TEXT,
       api_key TEXT,
       admin BOOLEAN
);

CREATE TABLE user_sessions (
       id SERIAL,
       user_id INT,
       session TEXT,
       expires_at TIMESTAMP
);

CREATE TABLE user_settings (
       id SERIAL,
       user_id INT,
       section TEXT,
       key TEXT,
       value TEXT
);

CREATE TABLE user_movie_data (
       id SERIAL,
       user_id INT,
       movie_id INT,
       key TEXT,
       value TEXT,
       created_at TIMESTAMP,
       updated_at TIMESTAMP
);

-- Search (Not actually used)
CREATE TABLE searches (
       id SERIAL,
       title TEXT,
       link_score INT,
       occupation_score INT
);
