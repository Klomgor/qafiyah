# Database Dumps

PostgreSQL custom-format (`pg_dump -Fc`) snapshots of the `public` schema.

## Directory Naming Convention

Each dump is stored in a subdirectory named `{sequence}_{DD}_{MM}_{YYYY}`, where `{sequence}` is a zero-padded four-digit index that determines sort order. Example: `0003_29_01_2026` is the third dump, created on 29 January 2026. The highest-numbered directory always contains the current dump.

## Dataset Contents

The current dump (`0031_26_05_2026`) drops and recreates the `poems.title`
`GENERATED ALWAYS AS STORED` column to refresh all stored values. The
definition is unchanged — `split_part(content, '*', 1)` — but the column
position moves to last and the `poem_full_data` view is recreated in lock
step. No data rows were added or removed.

`0030_26_05_2026` consolidates the 6 random-poem SQL
functions into one. `get_random_eligible_poem_slug`, `get_random_eligible_poet`,
`get_random_poem_by_poet`, `get_poem_details`, and `get_poem_slug` are dropped.
`get_random_eligible_poem` is replaced with a single CTE that returns
`poem_id`, `poet_name`, `content`, and `slug` in one query. See
`scripts/sql/0014_consolidate_random_poem_functions.sql`.

`0029_26_05_2026` consolidates meters to the 16 canonical
Khalilian meters. The 7 non-classical meters (موشح, مخلع, الدوبيت, المواليا,
أحذ, عدد, مجزوء) are collapsed into a new catch-all entry **غير ذلك**
(11,096 poems reassigned). The two Khalilian meters missing from the previous
dataset — **المضارع** and **المقتضب** — are added as empty rows. Meter count
drops from 21 to 17 (16 classical + غير ذلك).

`0028_25_05_2026` adds the `poem_relations` table:
396,790 precomputed rows (5 related poems per poem) scored by shared
collection (6), poet (5), era (4), theme (3), rhyme (2), and meter (1).
The old `get_related_poems` and `get_poem_with_related` SQL functions are
dropped. Schema change documented in `scripts/sql/0013_poem_relations.sql`.

`0027_25_05_2026` was the `0026` dataset with 309
content-duplicate poems removed: rows sharing identical `content` (across
any poet) were deduplicated by keeping the row whose poet belongs to the
earliest era (lowest `eras.sort_order`), breaking ties by the lowest
`poems.id`, and deleting the rest. Poem count reduced from 79,667 to
79,358.

`0026_25_05_2026` was the `0025` dataset with curated era slugs
(`jahili`, `islami`, `umawi`, `abbasi`, `andalusi`, `mutaakhkhir`) and
`eras.sort_order` (1–6) added to the `eras` table.

`0025_25_05_2026` was the `0024` dataset with 354
duplicate poems removed: rows sharing identical `poet_id` + `content`
were deduplicated by keeping the lowest `id` and deleting the rest,
reducing the poem count from 80,021 to 79,667.

`0024_25_05_2026` was the `0023` dataset with `poems.title`
converted from a manually-curated column to a `GENERATED ALWAYS AS STORED`
column derived from `split_part(content, '*', 1)` (the first verse line).
2,535 stored titles previously diverged from the actual first line; they
are now always in sync. See `scripts/sql/0011_regenerate_titles.sql`.

`0023_25_05_2026` was the `0022` dataset with the duplicate poet
أبو النجم العجلي merged: the source had two poet rows holding identical
72-poem sets; the `-b`-suffixed duplicate and its 72 redundant poems were
removed, leaving one poet with the bare `abu-alnajm-alajli` slug. See
`scripts/sql/0010_dedupe_abu_alnajm.sql`.

`0022_25_05_2026` was the `0021` dataset with unified slug generation
applied: a single `public.generate_slug(mode, input)` function backs
every slug, all UUID slugs were converted to text (`themes`,
`collections`, `poems`), and existing transliterated slugs were
re-normalized to the new rule — lowercase letters + hyphens only,
article "al" joined to the next word, no digits. See
`scripts/sql/0009_unified_slug_generation.sql`.) contains:

| Metric          | Count   |
| --------------- | ------- |
| Poems           | 79,358  |
| Poets           | 580     |
| Historical eras | 6       |
| Meters          | 17      |
| Rhyme letters   | 36      |
| Themes          | 9       |
| Collections     | 1       |
| Poem relations  | 396,790 |

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
  ./0031_26_05_2026/qafiyah_public_20260526_013039.dump
```

## Verify

```bash
psql -U qafiyah -d qafiyah -c "\dt"
psql -U qafiyah -d qafiyah -c "SELECT count(*) FROM poems;"
```
