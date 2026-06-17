-- Loire: mainstem plus two rings of confluents (448 reaches).
-- Shows the repeated pattern that WITH RECURSIVE automates.
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
)
  select geom, ord_stra from mainstem
union all
  select geom, ord_stra from ring1             -- 161 direct tributaries
union all
  select r.geom, r.ord_stra
    from hydrorivers.rivers r
    join ring1 on r.next_down = ring1.hyriv_id
   where r.main_riv = 20446779;               -- 132 more: total 448
