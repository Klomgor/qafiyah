-- scripts/sql/0009_unified_slug_generation.sql
-- Unified slug generation across every slug column in the schema.
--
--   1. Install a single `public.generate_slug(mode, input)` function with two
--      modes:
--        * 'transliterate' — normalize an already-Latin string: lowercase,
--          join the article "al" to the next word (al madid → almadid),
--          strip non-letters, hyphenate.
--        * 'poem' — return a random 4-character [a-zA-Z] string
--          (52^4 = 7,311,616 combinations). Retry-on-conflict is the
--          caller's responsibility; this migration includes a bounded
--          retry loop for the initial bulk seed.
--   2. Drop all views that depend on a slug column.
--   3. Convert UUID slugs (themes, collections, poems) to text and
--      re-seed every row:
--        * themes/collections: curated Arabic→Latin mappings.
--        * poems: random via generate_slug('poem'), with collision-resolve
--          loop (max 50 iterations).
--   4. Re-normalize existing text slugs (eras, meters, rhymes, poets)
--      through generate_slug('transliterate', slug). For poets, the
--      `2`-suffix disambiguator that exists in the source data is stripped
--      by the no-digits rule, so the migration appends a letter suffix
--      ('-b', '-c', …) to remaining duplicates.
--   5. Re-create the views with the exact same DDL as before (slug column
--      types auto-derive from the underlying tables).
--   6. Re-add UNIQUE constraints / UNIQUE indexes and assert NOT NULL.
--
-- NOT idempotent: re-running on already-migrated data raises an exception
-- via the pre-flight guards.

BEGIN;

-- =====================================================================
-- Pre-flight: not already migrated.
-- =====================================================================
DO $pre$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'generate_slug'
  ) THEN
    RAISE EXCEPTION 'pre-flight failed: public.generate_slug already exists (already migrated?)';
  END IF;

  -- Themes/collections must match the curated set (otherwise CASE returns
  -- NULL below and the migration would lose data silently).
  IF EXISTS (
    SELECT name FROM public.themes
    WHERE name NOT IN (
      'المديح', 'الحماسة', 'الهجاء', 'الرثاء', 'النسيب',
      'العتاب', 'الحكمة', 'الزهد', 'المتفرقات'
    )
  ) THEN
    RAISE EXCEPTION 'pre-flight failed: themes table has names outside the curated mapping';
  END IF;

  IF EXISTS (
    SELECT name FROM public.collections WHERE name NOT IN ('المعلقات')
  ) THEN
    RAISE EXCEPTION 'pre-flight failed: collections table has names outside the curated mapping';
  END IF;
END
$pre$;

