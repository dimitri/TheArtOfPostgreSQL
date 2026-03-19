explain (costs off, buffers, analyze)
  select name, location, country
    from circuits
order by point(lng,lat) <-> point(2.349014, 48.864716)
   limit 10;
