create table sandbox.article
 (
   id         bigserial primary key,
   category   integer references sandbox.category(id),
   pubdate    timestamptz,
   title      text not null,
   content    text
 );
