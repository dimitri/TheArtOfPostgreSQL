create table sandboxpk.comment
 (
   a_category integer     not null,
   a_pubdate  timestamptz not null,
   a_title    text        not null,
   pubdate    timestamptz,
   content    text,
   
   primary key(a_category, a_pubdate, a_title, pubdate, content),

   foreign key(a_category, a_pubdate, a_title)
    references sandboxpk.article(category, pubdate, title)
 );
