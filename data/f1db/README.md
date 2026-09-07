# Ergast Developer API

Data from

  http://ergast.com/mrd/db/

## Coverage, and the 2018-2024 append

`f1db.dump` is the last Ergast release and stops at the **2017** season:
the Ergast API was retired at the end of 2024 and its dumps were never
regenerated past that point for this schema.

`f1db.2018-2024.sql` carries the eight seasons after it (149 races and
their results, standings, qualifying, pit stops and lap times) and is
loaded on top of the dump by `taop f1db`. It is an *append*, not a
replacement: upstream primary keys are stable, so every row from
1950-2017 is untouched and every query, plan and row count the book and
courses captured against the dump still holds.

Source: <https://github.com/raceoptidata/Ergast_like-dumps> (CC BY-SA
4.0), which rebuilds the original Ergast schema from a current pipeline.
Regenerate with `tooling/f1db-append.sh`.

## Loading the data

Fetch the <http://ergast.com/downloads/f1db_ansi.sql.gz> file and restore it
into a MySQL database:

~~~
$ mysql -u root
> create database f1db;
> use f1db;
> source f1db_ansi.sql
~~~

Then load the database into PostgreSQL:

~~~
$ pgloader mysql://root@localhost/f1db pgsql://f1db@localhost/appdev
~~~

Here, the database is provided for as the `f1db.dump` file, that was created
with:

~~~
$ pg_dump -Fc -n f1db -f f1db/f1db.dump f1db
~~~

To restore it, either use the provided Makefile:

~~~
$ make f1db
~~~

or do it directly with

~~~
$ pg_restore --no-owner -U f1db -d appdev f1db/f1db.dump
~~~

Which is exactly what `make` will do for you, given the Makefile.
