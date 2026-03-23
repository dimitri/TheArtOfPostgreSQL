# Nested LATERAL Joins: Top-N Per Group

The "Top-N per group" is a classic SQL problem. PostgreSQL's `LATERAL` keyword makes it elegant, and you can even nest them.

## The Problem

For each category, show the top N articles. For each article, show the top M comments. In a single query.

## The Query

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

Start with a simple join between categories and articles:

```sql
select category.name, article.title
  from sandbox.category
  join sandbox.article on article.category = category.id;
```

### Step 2: Add LATERAL

Use LATERAL to get the top articles per category:

```sql
select category.name, article.title, article.pubdate
  from sandbox.category
  join lateral (
      select id, title, pubdate
        from sandbox.article
       where category = category.id
    order by pubdate desc
       limit 1
  ) as article on true;
```

### Step 3: Add a Second LATERAL

Nest another LATERAL to get top comments per article:

```sql
select category.name, article.title,
       comment.content
  from sandbox.category
  join lateral (
      select id, title, pubdate
        from sandbox.article
       where category = category.id
    order by pubdate desc
       limit 1
  ) as article on true
  join lateral (
      select content, pubdate
        from sandbox.comment
       where article = article.id
    order by pubdate desc
       limit 3
  ) as comment on true;
```

### Step 4: Aggregate with JSON

Use `jsonb_agg()` to combine multiple comments:

```sql
select category.name,
       article.title,
       jsonb_agg(comment.content) as comments
  from sandbox.category
  join lateral (...) as article on true
  join lateral (...) as comment on true
  group by category.name, article.id;
```

## How to Run

```bash
docker compose run --rm -it psql

-- First load the sandbox data
\i data/sandbox/sandbox.sql

-- Then run the query
\i starter-kit/01-nested-lateral.sql
```
