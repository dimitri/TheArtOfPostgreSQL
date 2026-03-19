select nspname, typname
    from      pg_type t TABLESAMPLE bernoulli(20)
         join pg_namespace n
           on n.oid = t.typnamespace
   where nspname = 'pg_catalog'
     and typname !~ '(^_|^pg_|^reg|_handler$)'
order by nspname, typname;
