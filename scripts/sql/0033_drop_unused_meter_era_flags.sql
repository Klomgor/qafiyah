-- scripts/sql/0033_drop_unused_meter_era_flags.sql
-- Drop unused boolean flags introduced in 0032:
--   * meters.is_formal — every meter (including the "other" bucket) should
--     surface in listings; the filter was removed at the app layer.
--   * eras.bot_eligible — every row was true, so the column carried no signal.
-- Apply to dev:  psql -U qafiyah -d qafiyah -h 127.0.0.1 -p 5433 -f scripts/sql/0033_drop_unused_meter_era_flags.sql
-- Apply to prod: psql -h <PROD_DB_HOST> -U qafiyah -d qafiyah -f scripts/sql/0033_drop_unused_meter_era_flags.sql

BEGIN;

-- ── meters.is_formal ─────────────────────────────────────────────────────────
-- meter_stats must be DROPped (not REPLACEd) because the column set changes.

DROP VIEW IF EXISTS public.meter_stats;

ALTER TABLE public.meters
  DROP COLUMN IF EXISTS is_formal;

CREATE VIEW public.meter_stats WITH (security_invoker = 'on') AS
  SELECT
    m.id,
    m.name,
    m.slug,
    count(DISTINCT p.id)       AS poems_count,
    count(DISTINCT p.poet_id)  AS poets_count
  FROM public.meters m
  LEFT JOIN public.poems p ON m.id = p.meter_id
  GROUP BY m.id, m.name, m.slug;

COMMIT;

BEGIN;

-- ── eras.bot_eligible ────────────────────────────────────────────────────────
-- Restore get_random_eligible_poem to a single random poem pick, with no era
-- join. The previous WHERE e.bot_eligible = true was a no-op on every row.

CREATE OR REPLACE FUNCTION public.get_random_eligible_poem() RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
AS $$
DECLARE
  result JSON;
BEGIN
  WITH random_poet AS (
    SELECT id
    FROM public.poets
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

ALTER TABLE public.eras
  DROP COLUMN IF EXISTS bot_eligible;

COMMIT;
