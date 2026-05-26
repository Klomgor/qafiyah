-- scripts/sql/0036_auto_generate_poem_slug.sql
-- Auto-generate poem slugs when callers leave the column NULL or empty.
--   * Restores public.generate_slug(mode, input) that 0035 dropped — the
--     "poem" mode (random 4-char [a-zA-Z]) is needed by the new trigger.
--     Adds `SET search_path = ''` hardening that 0035 brought to the other
--     PL/pgSQL functions.
--   * Adds public.auto_assign_poem_slug() trigger function. No-op when the
--     caller supplies a non-empty slug; otherwise loops up to 10 times
--     calling generate_slug('poem') and SELECT-checking for collision before
--     assigning NEW.slug. With ~79k rows in 52^4 = 7.3M space, per-attempt
--     collision probability is ~1%; ten in a row is ~1e-20, so the RAISE
--     is a real-bug fence, not an expected path.
--   * Adds trg_auto_assign_poem_slug BEFORE INSERT trigger on public.poems.
--     UPDATE-of-slug paths stay explicit (dump restores, fixtures, manual
--     operator edits keep working unchanged).
-- Apply to dev:  psql -U qafiyah -d qafiyah -h 127.0.0.1 -p 5433 -f scripts/sql/0036_auto_generate_poem_slug.sql
-- Apply to prod: psql -h <PROD_DB_HOST> -U qafiyah -d qafiyah -f scripts/sql/0036_auto_generate_poem_slug.sql

BEGIN;

-- ── Restore generate_slug ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_slug(mode text, input text DEFAULT NULL)
  RETURNS text
  LANGUAGE plpgsql
  SET search_path TO ''
AS $$
DECLARE
  result text;
  chars  constant text := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  i      int;
BEGIN
  IF mode = 'transliterate' THEN
    IF input IS NULL OR length(btrim(input)) = 0 THEN
      RAISE EXCEPTION 'generate_slug(transliterate): input is required';
    END IF;
    result := lower(input);
    result := regexp_replace(result, '[^a-z]+', ' ', 'g');
    result := btrim(result);
    result := regexp_replace(result, '(^| )al +', '\1al', 'g');
    result := regexp_replace(result, ' +', '-', 'g');
    result := btrim(result, '-');
    IF length(result) = 0 THEN
      RAISE EXCEPTION 'generate_slug(transliterate): produced empty slug from "%"', input;
    END IF;
    RETURN result;

  ELSIF mode = 'poem' THEN
    result := '';
    FOR i IN 1..4 LOOP
      result := result || substr(chars, 1 + floor(random() * 52)::int, 1);
    END LOOP;
    RETURN result;

  ELSE
    RAISE EXCEPTION 'generate_slug: unknown mode "%"', mode;
  END IF;
END
$$;

COMMENT ON FUNCTION public.generate_slug(text, text) IS
  'Mode "transliterate" normalizes a Latin input into a slug ([a-z-]+, '
  'article "al" joined to the next word). Mode "poem" returns a random '
  '4-char [a-zA-Z] string; callers must handle collision.';

-- ── Trigger function: fill NULL/empty slug with a unique random 4-char ───────

CREATE OR REPLACE FUNCTION public.auto_assign_poem_slug()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
AS $$
DECLARE
  v_candidate text;
  v_attempt   int;
  v_max       constant int := 10;
BEGIN
  IF NEW.slug IS NOT NULL AND length(btrim(NEW.slug)) > 0 THEN
    RETURN NEW;
  END IF;

  FOR v_attempt IN 1..v_max LOOP
    v_candidate := public.generate_slug('poem');
    IF NOT EXISTS (SELECT 1 FROM public.poems WHERE slug = v_candidate) THEN
      NEW.slug := v_candidate;
      RETURN NEW;
    END IF;
  END LOOP;

  RAISE EXCEPTION
    'auto_assign_poem_slug: could not find a free slug after % attempts', v_max;
END;
$$;

-- ── Trigger: BEFORE INSERT only ──────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_auto_assign_poem_slug ON public.poems;
CREATE TRIGGER trg_auto_assign_poem_slug
  BEFORE INSERT ON public.poems
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_assign_poem_slug();

COMMIT;
