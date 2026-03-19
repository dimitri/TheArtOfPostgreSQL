create or replace function get_all_albums
 (
   in  name     text,
   out album    text,
   out duration interval
 )
returns setof record
language plpgsql
as $$
declare
  rec record;
begin
  for rec in select albumid
               from album
                    join artist using(artistid)
              where album.name = get_all_albums.name
  loop
       select title, sum(milliseconds) * interval '1ms'
         into album, duration
         from album
              left join track using(albumid)
        where albumid = record.albumid
     group by title
     order by title;

    return next;
  end loop;
end;
$$;
