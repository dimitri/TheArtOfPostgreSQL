-- Loire: mainstem plus one ring of confluents (316 reaches).
-- Every reach whose next_down lands on a mainstem channel.
with mainstem as (
  select hyriv_id, geom, ord_stra
    from hydrorivers.rivers
   where main_riv = 20446779 and ord_stra >= 6
)
  select geom, ord_stra from mainstem          -- 155 high-order channels

union all

  select r.geom, r.ord_stra
    from hydrorivers.rivers r
    join mainstem m on r.next_down = m.hyriv_id
   where r.main_riv = 20446779
     and r.ord_stra < 6;                       -- 161 direct tributaries
