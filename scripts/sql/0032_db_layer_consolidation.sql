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
