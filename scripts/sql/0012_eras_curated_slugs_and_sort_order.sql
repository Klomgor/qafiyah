-- scripts/sql/0012_eras_curated_slugs_and_sort_order.sql
--
-- 1. Replace era slugs with curated Arabic→Latin mappings (same approach as
--    themes and collections in 0009) instead of re-normalising the old Latin.
-- 2. Add sort_order column to eras, seeded with the canonical chronological
--    ordering that was previously hard-coded in packages/db/src/constants.ts.
-- 3. Rebuild era_stats to expose sort_order to the TypeScript layer.
--
-- NOT idempotent: re-running raises an exception via pre-flight guards.

BEGIN;

-- =====================================================================
-- Pre-flight: exactly these 6 eras with no extras; sort_order absent.
-- =====================================================================
DO $pre$
DECLARE
  era_count int;
BEGIN
  SELECT count(*) INTO era_count FROM public.eras;
  IF era_count <> 6 THEN
    RAISE EXCEPTION 'pre-flight failed: expected 6 eras, found %', era_count;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.eras
    WHERE name NOT IN ('جاهلي', 'إسلامي', 'أموي', 'عباسي', 'أندلسي', 'متأخر')
  ) THEN
    RAISE EXCEPTION 'pre-flight failed: eras table contains unexpected names';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'eras'
      AND column_name  = 'sort_order'
  ) THEN
    RAISE EXCEPTION 'pre-flight failed: sort_order column already exists (already migrated?)';
  END IF;
END
$pre$;

-- =====================================================================
-- (1) Re-seed era slugs via curated Arabic→Latin mappings.
-- =====================================================================
ALTER TABLE public.eras DROP CONSTRAINT eras_slug_key;

UPDATE public.eras
   SET slug = CASE name
     WHEN 'جاهلي'   THEN public.generate_slug('transliterate', 'jahili')
     WHEN 'إسلامي'  THEN public.generate_slug('transliterate', 'islami')
     WHEN 'أموي'    THEN public.generate_slug('transliterate', 'umawi')
     WHEN 'عباسي'   THEN public.generate_slug('transliterate', 'abbasi')
     WHEN 'أندلسي'  THEN public.generate_slug('transliterate', 'andalusi')
     WHEN 'متأخر'   THEN public.generate_slug('transliterate', 'mutaakhkhir')
     ELSE NULL
   END;

DO $slugs_post$
BEGIN
  IF EXISTS (SELECT 1 FROM public.eras WHERE slug IS NULL) THEN
    RAISE EXCEPTION 'eras: unmapped name produced NULL slug';
  END IF;
END
$slugs_post$;

ALTER TABLE public.eras ADD CONSTRAINT eras_slug_key UNIQUE (slug);

-- =====================================================================
-- (2) Add sort_order column and seed values.
-- =====================================================================
ALTER TABLE public.eras ADD COLUMN sort_order integer;

UPDATE public.eras
   SET sort_order = CASE name
     WHEN 'جاهلي'   THEN 1
     WHEN 'إسلامي'  THEN 2
     WHEN 'أموي'    THEN 3
     WHEN 'عباسي'   THEN 4
     WHEN 'أندلسي'  THEN 5
     WHEN 'متأخر'   THEN 6
     ELSE NULL
   END;

DO $sort_post$
BEGIN
  IF EXISTS (SELECT 1 FROM public.eras WHERE sort_order IS NULL) THEN
    RAISE EXCEPTION 'eras: unmapped name produced NULL sort_order';
  END IF;
END
$sort_post$;

ALTER TABLE public.eras ALTER COLUMN sort_order SET NOT NULL;

-- =====================================================================
-- (3) Rebuild era_stats to expose sort_order.
-- =====================================================================
DROP VIEW public.era_stats;

CREATE VIEW public.era_stats WITH (security_invoker=on) AS
SELECT e.id,
       e.name,
       e.slug,
       e.sort_order,
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

-- =====================================================================
-- (4) Final assertions.
-- =====================================================================
DO $final$
DECLARE
  bad int;
BEGIN
  SELECT count(*) INTO bad FROM public.eras WHERE slug !~ '^[a-z][a-z-]*$';
  IF bad > 0 THEN
    RAISE EXCEPTION 'eras: % rows with invalid slug after migration', bad;
  END IF;

  SELECT count(*) INTO bad FROM public.eras WHERE sort_order IS NULL;
  IF bad > 0 THEN
    RAISE EXCEPTION 'eras: % rows with NULL sort_order', bad;
  END IF;

  -- Assert exact expected slugs (catches silent mapping bugs).
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'جاهلي'  AND slug = 'jahili')       THEN RAISE EXCEPTION 'eras: جاهلي slug mismatch';   END IF;
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'إسلامي' AND slug = 'islami')       THEN RAISE EXCEPTION 'eras: إسلامي slug mismatch';  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'أموي'   AND slug = 'umawi')        THEN RAISE EXCEPTION 'eras: أموي slug mismatch';    END IF;
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'عباسي'  AND slug = 'abbasi')       THEN RAISE EXCEPTION 'eras: عباسي slug mismatch';   END IF;
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'أندلسي' AND slug = 'andalusi')     THEN RAISE EXCEPTION 'eras: أندلسي slug mismatch';  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.eras WHERE name = 'متأخر'  AND slug = 'mutaakhkhir') THEN RAISE EXCEPTION 'eras: متأخر slug mismatch';   END IF;
END
$final$;

COMMIT;
