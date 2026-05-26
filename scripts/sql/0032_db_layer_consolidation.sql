-- scripts/sql/0032_db_layer_consolidation.sql
-- DB Layer Consolidation: 2026-05-26
-- Apply to dev:  psql -U qafiyah -d qafiyah -h 127.0.0.1 -p 5433 -f scripts/sql/0032_db_layer_consolidation.sql
-- Apply to prod: psql -h <PROD_DB_HOST> -U qafiyah -d qafiyah -f scripts/sql/0032_db_layer_consolidation.sql

BEGIN;

-- ── Task 1: FK indexes ────────────────────────────────────────────────────────
-- The stats views (theme_stats, rhyme_stats, collection_stats, era_stats,
-- poet_stats) GROUP BY via JOINs on these columns. Without indexes, every
-- request does a full seq scan on the poems table.

CREATE INDEX IF NOT EXISTS idx_poems_theme_id
  ON public.poems(theme_id);

CREATE INDEX IF NOT EXISTS idx_poems_rhyme_id
  ON public.poems(rhyme_id)
  WHERE rhyme_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_poems_collection_id
  ON public.poems(collection_id)
  WHERE collection_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_poets_era_id
  ON public.poets(era_id);

COMMIT;

BEGIN;

-- ── Task 2: is_formal column on meters ───────────────────────────────────────
-- The 16 classical (Khalilian) Arabic meters are now classified in the DB.
-- The app no longer needs the hardcoded FORMAL_METERS constant.

ALTER TABLE public.meters
  ADD COLUMN IF NOT EXISTS is_formal boolean NOT NULL DEFAULT false;

UPDATE public.meters
SET is_formal = true
WHERE name IN (
  'الطويل', 'المديد', 'البسيط', 'الوافر', 'الكامل',
  'الهزج', 'الرجز', 'الرمل', 'السريع', 'المنسرح',
  'الخفيف', 'المضارع', 'المقتضب', 'المجتث', 'المتقارب', 'المتدارك'
);

-- Recreate meter_stats to expose is_formal. ORDER BY replaces app-level localeCompare.
-- Must DROP + CREATE (not CREATE OR REPLACE) because column order changes.
DROP VIEW IF EXISTS public.meter_stats;
CREATE VIEW public.meter_stats WITH (security_invoker = 'on') AS
  SELECT
    m.id,
    m.name,
    m.slug,
    m.is_formal,
    count(DISTINCT p.id)       AS poems_count,
    count(DISTINCT p.poet_id)  AS poets_count
  FROM public.meters m
  LEFT JOIN public.poems p ON m.id = p.meter_id
  GROUP BY m.id, m.name, m.slug, m.is_formal
  ORDER BY m.name COLLATE "C";

COMMIT;

BEGIN;

