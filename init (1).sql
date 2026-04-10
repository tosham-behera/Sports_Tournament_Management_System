-- ============================================
-- SPORTS TOURNAMENT MANAGEMENT SYSTEM
-- init.sql - Run this file once to set up DB
-- ============================================

DROP DATABASE IF EXISTS sports_tournament;
CREATE DATABASE sports_tournament;
USE sports_tournament;

-- ============================================
-- TABLES
-- ============================================

CREATE TABLE Sports (
    sport_id   INT AUTO_INCREMENT PRIMARY KEY,
    sport_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Venues (
    venue_id   INT AUTO_INCREMENT PRIMARY KEY,
    venue_name VARCHAR(150) NOT NULL,
    city       VARCHAR(100) NOT NULL
);

CREATE TABLE Referees (
    referee_id   INT AUTO_INCREMENT PRIMARY KEY,
    referee_name VARCHAR(100) NOT NULL,
    sport_id     INT NOT NULL,
    FOREIGN KEY (sport_id) REFERENCES Sports(sport_id) ON DELETE CASCADE
);

CREATE TABLE Teams (
    team_id      INT AUTO_INCREMENT PRIMARY KEY,
    team_name    VARCHAR(100) NOT NULL UNIQUE,
    sport_id     INT NOT NULL,
    total_wins   INT DEFAULT 0,
    total_losses INT DEFAULT 0,
    FOREIGN KEY (sport_id) REFERENCES Sports(sport_id) ON DELETE CASCADE
);

CREATE TABLE Players (
    player_id   INT AUTO_INCREMENT PRIMARY KEY,
    player_name VARCHAR(100) NOT NULL,
    age         INT NOT NULL,
    position    VARCHAR(50),
    team_id     INT NOT NULL,
    FOREIGN KEY (team_id) REFERENCES Teams(team_id) ON DELETE CASCADE
);

CREATE TABLE Matches (
    match_id    INT AUTO_INCREMENT PRIMARY KEY,
    sport_id    INT NOT NULL,
    venue_id    INT NOT NULL,
    referee_id  INT NOT NULL,
    team1_id    INT NOT NULL,
    team2_id    INT NOT NULL,
    team1_score INT DEFAULT 0,
    team2_score INT DEFAULT 0,
    match_date  DATE NOT NULL,
    -- CONSTRAINT: a team cannot play itself
    CONSTRAINT chk_different_teams CHECK (team1_id != team2_id),
    FOREIGN KEY (sport_id)   REFERENCES Sports(sport_id),
    FOREIGN KEY (venue_id)   REFERENCES Venues(venue_id),
    FOREIGN KEY (referee_id) REFERENCES Referees(referee_id),
    FOREIGN KEY (team1_id)   REFERENCES Teams(team_id),
    FOREIGN KEY (team2_id)   REFERENCES Teams(team_id)
);

-- ============================================
-- VIEW: Tournament_Standings
-- ============================================

CREATE VIEW Tournament_Standings AS
SELECT
    t.team_id,
    t.team_name,
    s.sport_name,
    t.total_wins   AS wins,
    t.total_losses AS losses
FROM Teams t
JOIN Sports s ON t.sport_id = s.sport_id
ORDER BY t.total_wins DESC;

-- ============================================
-- TRIGGER 1: After_Match_Insert
-- Auto-updates wins/losses after a match insert
-- ============================================

DELIMITER //

CREATE TRIGGER After_Match_Insert
AFTER INSERT ON Matches
FOR EACH ROW
BEGIN
    IF NEW.team1_score > NEW.team2_score THEN
        UPDATE Teams SET total_wins   = total_wins   + 1 WHERE team_id = NEW.team1_id;
        UPDATE Teams SET total_losses = total_losses + 1 WHERE team_id = NEW.team2_id;
    ELSEIF NEW.team2_score > NEW.team1_score THEN
        UPDATE Teams SET total_wins   = total_wins   + 1 WHERE team_id = NEW.team2_id;
        UPDATE Teams SET total_losses = total_losses + 1 WHERE team_id = NEW.team1_id;
    END IF;
END //

-- ============================================
-- TRIGGER 2: Prevent_Negative_Age
-- Blocks inserting a player with negative age
-- ============================================

CREATE TRIGGER Prevent_Negative_Age
BEFORE INSERT ON Players
FOR EACH ROW
BEGIN
    IF NEW.age < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Age cannot be negative';
    END IF;
END //

-- ============================================
-- TRIGGER 3: Prevent_Win_Reduction
-- Ensures total_wins can never be reduced
-- ============================================

CREATE TRIGGER Prevent_Win_Reduction
BEFORE UPDATE ON Teams
FOR EACH ROW
BEGIN
    IF NEW.total_wins < OLD.total_wins THEN
        SET NEW.total_wins = OLD.total_wins;
    END IF;
END //

DELIMITER ;

-- ============================================
-- STORED PROCEDURE 1: List_All_Players
-- Cursor loops through all players with sport
-- ============================================

DELIMITER //

CREATE PROCEDURE List_All_Players()
BEGIN
    DECLARE done      INT DEFAULT FALSE;
    DECLARE v_player  VARCHAR(100);
    DECLARE v_sport   VARCHAR(100);
    DECLARE v_team    VARCHAR(100);

    DECLARE player_cursor CURSOR FOR
        SELECT p.player_name, s.sport_name, t.team_name
        FROM Players p
        JOIN Teams  t ON p.team_id  = t.team_id
        JOIN Sports s ON t.sport_id = s.sport_id
        ORDER BY s.sport_name, t.team_name;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN player_cursor;
    read_loop: LOOP
        FETCH player_cursor INTO v_player, v_sport, v_team;
        IF done THEN LEAVE read_loop; END IF;
        SELECT v_player AS Player, v_sport AS Sport, v_team AS Team;
    END LOOP;
    CLOSE player_cursor;
END //

-- ============================================
-- STORED PROCEDURE 2: Show_All_Sports
-- Cursor loops through all sports
-- ============================================

CREATE PROCEDURE Show_All_Sports()
BEGIN
    DECLARE done   INT DEFAULT 0;
    DECLARE s_name VARCHAR(100);

    DECLARE sport_cursor CURSOR FOR SELECT sport_name FROM Sports;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN sport_cursor;
    read_loop: LOOP
        FETCH sport_cursor INTO s_name;
        IF done = 1 THEN LEAVE read_loop; END IF;
        SELECT s_name AS Sport_Name;
    END LOOP;
    CLOSE sport_cursor;
END //

-- ============================================
-- STORED PROCEDURE 3: Show_Team_Losses
-- Cursor loops through all teams and losses
-- ============================================

CREATE PROCEDURE Show_Team_Losses()
BEGIN
    DECLARE done     INT DEFAULT 0;
    DECLARE t_name   VARCHAR(100);
    DECLARE t_losses INT;

    DECLARE team_cursor CURSOR FOR SELECT team_name, total_losses FROM Teams;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN team_cursor;
    read_loop: LOOP
        FETCH team_cursor INTO t_name, t_losses;
        IF done = 1 THEN LEAVE read_loop; END IF;
        SELECT t_name AS Team, t_losses AS Losses;
    END LOOP;
    CLOSE team_cursor;
END //

DELIMITER ;

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO Sports (sport_name) VALUES
    ('Football'), ('Cricket'), ('Basketball'), ('Tennis'), ('Hockey');

INSERT INTO Venues (venue_name, city) VALUES
    ('MA Chidambaram Stadium', 'Chennai'),
    ('Wankhede Stadium',       'Mumbai'),
    ('Eden Gardens',           'Kolkata'),
    ('Jawaharlal Nehru Stadium','Delhi'),
    ('Chinnaswamy Stadium',    'Bangalore');

INSERT INTO Referees (referee_name, sport_id) VALUES
    ('Rajesh Kumar',  1),
    ('Anil Sharma',   1),
    ('Suresh Patel',  2),
    ('Mohan Das',     2),
    ('Kiran Rao',     3);

INSERT INTO Teams (team_name, sport_id) VALUES
    ('Chennai Strikers',    1),
    ('Mumbai FC',           1),
    ('Delhi Warriors',      1),
    ('Bangalore Blazers',   2),
    ('Kolkata Knights',     2);

INSERT INTO Players (player_name, age, position, team_id) VALUES
    ('Arjun Sharma',  22, 'Forward',     1),
    ('Ravi Patel',    25, 'Midfielder',  1),
    ('Sunil Kumar',   28, 'Defender',    2),
    ('Mohan Singh',   21, 'Forward',     2),
    ('Karan Verma',   26, 'Midfielder',  3),
    ('Aman Gupta',    24, 'Batsman',     4),
    ('Rohan Das',     29, 'Bowler',      4),
    ('Vijay Nair',    23, 'Batsman',     5),
    ('Sanjay Iyer',   27, 'All-rounder', 5);

-- NOTE: Sample matches use future dates so they pass the date validation
INSERT INTO Matches (sport_id, venue_id, referee_id, team1_id, team2_id, team1_score, team2_score, match_date) VALUES
    (1, 1, 1, 1, 2, 3, 1, '2026-04-15'),
    (1, 4, 2, 2, 3, 2, 2, '2026-04-20'),
    (1, 1, 1, 1, 3, 1, 0, '2026-05-05'),
    (2, 2, 3, 4, 5, 0, 1, '2026-05-10');
