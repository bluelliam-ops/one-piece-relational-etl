-- One Piece Relational ETL Database
-- Schema (DDL) for the normalized Postgres tables produced by the ETL notebook.
-- Tables are listed in dependency order so this file can be run top-to-bottom
-- against a fresh Postgres database.
--
-- See docs/schema.png for the visual ERD, and One_Piece_Database.ipynb for how
-- each table is populated from the raw source data.

CREATE TABLE arcs (
  arc_id INTEGER PRIMARY KEY,
  arc_name VARCHAR(255) NOT NULL,
  arc_order INTEGER
);

CREATE TABLE episodes (
  episode_id INTEGER PRIMARY KEY,
  episode_name VARCHAR(500),
  arc_id INTEGER REFERENCES arcs(arc_id),
  summary TEXT
);

CREATE TABLE characters (
  character_id INTEGER PRIMARY KEY,
  canonical_name VARCHAR(255) NOT NULL,
  japanese_name VARCHAR(255),
  romanized_name VARCHAR(255),
  official_english_name VARCHAR(500),
  origin VARCHAR(255),
  residence VARCHAR(255),
  debut_episodes_id INTEGER REFERENCES episodes(episode_id),
  debut_manga_id INTEGER,
  affiliations VARCHAR(255),
  status VARCHAR(100),
  age_at_death INTEGER,
  height_cm INTEGER,
  blood_type VARCHAR(100),
  devil_fruit VARCHAR(225),
  devil_fruit_type VARCHAR(225),
  birthday VARCHAR(100),
  liveaction_portrayal VARCHAR(255),
  name_meaning VARCHAR(225)
);

CREATE TABLE character_aliases (
  alias_id INTEGER PRIMARY KEY,
  character_id INTEGER REFERENCES characters(character_id),
  alias_text VARCHAR(500),
  source_dataset VARCHAR(225)
);

CREATE TABLE character_episode_appearances (
  appearance_id INTEGER PRIMARY KEY,
  episode_id INTEGER REFERENCES episodes(episode_id),
  character_id INTEGER REFERENCES characters(character_id),
  appearance_order INTEGER
);

CREATE TABLE cards (
  card_id VARCHAR(50) PRIMARY KEY,
  card_code VARCHAR(50),
  card_art_variant INTEGER,
  card_name VARCHAR(225),
  character_id INTEGER REFERENCES characters(character_id),
  card_rarity VARCHAR(50),
  card_color VARCHAR(50),
  card_expansion VARCHAR(50),
  card_power INTEGER,
  card_cost INTEGER,
  card_counter INTEGER,
  card_effect TEXT,
  card_trigger TEXT,
  card_image VARCHAR(255),
  card_type VARCHAR(50),
  card_banned BOOLEAN,
  is_character_card BOOLEAN
);

CREATE TABLE card_factions (
  card_faction_id INTEGER PRIMARY KEY,
  card_id VARCHAR(50) REFERENCES cards(card_id),
  faction_name VARCHAR(225)
);
