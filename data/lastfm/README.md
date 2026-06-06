# Last.fm

A subset of the Last.fm music dataset (10,262 tracks with artist/title/track_id).

To obtain the data:

```bash
curl -L -o lastfm_subset.zip http://labrosa.ee.columbia.edu/millionsong/sites/default/files/lastfm/lastfm_subset.zip
```

The subset is 12 MB and fully powers Chapter 8's trigrams queries.

For full tag tables (tid_tag, tags), see the optional phase 2 in the plan
(requires the ~1 GB lastfm_tags.db).
