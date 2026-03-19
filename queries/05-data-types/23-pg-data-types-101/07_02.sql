select uuid_generate_v4()
  from generate_series(1, 10) as t(x);
