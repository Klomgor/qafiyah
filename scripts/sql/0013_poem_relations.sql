-- Drop the on-the-fly SQL functions replaced by the poem_relations table.
DROP FUNCTION IF EXISTS public.get_poem_with_related(text);
DROP FUNCTION IF EXISTS public.get_related_poems(text);

-- Precomputed top-5 related poems per poem, scored by shared signals.
CREATE TABLE public.poem_relations (
  poem_id    integer  NOT NULL REFERENCES public.poems(id) ON DELETE CASCADE,
  related_id integer  NOT NULL REFERENCES public.poems(id) ON DELETE CASCADE,
  score      smallint NOT NULL,
  rank       smallint NOT NULL,
  PRIMARY KEY (poem_id, rank),
  UNIQUE (poem_id, related_id)
);

CREATE INDEX ON public.poem_relations (poem_id);
