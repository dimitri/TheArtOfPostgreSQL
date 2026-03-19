\set comments 3
\set articles 1

  select category.name as category,
         article.pubdate,
         title,
         jsonb_pretty(comments) as comments

    from sandbox.category
         /*
          * Classic implementation of a Top-N query
          * to fetch 3 most articles per category
          */
         left join lateral
         (
            select id,
                   title,
                   article.pubdate,
                   jsonb_agg(comment) as comments
              from sandbox.article
                  /*
                   * Classic implementation of a Top-N query
                   * to fetch 3 most recent comments per article
                   */
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
                  on true   -- required with a lateral join
              
             where category = category.id

          group by article.id
          order by article.pubdate desc
             limit :articles
         )
         as article
         on true -- required with a lateral join

order by category.name, article.pubdate desc;
