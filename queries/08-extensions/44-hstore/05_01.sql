select audit.change_date::date,
       artist.name as "current name", 
       before.name as "previous name"

  from      moma.artist
      join moma.audit
        on (audit.before->'constituentid')::integer
         = artist.constituentid,
      populate_record(NULL::moma.artist, before) as before

where artist.name <> before.name;