-- ── Task 3: Content normalization ─────────────────────────────────────────────
-- Double-quote characters (") in poem content and poet names are an artifact of
-- the original data source. Strip them at rest so application code never needs
-- to strip them at read time.

UPDATE public.poems
  SET content = replace(content, '"', '')
  WHERE content LIKE '%"%';

UPDATE public.poets
  SET name = replace(name, '"', '')
  WHERE name LIKE '%"%';

COMMIT;

BEGIN;

-- ── Task 4: verse_count as generated column ───────────────────────────────────
-- verse_count is fully deterministic from content (number of *-separated lines,
-- paired into hemistichs, truncated). GENERATED ALWAYS AS prevents drift if
-- content is ever updated without recomputing verse_count manually.
-- Note: floor (not ceil) is correct — odd part counts mean a trailing unpaired
-- hemistich that does not count as a full verse.
-- poem_full_data must be dropped and recreated because it references verse_count.

DROP VIEW IF EXISTS public.poem_full_data;

ALTER TABLE public.poems DROP COLUMN verse_count;

ALTER TABLE public.poems
  ADD COLUMN verse_count integer
    GENERATED ALWAYS AS (
      floor(array_length(string_to_array(content, '*'), 1)::decimal / 2)::integer
    ) STORED NOT NULL;

CREATE VIEW public.poem_full_data WITH (security_invoker = 'on') AS
  SELECT
    p.slug,
    p.title,
    p.content,
    p.verse_count,
    po.name  AS poet_name,
    po.slug  AS poet_slug,
    m.name   AS meter_name,
    t.name   AS theme_name,
    e.name   AS era_name,
    e.slug   AS era_slug,
    c.name   AS collection_name,
    c.slug   AS collection_slug
  FROM public.poems p
  JOIN public.poets      po ON p.poet_id       = po.id
  JOIN public.meters     m  ON p.meter_id      = m.id
  JOIN public.themes     t  ON p.theme_id      = t.id
  JOIN public.eras       e  ON po.era_id       = e.id
  LEFT JOIN public.collections c ON p.collection_id = c.id;

COMMIT;

BEGIN;

-- ── Task 5: bot_eligible on eras ─────────────────────────────────────────────
-- The random-poem function previously excluded era_id IN (3, 9) which are
-- deleted eras. This column makes eligibility legible and configurable without
-- touching SQL.

ALTER TABLE public.eras
  ADD COLUMN IF NOT EXISTS bot_eligible boolean NOT NULL DEFAULT true;

-- Era IDs 3 and 9 no longer exist (were deleted), so all current eras are
-- eligible. Set bot_eligible = false on specific eras to exclude them.

CREATE OR REPLACE FUNCTION public.get_random_eligible_poem() RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
AS $$
DECLARE
  result JSON;
BEGIN
  WITH random_poet AS (
    SELECT po.id
    FROM public.poets po
    JOIN public.eras e ON e.id = po.era_id
    WHERE e.bot_eligible = true
    ORDER BY random()
    LIMIT 1
  ),
  random_poem AS (
    SELECT p.id
    FROM public.poems p
    JOIN random_poet rp ON p.poet_id = rp.id
    ORDER BY random()
    LIMIT 1
  )
  SELECT json_build_object(
    'poem_id',   p.id,
    'poet_name', pt.name,
    'content',   p.content,
    'slug',      p.slug
  )
  INTO result
  FROM public.poems p
  JOIN public.poets pt ON pt.id = p.poet_id
  WHERE p.id = (SELECT id FROM random_poem);

  IF result IS NULL THEN
    RETURN json_build_object('error', 'No eligible poem found');
  END IF;

  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('error', 'An error occurred: ' || SQLERRM);
END;
$$;

COMMIT;

BEGIN;

-- ── Task 6: extract_rhyme_letter PL/pgSQL function + trigger ──────────────────
-- Ports packages/db/src/extract-rhymes.ts to PL/pgSQL so rhyme_id is
-- auto-assigned on INSERT and content UPDATE without a separate backfill step.

CREATE OR REPLACE FUNCTION public.extract_rhyme_letter(p_content text)
  RETURNS text
  LANGUAGE plpgsql
  IMMUTABLE
AS $$
DECLARE
  rhyme_letters  text[] := ARRAY[
    'ا','أ','إ','آ','ى','ء','ؤ','ئ','ة',
    'ب','ت','ث','ج','ح','خ','د','ذ','ر','ز',
    'س','ش','ص','ض','ط','ظ','ع','غ','ف','ق',
    'ك','ل','م','ن','ه','و','ي'
  ];
  lines          text[];
  ajuz           text[];
  finals         text[];
  seen           text[] := '{}';
  i              int;
  line           text;
  last_char      text;
  c              text;
  n_lines        int;
BEGIN
  -- NOTE: string_to_array on empty string returns {''}, array_length returns 1.
  -- Guard with n_lines to avoid a null upper-bound in the FOR loop when content
  -- is truly NULL (though the column is NOT NULL, defensive is safer here).
  lines := string_to_array(p_content, '*');
  n_lines := array_length(lines, 1);

  IF n_lines IS NULL OR n_lines = 0 THEN
    RETURN NULL;
  END IF;

  FOR i IN 1..n_lines LOOP
    IF i % 2 = 0 THEN
      ajuz := array_append(ajuz, trim(lines[i]));
    END IF;
  END LOOP;

  IF ajuz IS NULL OR array_length(ajuz, 1) = 0 THEN
    RETURN NULL;
  END IF;

  FOREACH line IN ARRAY ajuz LOOP
    last_char := right(line, 1);
    IF last_char = ANY(rhyme_letters) THEN
      finals := array_append(finals, last_char);
    END IF;
  END LOOP;

  IF finals IS NULL OR array_length(finals, 1) = 0 THEN
    RETURN NULL;
  END IF;

  IF array_length(ajuz, 1) = 1 THEN
    RETURN finals[1];
  END IF;

  FOREACH c IN ARRAY finals LOOP
    IF c = ANY(seen) THEN
      RETURN c;
    END IF;
    seen := array_append(seen, c);
  END LOOP;

  RETURN finals[1];
END;
$$;

CREATE OR REPLACE FUNCTION public.auto_assign_rhyme_id()
  RETURNS trigger
  LANGUAGE plpgsql
AS $$
DECLARE
  v_letter   text;
  v_rhyme_id integer;
BEGIN
  v_letter := public.extract_rhyme_letter(NEW.content);
  IF v_letter IS NOT NULL THEN
    SELECT id INTO v_rhyme_id
    FROM public.rhymes
    WHERE letter = v_letter
    LIMIT 1;
  END IF;
  NEW.rhyme_id := v_rhyme_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_assign_rhyme ON public.poems;
CREATE TRIGGER trg_auto_assign_rhyme
  BEFORE INSERT OR UPDATE OF content
  ON public.poems
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_assign_rhyme_id();

COMMIT;
