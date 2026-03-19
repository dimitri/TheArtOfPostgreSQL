\pset format wrapped
\pset columns 72

  explain (analyze, verbose, buffers, costs off)
  select id, name, pos
    from pubnames
order by pos <-> point(51.516,-0.12)
   limit 3;
