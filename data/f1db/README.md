# Ergast Developer API

Data from

  http://ergast.com/mrd/db/

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
