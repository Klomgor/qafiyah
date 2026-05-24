-- scripts/sql/0007_normalize_titles.sql
-- One-shot data migration applied to the 0018 dump to produce the 0019 baseline.
-- Normalizes the 9 poem titles that contain characters outside [ء-ي ] (basic
-- Arabic letter block + ASCII space).
--
-- Offending characters by row (verified against the 0018 dump):
--   10171  U+060C arabic comma + double-space
--   10439  U+0028/U+0029 parentheses wrapping a parenthetical
--   35436  U+FEFB arabic ligature lam-with-alef (presentation form)
--   65670  U+060C arabic comma
--   76501  U+0021 leading exclamation mark
--   76744  U+060C arabic comma
--   78918  U+060C arabic comma (with surrounding spaces)
--   78923  U+060C arabic comma (with surrounding spaces)
--   78924  U+060C arabic comma × 2 (with surrounding spaces)
--
-- After this migration, every poems.title matches ^[ء-ي ]+$ with no leading,
-- trailing, or repeated spaces.
--
-- NOT idempotent: re-running on already-migrated data raises an exception via
-- the pre-flight guard below.
BEGIN;

DO $$
DECLARE
  v_expected_ids integer[] := ARRAY[10171, 10439, 35436, 65670, 76501,
                                    76744, 78918, 78923, 78924];
  v_pre_bad_count   integer;
  v_pre_match_ids   integer;
  v_pre_poems_total integer;
  v_post_poems_total integer;
  v_post_bad_count  integer;
BEGIN
  -- Pre-flight: the regex must match exactly those 9 ids, no more, no less.
  SELECT count(*) INTO v_pre_bad_count
  FROM poems WHERE title ~ '[^ء-ي ]';
  IF v_pre_bad_count <> 9 THEN
    RAISE EXCEPTION
      'pre-flight failed: expected 9 titles with non-Arabic chars, found %',
      v_pre_bad_count;
  END IF;

  SELECT count(*) INTO v_pre_match_ids
  FROM poems
  WHERE title ~ '[^ء-ي ]'
    AND id = ANY(v_expected_ids);
  IF v_pre_match_ids <> 9 THEN
    RAISE EXCEPTION
      'pre-flight failed: the 9 offending ids do not match the expected set (matched %)',
      v_pre_match_ids;
  END IF;

  SELECT count(*) INTO v_pre_poems_total FROM poems;

  -- Apply the cleaned titles. Keyed by id so a stray character anywhere else
  -- in the dataset would not be silently rewritten.
  WITH fixes(id, title) AS (VALUES
    (10171, 'ورد العفاة المعطشون وأصدروا'),
    (10439, 'أصالة الرأي صانتني لامية العجم'),
    (35436, 'حب الرياسة داء لا دواء له'),
    (65670, 'جزى الله رب الناس خير جزائه'),
    (76501, 'ذا اقتسم الناس فضل الفخار'),
    (76744, 'عزمه عزم عظيم رأيه رأي متين'),
    (78918, 'قد أوعدتنا معد وهي كاذبة'),
    (78923, 'يا دار أسماء بالعلياء من إضم'),
    (78924, 'لنا خباء وراووق ومسمعة')
  )
  UPDATE poems p
  SET title = f.title
  FROM fixes f
  WHERE p.id = f.id;

  -- Post-flight: no row should match the bad-char regex anymore.
  SELECT count(*) INTO v_post_bad_count
  FROM poems WHERE title ~ '[^ء-ي ]';
  IF v_post_bad_count <> 0 THEN
    RAISE EXCEPTION
      'post-flight failed: % title(s) still contain non-Arabic chars',
      v_post_bad_count;
  END IF;

  -- Post-flight: no leading/trailing/repeated spaces in the rewritten titles.
  IF EXISTS (
    SELECT 1 FROM poems
    WHERE id = ANY(v_expected_ids)
      AND (title ~ '^ | $|  ')
  ) THEN
    RAISE EXCEPTION 'post-flight failed: a rewritten title has stray whitespace';
  END IF;

  -- Post-flight: poem count preserved.
  SELECT count(*) INTO v_post_poems_total FROM poems;
  IF v_post_poems_total <> v_pre_poems_total THEN
    RAISE EXCEPTION 'post-flight failed: poem count changed (% -> %)',
      v_pre_poems_total, v_post_poems_total;
  END IF;
END $$;

COMMIT;
