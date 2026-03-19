# The Art of PostgreSQL - data loading tool

The data sets used in the book [The Art of
PostgreSQL](https://theartofpostgresql.com) are all available online with
Open Source or Open Data compatible licencing, but sometimes requires
pre-processing.

The pre-processing has been developed in a small tool written in Common
Lisp, that compiles into a single binary with the following sub-commands:

~~~
$ ./bin/taop 
./bin/taop [ --help ] [ --version ] command ...
./bin/taop: command line parse error.


Available commands:
 scan34   CSV DIRECTORY                   parse scan34 access.log file, outputs a CSV file.
 tweet    PLAY                            Parse the XML file PLAY and tweet its lines.
 retweet  MESSAGEID WORKERS TIMES         retweet MessageID given TIMES in concurrent WORKERS threads.
 rates    CSV DIRECTORY                   parse rates TSV files in DIRECTORY, outputs a CSV file.
 gitlog   CSV PROJECT-DIRECTORY           parse a git project's log and output a csv file.
 lastfm   ZIPFILENAME                     load the lastfm subset zip of JSON files.
 pubnames                                 load the pubnames from OSM export

~~~

To build the tool:

~~~
$ make
~~~

To clean-up after the build:

~~~
$ make clean
~~~
