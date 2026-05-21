-- scripts/sql/0001_drop_search.sql
-- Removes the custom PostgreSQL FTS search machinery from the Qafiyah schema.
-- Applied once to a dump restored from 0003 to produce the 0004 baseline.
-- Idempotent: safe to re-run.
BEGIN;

DROP INDEX IF EXISTS poems_search_idx;
DROP INDEX IF EXISTS poets_search_idx;

ALTER TABLE poems DROP COLUMN IF EXISTS search_vector;
ALTER TABLE poets DROP COLUMN IF EXISTS search_vector;

DROP FUNCTION IF EXISTS search_poems(text, integer, text, integer[], integer[], integer[], integer[]);
DROP FUNCTION IF EXISTS search_poets(text, integer, text, integer[]);
DROP FUNCTION IF EXISTS normalize_arabic_text(text, boolean);

COMMIT;
