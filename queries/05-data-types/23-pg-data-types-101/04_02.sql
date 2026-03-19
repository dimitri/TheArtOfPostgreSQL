  select oprname,
         oprcode::regproc,
         oprleft::regtype,
         oprright::regtype,
         oprresult::regtype
    from pg_operator
   where oprname = '='
     and oprleft::regtype = 'bigint'::regtype;
