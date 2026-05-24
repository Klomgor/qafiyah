-- scripts/sql/0006_floor_verse_count_nulls.sql
-- One-shot migration applied to the 0017 dump to produce the 0018 baseline.
-- Backfills the NULL verse_count rows (poems with odd line counts) using
-- floor(lines / 2), then promotes the column to NOT NULL.
--
-- Effect on the 1,429 odd-line poems:
--   1 line  → 0 verses
--   3 lines → 1 verse
--   5 lines → 2 verses ... etc.
--
-- NOT idempotent: re-running on already-migrated data raises an exception
-- via the pre-flight guard below.
BEGIN;

DO $$
DECLARE
  v_is_nullable text;
BEGIN
  SELECT is_nullable INTO v_is_nullable
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name   = 'poems'
    AND column_name  = 'verse_count';
  IF v_is_nullable IS NULL THEN
    RAISE EXCEPTION 'pre-flight failed: poems.verse_count does not exist (run 0005 first)';
  END IF;
  IF v_is_nullable = 'NO' THEN
    RAISE EXCEPTION 'pre-flight failed: poems.verse_count is already NOT NULL (already migrated?)';
  END IF;
END $$;

UPDATE public.poems
SET verse_count = array_length(string_to_array(content, '*'), 1) / 2
WHERE verse_count IS NULL;

ALTER TABLE public.poems ALTER COLUMN verse_count SET NOT NULL;

COMMIT;
