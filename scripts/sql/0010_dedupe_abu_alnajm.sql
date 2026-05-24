-- scripts/sql/0010_dedupe_abu_alnajm.sql
-- Dedupes أبو النجم العجلي. The source dataset shipped two poet rows
-- (id=3415, id=3447) with the same name and era, each holding the same
-- 72 poems (identical title + identical content). Migration 0009's
-- slug normalizer disambiguated the second one with a "-b" suffix
-- (`abu-alnajm-alajli` / `abu-alnajm-alajli-b`).
--
-- This migration removes the duplicate: deletes the 72 poems on
-- poet 3447 and the poet 3447 row itself. Net change: −72 poems,
-- −1 poet. Poet 3415 retains its 72 unique poems and recovers the
-- bare `abu-alnajm-alajli` slug as the only one.
--
-- NOT idempotent: re-running raises an exception via the pre-flight.
BEGIN;

DO $pre$
DECLARE
  v_keep_id      constant int := 3415;
  v_remove_id    constant int := 3447;
  v_name         text;
  v_era_id       int;
  v_keep_count   int;
  v_remove_count int;
  v_overlap      int;
BEGIN
  SELECT name, era_id INTO v_name, v_era_id
    FROM public.poets WHERE id = v_keep_id;
  IF v_name IS NULL THEN
    RAISE EXCEPTION 'pre-flight failed: poet id=% not found', v_keep_id;
  END IF;

  PERFORM 1 FROM public.poets
   WHERE id = v_remove_id AND name = v_name AND era_id = v_era_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION
      'pre-flight failed: poet id=% does not exist with matching name/era (already deduped?)',
      v_remove_id;
  END IF;

  SELECT count(*) INTO v_keep_count   FROM public.poems WHERE poet_id = v_keep_id;
  SELECT count(*) INTO v_remove_count FROM public.poems WHERE poet_id = v_remove_id;
  IF v_keep_count <> 72 OR v_remove_count <> 72 THEN
    RAISE EXCEPTION
      'pre-flight failed: expected 72 poems each (keep=%, remove=%)',
      v_keep_count, v_remove_count;
  END IF;

  -- Confirm true duplication: every content hash on the remove side
  -- also appears on the keep side.
  SELECT count(*) INTO v_overlap FROM (
    SELECT md5(content) AS h FROM public.poems WHERE poet_id = v_keep_id
    INTERSECT
    SELECT md5(content) AS h FROM public.poems WHERE poet_id = v_remove_id
  ) s;
  IF v_overlap <> 72 THEN
    RAISE EXCEPTION
      'pre-flight failed: expected 72 overlapping content hashes, got % — refusing to delete non-duplicate rows',
      v_overlap;
  END IF;
END
$pre$;

-- Delete the 72 duplicate poems first (FK satisfaction), then the poet row.
DELETE FROM public.poems WHERE poet_id = 3447;
DELETE FROM public.poets WHERE id      = 3447;

DO $post$
DECLARE
  v_keep_count    int;
  v_remove_exists boolean;
  v_keep_slug     text;
BEGIN
  SELECT count(*) INTO v_keep_count FROM public.poems WHERE poet_id = 3415;
  IF v_keep_count <> 72 THEN
    RAISE EXCEPTION
      'post-flight failed: poet 3415 should still have 72 poems, got %',
      v_keep_count;
  END IF;

  SELECT EXISTS (SELECT 1 FROM public.poets WHERE id = 3447) INTO v_remove_exists;
  IF v_remove_exists THEN
    RAISE EXCEPTION 'post-flight failed: poet id=3447 still exists';
  END IF;

  -- Surviving poet should retain the bare slug (no `-b` sibling left).
  SELECT slug INTO v_keep_slug FROM public.poets WHERE id = 3415;
  IF v_keep_slug <> 'abu-alnajm-alajli' THEN
    RAISE EXCEPTION
      'post-flight failed: poet 3415 slug is "%", expected "abu-alnajm-alajli"',
      v_keep_slug;
  END IF;
END
$post$;

COMMIT;
