create table sandboxpk.article
 (
   id         bigserial primary key,
   category   integer      not null references sandbox.category(id),
   pubdate    timestamptz  not null,
   title      text         not null,
   content    text,
   
   unique(category, pubdate, title)
 );
