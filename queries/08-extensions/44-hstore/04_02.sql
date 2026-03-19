select (before -> 'constituentid')::integer as id,
       after - before as diff
  from moma.audit
  limit 15;
