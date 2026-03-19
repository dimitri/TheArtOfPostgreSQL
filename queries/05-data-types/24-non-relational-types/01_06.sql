explain (analyze, verbose, costs off, buffers)
 select count(*)
  from hashtag
 where hashtags @> array['#job'];
                              QUERY PLAN                              
══════════════════════════════════════════════════════════════════════
 Aggregate (actual time=27.227..27.227 rows=1 loops=1)
   Output: count(*)
   Buffers: shared hit=3715
   ->  Bitmap Heap Scan on public.hashtag (actual time=13.023..23.453…
… rows=17763 loops=1)
         Output: id, date, uname, message, location, hashtags
         Recheck Cond: (hashtag.hashtags @> '{#job}'::text[])
         Heap Blocks: exact=3707
         Buffers: shared hit=3715
         ->  Bitmap Index Scan on hashtag_hashtags_idx (actual time=1…
…1.030..11.030 rows=17763 loops=1)
               Index Cond: (hashtag.hashtags @> '{#job}'::text[])
               Buffers: shared hit=8
 Planning time: 0.596 ms
 Execution time: 27.313 ms
(13 rows)
