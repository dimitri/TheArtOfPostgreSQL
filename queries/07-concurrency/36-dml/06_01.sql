begin;

  explain (analyze, costs off, timing off)
   update public.foo
      set f1 = forename, f2 = surname
     from f1db.drivers
    where drivers.driverid = foo.id
      and foo.id in (1, 2, 3)
returning foo.*, drivers.code;

rollback;
