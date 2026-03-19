create table sandbox.article
 (
   category   integer references sandbox.category(id),
   pubdate    timestamptz,
   title      text not null,
   content    text,
   
   primary key(category, title);
 );
