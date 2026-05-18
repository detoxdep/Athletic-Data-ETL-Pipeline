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

-- 1. Ensure the fallback meet exists
INSERT INTO meets (meet_id, meet_name, meet_date, location) 
VALUES (1, 'Time Trial / Unassigned Meet', '2026-05-18', 'Home Track')
ON CONFLICT (meet_id) DO NOTHING;

-- 2. Seed the athletes with matching IDs
INSERT INTO athletes (athlete_id, first_name, last_name, gender, graduation_year)
VALUES 
    (101, 'Alex', 'TrackTeam', 'Boys', 2026),
    (102, 'Ryan', 'TrackTeam', 'Boys', 2026),
    (201, 'Sam', 'XCTeam', 'Boys', 2027),
    (202, 'Kyle', 'XCTeam', 'Boys', 2027),
    (301, 'Ben', 'JVTeam', 'Boys', 2029)
ON CONFLICT (athlete_id) DO NOTHING;

-- 3. Reset the internal ID counter so future auto-generations don't conflict
SELECT setval(pg_get_serial_sequence('athletes', 'athlete_id'), COALESCE(MAX(athlete_id), 1)) FROM athletes;