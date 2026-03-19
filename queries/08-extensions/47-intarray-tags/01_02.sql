  select tt.tid, array_agg(tags.rowid) as tags
    from      tags 
         join tid_tag tt
           on tags.rowid = tt.tag
group by tt.tid
   limit 3;
