-- scripts/sql/0037_rename_db_functions.sql
-- Rename DB functions to communicate intent at the call site.
--
--   auto_assign_poem_slug()         → poems_fill_slug()
--   auto_assign_rhyme_id()          → poems_derive_rhyme_id()
--   extract_rhyme_letter(p_content) → extract_rhyme_letter(content)   (param rename only)
--   generate_slug(mode, input)      → split into slugify(input) + random_poem_slug()
--   get_random_eligible_poem()      → random_poem_json()
--
-- Triggers:
--   trg_auto_assign_poem_slug → poems_fill_slug
--   trg_auto_assign_rhyme     → poems_derive_rhyme_id
--
-- Apply to dev:  psql -U qafiyah -d qafiyah -h 127.0.0.1 -p 5433 -f scripts/sql/0037_rename_db_functions.sql
-- Apply to prod: psql -h <PROD_DB_HOST> -U qafiyah -d qafiyah -f scripts/sql/0037_rename_db_functions.sql

BEGIN;

-- ── Drop triggers that depend on the functions we're replacing ──────────────

DROP TRIGGER IF EXISTS trg_auto_assign_poem_slug ON public.poems;
DROP TRIGGER IF EXISTS trg_auto_assign_rhyme     ON public.poems;

-- ── Drop old functions ──────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.auto_assign_poem_slug();
DROP FUNCTION IF EXISTS public.auto_assign_rhyme_id();
DROP FUNCTION IF EXISTS public.generate_slug(text, text);
DROP FUNCTION IF EXISTS public.get_random_eligible_poem();
DROP FUNCTION IF EXISTS public.extract_rhyme_letter(text);

-- ── extract_rhyme_letter: same body, parameter renamed p_content → content ──

CREATE FUNCTION public.extract_rhyme_letter(content text) RETURNS text
  LANGUAGE plpgsql IMMUTABLE
  SET search_path TO ''
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
  lines := string_to_array(content, '*');
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

-- ── slugify: transliterated Latin → kebab-case (was generate_slug('transliterate', _)) ──

CREATE FUNCTION public.slugify(input text) RETURNS text
  LANGUAGE plpgsql IMMUTABLE
  SET search_path TO ''
AS $$
DECLARE
  result text;
BEGIN
  IF input IS NULL OR length(btrim(input)) = 0 THEN
    RAISE EXCEPTION 'slugify: input is required';
  END IF;
  result := lower(input);
  result := regexp_replace(result, '[^a-z]+', ' ', 'g');
  result := btrim(result);
  result := regexp_replace(result, '(^| )al +', '\1al', 'g');
  result := regexp_replace(result, ' +', '-', 'g');
  result := btrim(result, '-');
  IF length(result) = 0 THEN
    RAISE EXCEPTION 'slugify: produced empty slug from "%"', input;
  END IF;
  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.slugify(text) IS
  'Normalizes a Latin input into a slug ([a-z-]+, article "al" joined to the next word).';

-- ── random_poem_slug: 4-char [a-zA-Z] (was generate_slug('poem')) ──────────

CREATE FUNCTION public.random_poem_slug() RETURNS text
  LANGUAGE plpgsql VOLATILE
  SET search_path TO ''
AS $$
DECLARE
  result text := '';
  chars  constant text := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  i      int;
BEGIN
  FOR i IN 1..4 LOOP
    result := result || substr(chars, 1 + floor(random() * 52)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.random_poem_slug() IS
  'Returns a random 4-char [a-zA-Z] string; callers must handle collision.';

-- ── poems_fill_slug: trigger fn, no-op when slug supplied ──────────────────

CREATE FUNCTION public.poems_fill_slug() RETURNS trigger
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
    v_candidate := public.random_poem_slug();
    IF NOT EXISTS (SELECT 1 FROM public.poems WHERE slug = v_candidate) THEN
      NEW.slug := v_candidate;
      RETURN NEW;
    END IF;
  END LOOP;

  RAISE EXCEPTION
    'poems_fill_slug: could not find a free slug after % attempts', v_max;
END;
$$;

-- ── poems_derive_rhyme_id: trigger fn, derives rhyme_id from NEW.content ───

CREATE FUNCTION public.poems_derive_rhyme_id() RETURNS trigger
  LANGUAGE plpgsql
  SET search_path TO ''
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

-- ── random_poem_json: was get_random_eligible_poem ────────────────────────

CREATE FUNCTION public.random_poem_json() RETURNS json
  LANGUAGE sql SECURITY DEFINER
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

COMMENT ON FUNCTION public.random_poem_json() IS
  'Returns a uniformly-random poem payload (poet-weighted by row count): '
  'first picks a random poet, then a random poem by that poet, returning '
  '{poem_id, poet_name, content, slug} as JSON.';

-- ── Re-create triggers pointing at renamed functions ───────────────────────

CREATE TRIGGER poems_fill_slug
  BEFORE INSERT ON public.poems
  FOR EACH ROW
  EXECUTE FUNCTION public.poems_fill_slug();

CREATE TRIGGER poems_derive_rhyme_id
  BEFORE INSERT OR UPDATE OF content ON public.poems
  FOR EACH ROW
  EXECUTE FUNCTION public.poems_derive_rhyme_id();

COMMIT;
