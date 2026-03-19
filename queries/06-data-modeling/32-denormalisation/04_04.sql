select driver, constructor, points
  from cache.season_points
 where season = 2017
   and points > 150;
