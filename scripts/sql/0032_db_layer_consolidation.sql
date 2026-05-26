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
