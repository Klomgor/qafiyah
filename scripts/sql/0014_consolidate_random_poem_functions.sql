-- Consolidate 6 random-poem SQL functions into one.
-- The old design used 4 helpers (get_random_eligible_poet, get_random_poem_by_poet,
-- get_poem_details, get_poem_slug) called by 2 near-identical orchestrators. This
-- replaces all 6 with a single function that returns poem_id, poet_name, content,
-- and slug in one CTE.
--
-- Poet-first sampling is preserved: a random eligible poet is chosen first so that
-- poets with many poems don't dominate the distribution.

DROP FUNCTION IF EXISTS public.get_random_eligible_poem_slug();
DROP FUNCTION IF EXISTS public.get_poem_details(integer);
DROP FUNCTION IF EXISTS public.get_poem_slug(integer);
DROP FUNCTION IF EXISTS public.get_random_poem_by_poet(integer);
DROP FUNCTION IF EXISTS public.get_random_eligible_poet();

CREATE OR REPLACE FUNCTION public.get_random_eligible_poem() RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    result JSON;
BEGIN
    WITH random_poet AS (
        SELECT id
        FROM public.poets
        WHERE era_id NOT IN (3, 9)
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
