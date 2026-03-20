# The Art of PostgreSQL - data loading tool

The data sets used in the book [The Art of
PostgreSQL](https://theartofpostgresql.com) are all available online with
Open Source or Open Data compatible licencing, but sometimes requires
pre-processing.

The pre-processing has been developed in a small tool written in Common
Lisp, that compiles into a single binary with the following sub-commands:

~~~
$ ./bin/taop [ --help ] [ --version ] command ...

Available commands:

 scan34     &OPTIONAL DIRECTORY
 tweet      &OPTIONAL PLAY
 retweet    MESSAGEID WORKERS TIMES
 rates      &OPTIONAL CSV DIRECTORY
 gitlog init
 gitlog import PROJECT
 gitlog fetch REPOSITORY
 commitlog
 pubnames
 magic      &OPTIONAL DIRECTORY
 f1db       &OPTIONAL DIRECTORY
 moma
 opendata
 eav
 sandbox
 load-data
~~~

To build the tool:

~~~
$ make
~~~

To clean-up after the build:

~~~
$ make clean
~~~
