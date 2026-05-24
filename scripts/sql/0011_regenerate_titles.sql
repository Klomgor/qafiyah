-- scripts/sql/0011_regenerate_titles.sql
-- Replaces the manually-curated poems.title column with a STORED GENERATED
-- column derived from the first line of content (text before the first '*').
-- The 0023 dump had 2,535 poems whose stored title differed from
-- split_part(content,'*',1); this eliminates that drift permanently.

BEGIN;

DO $$
DECLARE
  v_poem_count  integer;
  v_drift_count integer;
BEGIN
  SELECT count(*) INTO v_poem_count FROM public.poems;
  IF v_poem_count = 0 THEN
    RAISE EXCEPTION 'pre-flight: poems table is empty';
  END IF;
  SELECT count(*) INTO v_drift_count
    FROM public.poems WHERE title <> split_part(content, '*', 1);
  RAISE NOTICE 'pre-flight: % poems, % titles diverge from first content line',
    v_poem_count, v_drift_count;
END $$;

-- poem_full_data depends on poems.title; drop it before altering the column.
-- Note: despite the Drizzle schema using pgMaterializedView, the DB object is a regular view.
DROP VIEW IF EXISTS public.poem_full_data;

ALTER TABLE public.poems DROP COLUMN title;

ALTER TABLE public.poems
  ADD COLUMN title text
  GENERATED ALWAYS AS (split_part(content, '*', 1)) STORED NOT NULL;

-- Recreate the view with the same definition as before.
CREATE VIEW public.poem_full_data AS
  SELECT p.slug,
         p.title,
         p.content,
         p.verse_count,
         po.name AS poet_name,
         po.slug AS poet_slug,
         m.name  AS meter_name,
         t.name  AS theme_name,
         e.name  AS era_name,
         e.slug  AS era_slug,
         c.name  AS collection_name,
         c.slug  AS collection_slug
    FROM public.poems p
    JOIN public.poets      po ON p.poet_id      = po.id
    JOIN public.meters     m  ON p.meter_id     = m.id
    JOIN public.themes     t  ON p.theme_id     = t.id
    JOIN public.eras       e  ON po.era_id      = e.id
    LEFT JOIN public.collections c ON p.collection_id = c.id;

DO $$
DECLARE
  v_poem_count   integer;
  v_null_titles  integer;
  v_empty_titles integer;
BEGIN
  SELECT count(*) INTO v_poem_count   FROM public.poems;
  SELECT count(*) INTO v_null_titles  FROM public.poems WHERE title IS NULL;
  SELECT count(*) INTO v_empty_titles FROM public.poems WHERE title = '';

  IF v_null_titles > 0 THEN
    RAISE EXCEPTION 'post-flight: % NULL titles found', v_null_titles;
  END IF;
  IF v_empty_titles > 0 THEN
    RAISE EXCEPTION 'post-flight: % empty titles found', v_empty_titles;
  END IF;
  RAISE NOTICE 'post-flight: % poems, 0 NULL/empty titles — OK', v_poem_count;
END $$;

COMMIT;