-- =====================================================================
-- (1) Install the unified slug-generation function.
-- =====================================================================
CREATE FUNCTION public.generate_slug(mode text, input text DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
VOLATILE  -- 'poem' mode calls random(); whole function is volatile.
AS $fn$
DECLARE
  result text;
  chars  constant text := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  i      int;
BEGIN
  IF mode = 'transliterate' THEN
    IF input IS NULL OR length(btrim(input)) = 0 THEN
      RAISE EXCEPTION 'generate_slug(transliterate): input is required';
    END IF;
    -- 1. Lowercase.
    result := lower(input);
    -- 2. Fold any non-[a-z] run to a single space. Digits and other
    --    punctuation are dropped — slug alphabet is [a-z-] only.
    result := regexp_replace(result, '[^a-z]+', ' ', 'g');
    result := btrim(result);
    -- 3. Join the article "al" to the following word. Word boundary =
    --    start-of-string OR a single space.
    result := regexp_replace(result, '(^| )al +', '\1al', 'g');
    -- 4. Spaces → hyphens.
    result := regexp_replace(result, ' +', '-', 'g');
    -- 5. Defensive trim.
    result := btrim(result, '-');
    IF length(result) = 0 THEN
      RAISE EXCEPTION 'generate_slug(transliterate): produced empty slug from "%"', input;
    END IF;
    RETURN result;

  ELSIF mode = 'poem' THEN
    -- Random 4-char [a-zA-Z]. The caller must retry on unique_violation
    -- (see the bulk-seed loop below for the canonical pattern).
    result := '';
    FOR i IN 1..4 LOOP
      result := result || substr(chars, 1 + floor(random() * 52)::int, 1);
    END LOOP;
    RETURN result;

  ELSE
    RAISE EXCEPTION 'generate_slug: unknown mode "%"', mode;
  END IF;
END
$fn$;

COMMENT ON FUNCTION public.generate_slug(text, text) IS
'Mode "transliterate" normalizes a Latin input string into a slug
([a-z-]+, article "al" joined to the next word). Mode "poem" returns
a random 4-char [a-zA-Z] string; the caller must retry on
unique_violation.';

-- =====================================================================
-- (2) Drop all views that depend on a slug column.
-- =====================================================================
DROP VIEW IF EXISTS public.poem_full_data;
DROP VIEW IF EXISTS public.collection_stats;
DROP VIEW IF EXISTS public.era_stats;
DROP VIEW IF EXISTS public.meter_stats;
DROP VIEW IF EXISTS public.poet_stats;
DROP VIEW IF EXISTS public.rhyme_stats;
DROP VIEW IF EXISTS public.theme_stats;

-- =====================================================================
-- (3) themes: uuid → text via curated mapping.
-- =====================================================================
ALTER TABLE public.themes DROP CONSTRAINT themes_slug_key;
ALTER TABLE public.themes
  ALTER COLUMN slug TYPE text USING (
    CASE name
      WHEN 'المديح'    THEN public.generate_slug('transliterate', 'almadih')
      WHEN 'الحماسة'   THEN public.generate_slug('transliterate', 'alhamasa')
      WHEN 'الهجاء'    THEN public.generate_slug('transliterate', 'alhija')
      WHEN 'الرثاء'    THEN public.generate_slug('transliterate', 'alritha')
      WHEN 'النسيب'    THEN public.generate_slug('transliterate', 'alnasib')
      WHEN 'العتاب'    THEN public.generate_slug('transliterate', 'alitab')
      WHEN 'الحكمة'    THEN public.generate_slug('transliterate', 'alhikma')
      WHEN 'الزهد'     THEN public.generate_slug('transliterate', 'alzuhd')
      WHEN 'المتفرقات' THEN public.generate_slug('transliterate', 'almutafarriqat')
      ELSE NULL
    END
  );
DO $themes_post$
BEGIN
  IF EXISTS (SELECT 1 FROM public.themes WHERE slug IS NULL) THEN
    RAISE EXCEPTION 'themes: unmapped name produced NULL slug';
  END IF;
END
$themes_post$;
ALTER TABLE public.themes ALTER COLUMN slug SET NOT NULL;
ALTER TABLE public.themes ADD CONSTRAINT themes_slug_key UNIQUE (slug);

-- =====================================================================
-- (4) collections: uuid → text via curated mapping.
-- =====================================================================
ALTER TABLE public.collections DROP CONSTRAINT collections_slug_key;
ALTER TABLE public.collections
  ALTER COLUMN slug TYPE text USING (
    CASE name
      WHEN 'المعلقات' THEN public.generate_slug('transliterate', 'almuallaqat')
      ELSE NULL
    END
  );
DO $collections_post$
BEGIN
  IF EXISTS (SELECT 1 FROM public.collections WHERE slug IS NULL) THEN
    RAISE EXCEPTION 'collections: unmapped name produced NULL slug';
  END IF;
END
$collections_post$;
ALTER TABLE public.collections ALTER COLUMN slug SET NOT NULL;
ALTER TABLE public.collections ADD CONSTRAINT collections_slug_key UNIQUE (slug);

-- =====================================================================
-- (5) poems: uuid → text random 4-char with collision-resolve loop.
-- =====================================================================
DROP INDEX public.idx_poems_slug;
-- ALTER COLUMN ... USING calls generate_slug('poem') once per row, so
-- collisions are statistically expected (~438 dupes for 80k rows in
-- a 7.3M-key space). The loop below regenerates only the dupes.
ALTER TABLE public.poems
  ALTER COLUMN slug TYPE text USING public.generate_slug('poem');
DO $poems_dedupe$
DECLARE
  dupe_count int;
  iter       int := 0;
BEGIN
  LOOP
    WITH dupes AS (
      SELECT id
      FROM (
        SELECT id, row_number() OVER (PARTITION BY slug ORDER BY id) AS rn
        FROM public.poems
      ) sub
      WHERE rn > 1
    )
    UPDATE public.poems p
       SET slug = public.generate_slug('poem')
     WHERE p.id IN (SELECT id FROM dupes);
    GET DIAGNOSTICS dupe_count = ROW_COUNT;
    EXIT WHEN dupe_count = 0;
    iter := iter + 1;
    IF iter > 50 THEN
      RAISE EXCEPTION 'poems: collision resolution exceeded 50 iterations';
    END IF;
  END LOOP;
END
$poems_dedupe$;
ALTER TABLE public.poems ALTER COLUMN slug SET NOT NULL;
CREATE UNIQUE INDEX idx_poems_slug ON public.poems (slug);

-- =====================================================================
-- (6) eras: re-normalize existing text slugs.
-- =====================================================================
ALTER TABLE public.eras DROP CONSTRAINT eras_slug_key;
UPDATE public.eras SET slug = public.generate_slug('transliterate', slug);
ALTER TABLE public.eras ADD CONSTRAINT eras_slug_key UNIQUE (slug);

-- =====================================================================
-- (7) meters: re-normalize existing text slugs.
-- =====================================================================
ALTER TABLE public.meters DROP CONSTRAINT meters_slug_key;
UPDATE public.meters SET slug = public.generate_slug('transliterate', slug);
ALTER TABLE public.meters ADD CONSTRAINT meters_slug_key UNIQUE (slug);

-- =====================================================================
-- (8) rhymes: re-normalize existing text slugs.
-- =====================================================================
ALTER TABLE public.rhymes DROP CONSTRAINT rhymes_slug_key;
UPDATE public.rhymes SET slug = public.generate_slug('transliterate', slug);
ALTER TABLE public.rhymes ADD CONSTRAINT rhymes_slug_key UNIQUE (slug);

-- =====================================================================
-- (9) poets: re-normalize + letter-suffix disambiguation for dupes.
--
-- A poet pair (`abu-al-najm-al-ajli`, `abu-al-najm-al-ajli2`) collapses
-- to the same normalized form because the `2` disambiguator is stripped
-- by the no-digits rule. The CTE below appends '-b', '-c', … to the
-- 2nd, 3rd, … row of each duplicate group (1st row keeps the bare slug).
-- 25-suffix cap (b..z); above that the assertion below trips.
-- =====================================================================
DROP INDEX public.idx_poets_slug;
UPDATE public.poets SET slug = public.generate_slug('transliterate', slug);
WITH dupes AS (
  SELECT id, slug, row_number() OVER (PARTITION BY slug ORDER BY id) AS rn
    FROM public.poets
)
UPDATE public.poets p
   SET slug = p.slug || '-' || chr((96 + d.rn)::int)  -- rn=2 → '-b', 3 → '-c', …
  FROM dupes d
 WHERE p.id = d.id AND d.rn > 1;
DO $poets_post$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad FROM (
    SELECT 1 FROM public.poets GROUP BY slug HAVING count(*) > 1
  ) s;
  IF bad > 0 THEN
    RAISE EXCEPTION 'poets: % duplicate slug(s) remain after disambiguation', bad;
  END IF;
END
$poets_post$;
CREATE UNIQUE INDEX idx_poets_slug ON public.poets (slug);

-- =====================================================================
-- (10) Re-create the views (same DDL as before; types auto-derive).
-- =====================================================================
CREATE VIEW public.collection_stats WITH (security_invoker=on) AS
SELECT c.id,
       c.name,
       c.slug,
       count(DISTINCT p.id)  AS poems_count,
       count(DISTINCT pt.id) AS poets_count
  FROM public.collections c
  LEFT JOIN public.poems p  ON c.id = p.collection_id
  LEFT JOIN public.poets pt ON p.poet_id = pt.id
 GROUP BY c.id, c.name, c.slug;

CREATE VIEW public.era_stats WITH (security_invoker=on) AS
SELECT e.id,
       e.name,
       e.slug,
       COALESCE(poet_counts.count, 0::bigint) AS poets_count,
       COALESCE(poem_counts.count, 0::bigint) AS poems_count
  FROM public.eras e
  LEFT JOIN (
    SELECT poets.era_id, count(*) AS count
      FROM public.poets
     GROUP BY poets.era_id
  ) poet_counts ON e.id = poet_counts.era_id
  LEFT JOIN (
    SELECT p.era_id, count(*) AS count
      FROM public.poems pm
      JOIN public.poets p ON pm.poet_id = p.id
     GROUP BY p.era_id
  ) poem_counts ON e.id = poem_counts.era_id;

CREATE VIEW public.meter_stats WITH (security_invoker=on) AS
SELECT m.id,
       m.name,
       m.slug,
       count(DISTINCT p.id)         AS poems_count,
       count(DISTINCT p.poet_id)    AS poets_count
  FROM public.meters m
  LEFT JOIN public.poems p ON m.id = p.meter_id
 GROUP BY m.id, m.name, m.slug;

CREATE VIEW public.poet_stats WITH (security_invoker=on) AS
SELECT p.id,
       p.name,
       p.slug,
       p.era_id,
       count(pm.id) AS poems_count
  FROM public.poets p
  LEFT JOIN public.poems pm ON p.id = pm.poet_id
 GROUP BY p.id, p.name, p.slug, p.era_id
 ORDER BY p.name;

CREATE VIEW public.rhyme_stats AS
SELECT r.id,
       r.letter,
       r.slug,
       r.name,
       count(p.id)::integer              AS poems_count,
       count(DISTINCT p.poet_id)::integer AS poets_count
  FROM public.rhymes r
  LEFT JOIN public.poems p ON p.rhyme_id = r.id
 GROUP BY r.id, r.letter, r.slug, r.name;

CREATE VIEW public.theme_stats WITH (security_invoker=on) AS
SELECT t.id,
       t.name,
       t.slug,
       count(DISTINCT p.id)  AS poems_count,
       count(DISTINCT pt.id) AS poets_count
  FROM public.themes t
  LEFT JOIN public.poems p  ON t.id = p.theme_id
  LEFT JOIN public.poets pt ON p.poet_id = pt.id
 GROUP BY t.id, t.name, t.slug;

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
  JOIN public.poets po  ON p.poet_id = po.id
  JOIN public.meters m  ON p.meter_id = m.id
  JOIN public.themes t  ON p.theme_id = t.id
  JOIN public.eras e    ON po.era_id = e.id
  LEFT JOIN public.collections c ON p.collection_id = c.id;

-- =====================================================================
-- (11) Replace SQL functions that hardcoded UUID semantics for slugs.
--      Original implementations cast the input to UUID and compared
--      against the (then-UUID) poems.slug column. Now slug is text and
--      the application validates `^[a-zA-Z]{4}$` at the contract layer.
-- =====================================================================
CREATE OR REPLACE FUNCTION public.get_related_poems(p_slug text)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path TO ''
AS $rel$
DECLARE
  poem_poet_slug text;
  poem_era_slug  text;
  result         jsonb;
BEGIN
  SELECT po.slug, e.slug
    INTO poem_poet_slug, poem_era_slug
    FROM public.poems p
    JOIN public.poets po ON p.poet_id = po.id
    JOIN public.eras  e  ON po.era_id = e.id
   WHERE p.slug = p_slug;

  IF poem_poet_slug IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_agg(jsonb_build_object(
           'poet_name',  related.poet_name,
           'poem_title', related.poem_title,
           'poem_slug',  related.poem_slug,
           'meter_name', related.meter_name
         )) INTO result
    FROM (
      -- Deterministic shuffle seed derived from the input slug.
      SELECT setseed(('x' || substr(md5(p_slug), 1, 8))::bit(32)::int / 2147483647.0)
    ) AS seed
    CROSS JOIN LATERAL (
      SELECT po.name  AS poet_name,
             p.title  AS poem_title,
             p.slug   AS poem_slug,
             m.name   AS meter_name
        FROM public.poems  p
        JOIN public.poets  po ON p.poet_id  = po.id
        JOIN public.meters m  ON p.meter_id = m.id
        JOIN public.eras   e  ON po.era_id  = e.id
       WHERE p.slug <> p_slug
         AND (po.slug = poem_poet_slug OR e.slug = poem_era_slug)
       ORDER BY
         CASE
           WHEN po.slug = poem_poet_slug THEN 1
           WHEN e.slug  = poem_era_slug  THEN 2
           ELSE 3
         END,
         random()
       LIMIT 10
    ) AS related;

  RETURN COALESCE(result, '[]'::jsonb);
END;
$rel$;

CREATE OR REPLACE FUNCTION public.get_poem_with_related(p_slug text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $fn$
DECLARE
  poem_data     jsonb;
  related_poems jsonb;
BEGIN
  SELECT to_jsonb(pfd) INTO poem_data
    FROM public.poem_full_data pfd
   WHERE pfd.slug = p_slug;

  IF poem_data IS NULL THEN
    RETURN jsonb_build_object(
      'error', 'Not Found',
      'message', 'No poem found with slug: ' || p_slug
    );
  END IF;

  BEGIN
    SELECT public.get_related_poems(p_slug) INTO related_poems;
  EXCEPTION WHEN OTHERS THEN
    related_poems := '[]'::jsonb;
    RAISE WARNING 'Error getting related poems: %', SQLERRM;
  END;

  RETURN jsonb_build_object(
    'poem', poem_data,
    'related_poems', COALESCE(related_poems, '[]'::jsonb)
  );
END;
$fn$;

-- =====================================================================
-- (12) Final assertions: every slug matches the contract.
-- =====================================================================
DO $final$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad FROM public.poems  WHERE slug !~ '^[a-zA-Z]{4}$';
  IF bad > 0 THEN RAISE EXCEPTION 'poems: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.poets       WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'poets: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.eras        WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'eras: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.meters      WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'meters: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.rhymes      WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'rhymes: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.themes      WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'themes: % rows with invalid slug', bad; END IF;

  SELECT count(*) INTO bad FROM public.collections WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN RAISE EXCEPTION 'collections: % rows with invalid slug', bad; END IF;
END
$final$;

COMMIT;
