--DB Reset--
DROP TABLE IF EXISTS splits;
DROP TABLE IF EXISTS race_entries;
DROP TABLE IF EXISTS meets;
DROP TABLE IF EXISTS athletes;

--Athletes Table--
CREATE TABLE athletes (
    athlete_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    graduation_year INT NOT NULL
);

--Meets Table--
CREATE TABLE meets (
    meet_id SERIAL PRIMARY KEY,
    meet_name VARCHAR(100) NOT NULL,
    meet_date DATE NOT NULL,
    location VARCHAR(100) NOT NULL
);

--Race Entries Table--
CREATE TABLE race_entries (
    entry_id SERIAL PRIMARY KEY,
    athlete_id INT REFERENCES athletes(athlete_id) ON DELETE CASCADE,
    meet_id INT REFERENCES meets(meet_id) ON DELETE CASCADE,
    event_distance INT NOT NULL,
    final_time VarCHAR(10)
);

--Splits Table--
CREATE TABLE splits (
    split_id SERIAL PRIMARY KEY,
    entry_id INT REFERENCES race_entries(entry_id) ON DELETE CASCADE,
    lap_number INT NOT NULL,
    cumulative_time INTERVAL NOT NULL,
    lap_time INTERVAL NOT NULL
);

