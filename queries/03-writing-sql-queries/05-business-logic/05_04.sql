select *
  from get_all_albums(
         (select artistid
            from artist
           where name = 'Red Hot Chili Peppers')
       );
