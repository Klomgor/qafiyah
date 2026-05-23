# Database Dumps

PostgreSQL custom-format (`pg_dump -Fc`) snapshots of the `public` schema.

## Directory Naming Convention

Each dump is stored in a subdirectory named `{sequence}_{DD}_{MM}_{YYYY}`, where `{sequence}` is a zero-padded four-digit index that determines sort order. Example: `0003_29_01_2026` is the third dump, created on 29 January 2026. The highest-numbered directory always contains the current dump.

## Dataset Contents

The current dump (`0005_23_05_2026` — the `0004` dataset with the era set consolidated:
the legacy `متأخر` era and all its poets/poems removed, `مخضرم` merged into `إسلامي`,
and `أيوبي` / `مملوكي` / `عثماني` merged into a fresh `متأخر`; see
`scripts/sql/0002_consolidate_eras.sql`) contains:

| Metric          | Count   |
| --------------- | ------- |
| Verses          | 901,728 |
| Poems           | 81,232  |
| Poets           | 921     |
| Historical eras | 6       |
| Meters          | 44      |
| Rhyme patterns  | 47      |
| Themes          | 27      |

## Format Compatibility

Dumps are produced with `pg_dump -Fc` (PostgreSQL custom format, version 1.16). PostgreSQL 17 or later is required to restore them with `pg_restore`. Older PostgreSQL versions may produce an error about an unsupported dump format version.

## Requirements

- PostgreSQL ≥ 17 (the dumps target format version 1.16)
- `pg_restore`

## Restore (local development)

If you are working in this repo, the database self-seeds: `bun run db:up` spins up Postgres in Docker and restores the newest dump on a fresh volume (or `bun run dev` to also start the app). To force a re-restore from a newer dump on an existing volume, use `bun run db:reset`:

```bash
bun run db:up       # or: bun run db:reset to wipe the volume + re-seed
```

## Restore (manual / external use)

Find the latest dump file and restore it:

```bash
# Find the latest dump: ls dumps/*/\*.dump | sort | tail -1
dropdb --if-exists qafiyah && createdb qafiyah && \
pg_restore \
  -U qafiyah \
  -d qafiyah \
  --no-owner \
  --no-privileges \
  ./0005_23_05_2026/qafiyah_public_20260523_054339.dump
```

## Verify

```bash
psql -U qafiyah -d qafiyah -c "\dt"
psql -U qafiyah -d qafiyah -c "SELECT count(*) FROM poems;"
```
