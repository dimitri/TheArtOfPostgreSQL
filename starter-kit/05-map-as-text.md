# A Map With No Graphics Library

You don't always need a plotting library to *see* your data. With nothing but
`GROUP BY`, a little arithmetic, and a handful of Unicode shade characters,
PostgreSQL can draw a density map straight into the query result — in the same
spirit as the `■■■` bar charts elsewhere in the book.

We use the **tweet** dataset (loaded with `taop hashtag`): 200,000 geolocated
tweets from across the United States, each with a `longitude` and `latitude`.

## The Problem

Where are the tweets? We want a quick map of their density — no GUI, no client,
just `psql`.

## The Query

Bin every tweet into a grid of character cells, count how many fall in each,
and pick a shade block (`█ ▓ ▒ ░`) by how busy the cell is:

```sql
with bounds as (
   select -125 as w, -66 as e, 24 as s, 50 as north, 80 as cols, 20 as rows
), grid as (                       -- one row per character cell
   select gx as cx, gy as cy
     from bounds,
          generate_series(0, cols - 1) as gx,
          generate_series(0, rows - 1) as gy
), hits as (                       -- tweets binned into the same cells
   select floor((longitude - w)    / (e - w)     * cols)::int as cx,
          floor((north - latitude) / (north - s) * rows)::int as cy,
          count(*) as c
     from tweet, bounds
    where longitude between w and e
      and latitude  between s and north
    group by 1, 2
)
 select string_agg(case when c is null then ' '
                        when c > 250   then '█'
                        when c >  80   then '▓'
                        when c >  20   then '▒'
                        else                '░' end,
                   '' order by cx)
   from grid left join hits using (cx, cy)
  group by cy
  order by cy;
```

The result is a map, drawn in nothing but text — and the United States is
unmistakable, dense seaboards and Florida and all:

```
               ░▒░   ░    ░  ░░ ░░  ░▓░ ░░ ░ ░ ░   ░░
              ▒░░░▒░  ░   ░ ░░░ ░░ ░░▒░░░░░░░  ░░          ░  ░ ░
          ░ ░ ▒░ ░░░░ ░  ░ ░░░░░▒ ░░  ▓▒░░░░▓░░░░░░░░ ░░ ░░░ ░░     ░
         ░ ░    ░░▒░ ░▒░  ░    ░  ░░░░░▒░▒██░▒░▒░░▒░░░▒░░ ░ ░░░░░░█▒░█░
        ░░░▓░ ░░ ░░░░░░░░ ░ ░▒ ░  ░ ░░▓░░░▓▓▒▒░▒▒▓▓░▒▒▒▒░░░░▓█▓▒▒▒▒▒░▒▓▒
          ░░░░░░░▒ ░░ ░  ░░░ ░ ░   ░ ░▒░░░░░▓░▒▒███ ▓█▓███░▓▓██▓█▓█▓▒█▓▓██
      ░░ ░  ░░░  ▓░░ ░ ░░░░▒░░░░░ ░ ▒▒▒█░░█▒░▓▓░▒██▓▓▓▓▒█▒███▒▒░▒▓▓▓██████▒
   ░▒░░░ ░ ░░ ░░ █▓░░░░░░▒██░░░ ░░░░░░▓░▒░▒░░▒░▓▓▓▒▓█▓▓███▒▓██▒▓▓██████░
  ▓▓██▓▓░░░▒ ░   ░░░░░▒░▒▒▒█ ░▒░░ ░░░▒▒▓▓█▒▒▓░██▒▒▒▒▓▓██▒▓▓░▒░▒▓██▓██
  ████▒▒▒░░  ░░▒░░  ░░░▒░░░▓▓░░▒▒░░░░█░▒░▓▓▓▒▒▒▒▓▒▓▒▒██▒▒▒▒▓▓▓▓▓█▓▒░
   ░█░▒█░░░░░█░░░▒░░░░▒░░▒░░ ░▒▒░░░░▒▓░█▒▓▒▒░░▒▒▒▒▒██▒▒█▓▓▓▓███▓▒▒█░  ░
     ▓▒▓█▓▓░░░▒░░▓▒░░░░░█▓░░░░░▒░░░░▒█▒░░▓░▓█▒▒█▒▓▓▓▓▓▓▒▒█▓██▒▓▓▓▒░░
  ░    ▓████▒░░░░█▓░░░░ ░ ░░░▓░▓░ ░▒░▓█▒░▒░▒▒░▒▒▒▓▓█▓▒██▓░▓█▓▒▓▓░
    ░     █▓▒▒░ ░▒▓█░ ░░▓▒ ░░░▒▒░░▓░▒██▒▓▒▓▒▓░▒█▒▒░░▓▓▓▒▓▒▓█▓█
  ░        ░░░ ░ ░░▒░    █░░ ░ ░░░░░▓█▓▒▒▒░▒▒▒▓▒▓▒▓▒▒▒▒▓▒░▒▒░
       ░          ░░   ░   ░░░  ▒░░██▓▒██▒▒▒██▓█▓▒▒▓▓▓░▓░▓██  ░         ░  ░
              ░ ░░▓█ ░  ░▒░░ ░  ░▒░░░▒░░▒     ░░░░       ███▓   ░
                ░░  ▒░░░  ░    ▒  ▒ ░▓      ░            █▓▒█░  ░          ░
                     ▒░  ░░  ▓░ ▓█░░▓▒          ░      ░  █░█░▒ ░░
       ░      ░    ▒ ░ ▓ ░░▒░░ ░░░░░         ░ ░       ░  ▒▒▒  ░▒░░
```

It is the very same data PostGIS draws as a proper density map — only the
rendering differs:

![Density of 200,000 geolocated tweets across North America](img/fig-tweets-density.png)

## Going further: Braille

A shade block gives one "pixel" per character. A **Braille** cell (`U+2800`–
`U+28FF`) packs a 2×4 dot matrix into a single glyph — eight times the
resolution. Set one bit per occupied sub-cell and read out
`chr(10240 + bit_or(...))`, and the same query renders a crisp dotted coastline.
(It depends on the terminal font having Braille glyphs, so shade blocks are the
safer default for sharing.)

The point stands either way: a "map" is just a grid of counts, and SQL is very
good at grids of counts.

> This example accompanies Chapter 51 of [*The Art of PostgreSQL*](https://theartofpostgresql.com/book/contents/?utm_source=lab&utm_medium=app&utm_content=starterkit-05-map-as-text), **Counting
> Distinct Users with HyperLogLog**, which is built on this tweet dataset.
