-- Loire mainstem + ring 1 + ring 2 (05_06) rendered as a single <svg>
-- document, same naturalearth.countries backdrop, one more shade of blue.
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
),
ring1 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779 and r.ord_stra < 6
),
ring2 as (
  select r.hyriv_id, r.geom, r.ord_stra
    from hydrorivers.rivers r
    join ring1 on r.next_down = ring1.hyriv_id
   where r.main_riv = 20446779
),
loire_bbox as (
  select st_xmin(bbox) as x0, st_xmax(bbox) as x1,
         st_ymin(bbox) as y0, st_ymax(bbox) as y1
    from (select st_extent(geom) as bbox
            from hydrorivers.rivers
           where main_riv = 20446779) e
),
win as (
  select st_makeenvelope(
           (x0+x1)/2 - half, (y0+y1)/2 - half,
           (x0+x1)/2 + half, (y0+y1)/2 + half,
           4326) as env
    from loire_bbox,
         lateral (select greatest(x1-x0, y1-y0)/2 + 2.0 as half) h
),
countries as (
  select c.name,
         st_intersection(c.geom, win.env) as geom
    from naturalearth.countries c, win
   where st_intersects(c.geom, win.env)
),
layers as (
  select 1 as z, '<path d="' || st_assvg(geom, 0, 3) || '" fill="' ||
         (case when name = 'France' then '#F2EFE9' else '#ECECEC' end) ||
         '" stroke="#C0B8AE" stroke-width="0.02"/>' as elem
    from countries
  union all
  select 2, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#5B8DB8" stroke-width="0.05" stroke-linecap="round"/>' as elem
    from mainstem
  union all
  select 3, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#7FA5C7" stroke-width="0.02" stroke-linecap="round"/>' as elem
    from ring1
  union all
  select 4, '<path d="' || st_assvg(geom, 0, 4) ||
         '" fill="none" stroke="#A3BDD6" stroke-width="0.012" stroke-linecap="round"/>' as elem
    from ring2
)
select '<svg viewBox="' || w.x0 || ' ' || (-w.y1) || ' ' ||
       (w.x1 - w.x0) || ' ' || (w.y1 - w.y0) ||
       '" xmlns="http://www.w3.org/2000/svg">' ||
       '<rect x="' || w.x0 || '" y="' || (-w.y1) || '" width="' ||
              (w.x1 - w.x0) || '" height="' || (w.y1 - w.y0) ||
              '" fill="#E8EEF5"/>' ||
       string_agg(layers.elem, '' order by layers.z) || '</svg>' as svg
  from layers,
       (select st_xmin(env) as x0, st_xmax(env) as x1,
               st_ymin(env) as y0, st_ymax(env) as y1
          from win) as w
 group by w.x0, w.x1, w.y0, w.y1;
