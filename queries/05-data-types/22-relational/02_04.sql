select amopopr::regoperator
    from pg_opclass c
         join pg_am am on am.oid = c.opcmethod
         join pg_amop amop on amop.amopfamily = c.opcfamily
   where opcintype = 'ip4r'::regtype
     and am.amname = 'gist';
