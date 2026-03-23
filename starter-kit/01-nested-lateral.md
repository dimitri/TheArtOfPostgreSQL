# Nested LATERAL Joins: Top-N Per Group

The "Top-N per group" is a classic SQL problem. PostgreSQL's `LATERAL`
keyword makes it elegant, and you can even nest them.

## The Problem

The following query lists the most recent articles per category with the
first three comments on each article, in a classic schema where have
categories, articles, and comments as first class relations:

```
taop@taop=# \dt sandbox.*
         List of relations
 Schema  │   Name   │ Type  │ Owner 
═════════╪══════════╪═══════╪═══════
 sandbox │ article  │ table │ taop
 sandbox │ category │ table │ taop
 sandbox │ comment  │ table │ taop
 sandbox │ lorem    │ table │ taop
(4 rows)
```

## The Query

We use the following query, that you can load either from disk (or from the
docker container files) with the following psql command:

```
\i 06-data-modeling/28-repl/03_03_topn-with-comments.sql
```

Or that you could copy and paste from the content of the file reproduced
here:

```sql
\set comments 3
\set articles 1

  select category.name as category,
         article.pubdate,
         title,
         jsonb_pretty(comments) as comments
    from sandbox.category
         left join lateral
         (
            select id,
                   title,
                   article.pubdate,
                   jsonb_agg(comment) as comments
              from sandbox.article
                  left join lateral
                  (
                      select comment.pubdate,
                             substring(comment.content from 1 for 25) || '…'
                             as content
                        from sandbox.comment
                       where comment.article = article.id
                    order by comment.pubdate desc
                       limit :comments
                  )
                  as comment
                  on true
              where category = category.id
           group by article.id
           order by article.pubdate desc
              limit :articles
         )
         as article
         on true
order by category.name, article.pubdate desc;
```

## Step-by-Step

### Step 1: Basic JOIN

Start with a simple join between categories and articles and discover how
many articles we have per category in our sandbox schema, where in the book
you would see how random data has been generated to play around with data
modelisation ideas:

```sql
  select category.name, count(article.id)
    from sandbox.category
         join sandbox.article on article.category = category.id
group by category.name
order by count desc;
```

Which gives:

```
    name    │ count 
════════════╪═══════
 box office │   343
 news       │   329
 sport      │   170
 music      │   158
(4 rows)
```

### Step 2: Add LATERAL

Use LATERAL to get the top articles per category:

```sql
select category.name, article.title, 
       to_char(article.pubdate, 'YYYY-MM-DD') as pubdate
  from sandbox.category
  join lateral (
      select id, title, pubdate
        from sandbox.article
       where category = category.id
    order by pubdate desc
       limit 1
  ) as article on true;
```

And we get the following result:

```
    name    │                    title                     │  pubdate   
════════════╪══════════════════════════════════════════════╪════════════
 sport      │ Magna Ut Distinctio Aut Itaque               │ 2026-04-19
 news       │ Aliquip Eius Consectetur Quas Delectus       │ 2026-04-20
 box office │ Sit Odio Rem Aperiam Doloribus               │ 2026-04-20
 music      │ Reprehenderit Adipiscing Nihil Neque Aliquid │ 2026-04-19
(4 rows)
```

### Step 3: Add a Second LATERAL

Nest another LATERAL to get top comments per article:

```sql
select category.name, article.title,
       comment.id, to_char(comment.pubdate, 'YYYY-MM-DD') as pubdate
  from sandbox.category
  join lateral (
      select id, title, pubdate
        from sandbox.article
       where category = category.id
    order by pubdate desc
       limit 1
  ) as article on true
  join lateral (
      select id, content, pubdate
        from sandbox.comment
       where article = article.id
    order by pubdate desc
       limit 3
  ) as comment on true;
```

And now we get the following result the most recent articles per category,
and for each article, the 3 most recent comments. As we have 4 categories,
times 1 article per category, times 3 comments, we have 12 rows of output:

```
    name    │                    title                     │  id   │  pubdate   
════════════╪══════════════════════════════════════════════╪═══════╪════════════
 sport      │ Magna Ut Distinctio Aut Itaque               │ 36224 │ 2026-04-19
 sport      │ Magna Ut Distinctio Aut Itaque               │  2864 │ 2026-04-18
 sport      │ Magna Ut Distinctio Aut Itaque               │ 39873 │ 2026-04-15
 news       │ Aliquip Eius Consectetur Quas Delectus       │  4401 │ 2026-04-13
 news       │ Aliquip Eius Consectetur Quas Delectus       │ 31417 │ 2026-04-13
 news       │ Aliquip Eius Consectetur Quas Delectus       │ 26782 │ 2026-04-10
 box office │ Sit Odio Rem Aperiam Doloribus               │ 48047 │ 2026-04-19
 box office │ Sit Odio Rem Aperiam Doloribus               │ 27538 │ 2026-04-16
 box office │ Sit Odio Rem Aperiam Doloribus               │ 30499 │ 2026-04-15
 music      │ Reprehenderit Adipiscing Nihil Neque Aliquid │  7537 │ 2026-04-19
 music      │ Reprehenderit Adipiscing Nihil Neque Aliquid │ 17283 │ 2026-04-18
 music      │ Reprehenderit Adipiscing Nihil Neque Aliquid │ 27124 │ 2026-04-17
(12 rows)
```

### Step 4: Aggregate with JSON

Use `jsonb_agg()` to combine multiple comments into a single entry and get
something that looks like the following, followed by another entry per
category:

```
─[ RECORD 1 ]───────────────────────────────────────────────────
category │ box office
pubdate  │ 2026-04-20 06:44:34.498816+00
title    │ Sit Odio Rem Aperiam Doloribus
comments │ [                                                    ↵
         │     {                                                ↵
         │         "content": "earum proident omnis magn…",     ↵
         │         "pubdate": "2026-04-19T02:12:44.498816+00:00"↵
         │     },                                               ↵
         │     {                                                ↵
         │         "content": "incididunt hic suscipit i…",     ↵
         │         "pubdate": "2026-04-16T05:48:10.498816+00:00"↵
         │     },                                               ↵
         │     {                                                ↵
         │         "content": "Itaque omnis eum animi ex…",     ↵
         │         "pubdate": "2026-04-15T00:52:10.498816+00:00"↵
         │     }                                                ↵
         │ ]
```
