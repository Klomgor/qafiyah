-- scripts/sql/0005_add_verse_count.sql
-- One-shot migration applied to the 0016 dump to produce the 0017 baseline.
-- Adds poems.verse_count and recreates poem_full_data to surface it.
--
-- Backfill rule: split content on '*', count resulting lines.
--   even line count  → verse_count = lines / 2
--   odd  line count  → verse_count = NULL  (irregular poem; consumer decides)
--
-- NOT idempotent: re-running on already-migrated data raises an exception
-- via the pre-flight guard below.
BEGIN;

DO $$
DECLARE
  v_has_column integer;
BEGIN
  SELECT count(*) INTO v_has_column
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name   = 'poems'
    AND column_name  = 'verse_count';
  IF v_has_column <> 0 THEN
    RAISE EXCEPTION 'pre-flight failed: poems.verse_count already exists (already migrated?)';
  END IF;
END $$;

ALTER TABLE public.poems ADD COLUMN verse_count integer;

UPDATE public.poems
SET verse_count = CASE
  WHEN array_length(string_to_array(content, '*'), 1) % 2 = 0
    THEN array_length(string_to_array(content, '*'), 1) / 2
  ELSE NULL
END;

-- poem_full_data is a regular view; recreate it to expose the new column.
DROP VIEW IF EXISTS public.poem_full_data;

CREATE VIEW public.poem_full_data AS
SELECT
  p.slug,
  p.title,
  p.content,
  p.verse_count,
  po.name AS poet_name,
  po.slug AS poet_slug,
  m.name  AS meter_name,
  t.name  AS theme_name,
  e.name  AS era_name,
  e.slug  AS era_slug
FROM public.poems p
JOIN public.poets  po ON p.poet_id  = po.id
JOIN public.meters m  ON p.meter_id = m.id
JOIN public.themes t  ON p.theme_id = t.id
JOIN public.eras   e  ON po.era_id  = e.id;

COMMIT;
