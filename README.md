# One Piece Relational ETL Database

A normalized relational database that links **One Piece** anime/manga data (characters, episodes, story arcs) to the **One Piece Trading Card Game**, built with a pandas ETL pipeline and loaded into Postgres.

Three messy, independently-sourced datasets — a wiki scrape of characters, an episode/arc list, and a TCG card database — share no common ID and use different name spellings for the same character. The pipeline resolves that: it builds one canonical name and ID per character, maps every alternate spelling from every source onto it, and produces seven clean, foreign-key-linked tables that can answer questions no single source could answer alone, such as:

- Does a character's death status affect how often they're chosen for cards?
- Does appearing in more episodes correlate with having more cards?
- Do characters who debut earlier in the story end up with rarer cards?

## Entity-relationship diagram

![Schema ERD](docs/schema.png)

Seven tables: `arcs`, `episodes`, `characters`, `character_aliases`, `character_episode_appearances`, `cards`, and `card_factions`. Full column-level DDL is in [`schema.sql`](schema.sql).

## How the pipeline works

The notebook ([`One_Piece_Database.ipynb`](One_Piece_Database.ipynb)) follows a standard Extract → Transform → Load structure:

**Extract** — loads the three raw source files and profiles each one for nulls, row meaning, and structural quirks (e.g. the raw character table is actually a 57-column dump of the wiki's character, organization, *and* ship infoboxes mixed together).

**Transform** — the bulk of the work:
- Builds one `canonical_name` per character (preferring the official English name, falling back to the romanized name, then the raw wiki name), fixes ~29 names that got glued together by a missing separator, and resolves 8 collisions where the same name string referred to two different characters.
- Assigns a stable `character_id` and builds a separate `character_aliases` table, since the TCG and episode datasets each spell character names differently (e.g. a card might say `Tony.Tony.Chopper` while an episode credit says `Chopper`) and each needs to resolve to the same ID.
- Pulls `arcs` into its own table (derived from the earliest episode of each arc, since arc order doesn't exist anywhere in the source data) and normalizes `episodes`.
- Explodes the episode dataset's `character_appearances` column — stored as a Python list inside a single CSV cell — into a proper `character_episode_appearances` join table, one row per (episode, character) pair. ~26,900 appearances matched automatically; the remaining unmatched names were resolved by frequency — anything appearing in 15+ episodes was manually verified and added as a new alias, everything rarer was dropped rather than risk mis-merging into a major character.
- Cleans `Debut` (a mixed "Chapter X; Episode Y" text field) into separate, validated `debut_episode_id` and `debut_manga_id` columns, and similarly cleans `height_cm`, `age_at_death`, and `devil_fruit`.
- Matches `cards` to `characters` by normalizing card names the same way, with a manual fix-up list for ~26 cards whose name included an alias/nickname (e.g. `Lucy` for `Sabo`) not present anywhere else. Splits each card's multi-value type field out into a `card_factions` table so questions like "how many cards are in the Straw Hat Crew faction" are queryable.

**Load** — creates the Postgres tables from `schema.sql` and bulk-loads each with `psycopg2.extras.execute_values()` (notably faster than `executemany()` for this row count).

**Check it** — a handful of verification queries, followed by three queries that answer the research questions above directly against the loaded database.

## Data sources

Raw data is **not included in this repo** (see [Data files](#data-files) below) — download the three CSVs yourself from Kaggle:

- [One Piece Episode Summaries (Episodes 1–1130)](https://www.kaggle.com/datasets/tejadhiya/one-piece-episode-summaries-episodes-1-1130/data)
- [One Piece TCG Card Database – July 2025](https://www.kaggle.com/datasets/jbowski/one-piece-tcg-card-database?resource=download)
- [One Piece Dataset](https://www.kaggle.com/datasets/mexwell/one-piece-dataset) (character wiki data)

Each dataset's license terms are set by its Kaggle uploader — check the license badge on each page before redistributing the raw files yourself. The underlying character, episode, and card data ultimately belongs to Eiichiro Oda / Shueisha / Toei Animation / Bandai; this project is a fan-made, non-commercial data engineering exercise.

### Data files

- `data/raw/` — put the three downloaded CSVs here (gitignored — not checked in).
- `data/processed/` — the seven cleaned, final tables as CSVs, exported directly from the notebook's transform step, so you can explore the results without running the pipeline or standing up a database.

## Setup

```bash
git clone <this-repo-url>
cd one-piece-relational-etl
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

1. Download the three source CSVs from the links above into `data/raw/` (see the notebook's Extract section for the exact filenames it expects).
2. Copy `.env.example` to `.env` and fill in `DATABASE_URL` with a Postgres connection string (any standard Postgres works — a free tier on [Aiven](https://aiven.io), [Supabase](https://supabase.com), [Neon](https://neon.tech), or a local instance).
3. Run `jupyter notebook One_Piece_Database.ipynb` and run all cells top to bottom.

Alternatively, run everything against the tables directly with `psql` using [`schema.sql`](schema.sql) and the CSVs in `data/processed/`.

## Sample queries

From the notebook's "Check It" section, run against the loaded database:

**How many cards does each character have?**

| canonical_name | card_count |
|---|---|
| Monkey D. Luffy | 120 |
| Sanji | 54 |
| Nami | 52 |
| Trafalgar D. Water Law | 50 |
| Roronoa Zoro | 47 |

**Does a character's debut arc predict how many cards they get?**

| arc_name | arc_order | characters_debuted | total_card_count |
|---|---|---|---|
| Romance Dawn Arc | 1 | 18 | 259 |
| Orange Town Arc | 2 | 23 | 109 |
| Syrup Village Arc | 3 | 19 | 21 |
| Baratie Arc | 4 | 17 | 95 |
| Dressrosa Arc | 53 | 92 | 191 |
| Wano Country Arc | 60 | 214 | 157 |

**Does more episode appearances mean rarer (SEC) cards?**

| canonical_name | sec_card_count | episode_appearances |
|---|---|---|
| Monkey D. Luffy | 15 | 1075 |
| Shanks | 5 | 78 |
| Roronoa Zoro | 4 | 797 |
| Charlotte Katakuri | 4 | 49 |

See the notebook for the full query SQL and complete results.

## Tech stack

pandas / numpy for the ETL, Postgres for storage, psycopg2 for loading, all orchestrated from a single Jupyter notebook.

## License

Code and documentation in this repo are MIT-licensed (see [`LICENSE`](LICENSE)). The underlying One Piece data is not — see [Data sources](#data-sources).
