-- scripts/sql/0035_tighten_postgres_functions.sql
-- Audit-driven cleanup of public.* functions:
--   * generate_slug — dead in the live DB (only referenced by migrations
--     0009/0012, both already applied). No runtime caller, no trigger, no
--     column default. Drop it.
--   * extract_rhyme_letter — harden with `SET search_path = ''` for
--     consistency with the other two PL/pgSQL functions.
--   * get_random_eligible_poem — stop swallowing every error as a
--     success-shaped {error: …} JSON envelope. Return SQL NULL when no row
--     matches (caller already handles that as `no_eligible_poem`) and let
--     real exceptions bubble up to the caller's `query_failed` path
--     (currently they were rewritten to `invalid_payload_shape`, losing
--     fidelity). Collapse the three-step CTE into a single SQL function.
-- Apply to dev:  psql -U qafiyah -d qafiyah -h 127.0.0.1 -p 5433 -f scripts/sql/0035_tighten_postgres_functions.sql
-- Apply to prod: psql -h <PROD_DB_HOST> -U qafiyah -d qafiyah -f scripts/sql/0035_tighten_postgres_functions.sql

BEGIN;

-- ── Drop dead generate_slug ──────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.generate_slug(text, text);

-- ── Harden extract_rhyme_letter ──────────────────────────────────────────────

ALTER FUNCTION public.extract_rhyme_letter(text) SET search_path = '';

-- ── Tighten get_random_eligible_poem ─────────────────────────────────────────
-- @NOTE: poet-uniform sampling (random poet → random poem from that poet)
-- gives every poet equal airtime regardless of corpus size. Intentional for
-- the @qafiyah_bot diversity; switch to poem-uniform if that ever changes.

CREATE OR REPLACE FUNCTION public.get_random_eligible_poem() RETURNS json
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path TO ''
AS $$
  WITH rp AS (
    SELECT id FROM public.poets ORDER BY random() LIMIT 1
  ),
  pm AS (
    SELECT p.id
    FROM public.poems p
    JOIN rp ON p.poet_id = rp.id
    ORDER BY random()
    LIMIT 1
  )
  SELECT json_build_object(
    'poem_id',   p.id,
    'poet_name', pt.name,
    'content',   p.content,
    'slug',      p.slug
  )
  FROM public.poems p
  JOIN public.poets pt ON pt.id = p.poet_id
  WHERE p.id = (SELECT id FROM pm);
$$;

COMMIT;
