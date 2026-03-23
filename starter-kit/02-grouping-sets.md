# GROUPING SETS + FILTER: Multiple Aggregations in One Pass

Ever needed to compute both per-driver and per-constructor points in the
same query? PostgreSQL's `GROUPING SETS` and `FILTER` clauses make this
elegant.

We take an example from Chapter 15 of the book titled **Group By, Having,
With, Union All**. In that chapter we play with the *f1db* schema and data
set, so we dive into the world of Formula 1.

## The Problem

The Formula One racing seems to be interesting enough outside of what we
cover in this book and the respective database: Wikipedia is full of
information about this sport. In the [list of Formula One
seasons](https://en.wikipedia.org/wiki/List_of_Formula_One_seasons), we can
see a table of all seasons and their champion driver and champion
constructor: the driver/constructor who won the most points in total in the
races that year.

To compute that in SQL we need to first add up the points for each driver
and constructor and then we can select those who won the most each season:

## The Query

```
\i 04-sql-select/16-sql-103/05_03_f1db.seasons.winners.sql
```

```sql
with points as (
   select year as season, driverid, constructorid,
          sum(points) as points
     from results join races using(raceid)
 group by grouping sets((year, driverid),
                        (year, constructorid))
   having sum(points) > 0
),
tops as (
   select season,
          max(points) filter(where driverid is null) as ctops,
          max(points) filter(where constructorid is null) as dtops
     from points
 group by season
),
champs as (
   select tops.season, champ_driver.driverid, champ_driver.points,
          champ_constructor.constructorid, champ_constructor.points
     from tops
          join points as champ_driver on champ_driver.season = tops.season
           and champ_driver.constructorid is null
           and champ_driver.points = tops.dtops
          join points as champ_constructor on champ_constructor.season = tops.season
           and champ_constructor.driverid is null
           and champ_constructor.points = tops.ctops
)
select season,
       format('%s %s', drivers.forename, drivers.surname) as "Driver's Champion",
       constructors.name as "Constructor's champion"
  from champs
       join drivers using(driverid)
       join constructors using(constructorid)
order by season;
```

This time we get about a full page SQL query, and yes it's getting complex.
The main thing to see is that we are *daisy chaining* the CTEs:

  1. The *points* CTE is computing the sum of points for both the
     drivers and the constructors for each season.

     We can do that in a single SQL query thanks to the *grouping sets*
     feature that is covered in more details later in this book. It allows
     us to run aggregates over more than one group at a time within a single
     query scan.

  2. The *tops* CTE is using the *points* one in its *from* clause and it
     computes the maximum points any driver and constructor had in any given
     season,
    
     We do that in a separate step because in SQL it's not possible to
     compute an aggregate over an aggregate:
    
        ERROR:  aggregate function calls cannot be nested
        
     Thus the way to have the sum of points and the maximum value for the
     sum of points in the same query is by using a two-stages pipeline,
     which is what we are doing.
    
  3. The *champs* CTE uses the *tops* and the *points* data to restrict our
     result set to the champions, that is those drivers and constructors who
     made as many points as the maximum.
     
     Additionnaly, in the *champs* CTE we can see that we use the *points*
     data twice for different purposes, aliasing the relation to
     *champ_driver* when looking for the champion driver, and to
     *champ_constructor* when looking for the champion constructor.
     
  4. Finally we have the outer query that uses the *champs* dataset and
     formats it for the application, which is close to what our Wikipedia
     example page is showing.

Here's a cut-down version of the 68 rows in the final result set:

~~~ psql
 season │ Driver's Champion  │ Constructor's champion 
════════╪════════════════════╪════════════════════════
   1950 │ Nino Farina        │ Alfa Romeo
   1951 │ Juan Fangio        │ Ferrari
   1952 │ Alberto Ascari     │ Ferrari
   1953 │ Alberto Ascari     │ Ferrari
   1954 │ Juan Fangio        │ Ferrari
   1955 │ Juan Fangio        │ Mercedes
   1956 │ Juan Fangio        │ Ferrari
   1957 │ Juan Fangio        │ Maserati
...
   1985 │ Alain Prost        │ McLaren
   1986 │ Alain Prost        │ Williams
   1987 │ Nelson Piquet      │ Williams
   1988 │ Alain Prost        │ McLaren
   1989 │ Alain Prost        │ McLaren
   1990 │ Ayrton Senna       │ McLaren
   1991 │ Ayrton Senna       │ McLaren
   1992 │ Nigel Mansell      │ Williams
   1993 │ Alain Prost        │ Williams
...
   2013 │ Sebastian Vettel   │ Red Bull
   2014 │ Lewis Hamilton     │ Mercedes
   2015 │ Lewis Hamilton     │ Mercedes
   2016 │ Nico Rosberg       │ Mercedes
~~~


## Step-by-Step

### Step 1: Simple GROUP BY

Start with basic points aggregation:

```sql
select year, driverid, sum(points) as pts
  from results join races using(raceid)
 group by year, driverid
 order by year, pts desc;
```

### Step 2: Add GROUPING SETS

Use `GROUPING SETS` to aggregate both drivers AND constructors in one pass:

```sql
select year as season, driverid, constructorid,
       sum(points) as pts
  from results join races using(raceid)
 group by grouping sets((year, driverid),
                        (year, constructorid))
 order by year, pts desc;
```

### Step 3: Add FILTER Clause

Use `FILTER` to extract top points for each category:

```sql
select season,
       max(points) filter(where driverid is not null) as driver_pts,
       max(points) filter(where constructorid is not null) as constructor_pts
  from (
      select year as season, driverid, constructorid, sum(points) as points
        from results join races using(raceid)
       group by grouping sets((year, driverid), (year, constructorid))
  ) as data
 group by season;
```

### Step 4: Self-Join to Find Champions

Join back to find who achieved those top scores:

```sql
-- Join the tops CTE to the points CTE twice:
-- once to find the driver, once to find the constructor
from tops
join points as champ_driver on champ_driver.season = tops.season
                     and champ_driver.constructorid is null
                     and champ_driver.points = tops.dtops
join points as champ_constructor on champ_constructor.season = tops.season
                               and champ_constructor.driverid is null
                               and champ_constructor.points = tops.ctops
```

