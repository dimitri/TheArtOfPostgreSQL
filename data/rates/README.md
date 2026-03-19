# Exchange Rate Archives by Month

The data comes from:

  https://www.imf.org/external/np/fin/data/param_rms_mth.aspx

It is possible to download a TSV file from the website, but then you have to
manually process it. Here's what it looks like:

~~~
Currency units per SDR for May 2017
Currency	May 01, 2017	May 02, 2017	May 03, 2017	...
Chinese Yuan	NA	9.445190	9.439220	...
~~~

  - split in two files each with a series of dates, because each month is
    split into two “regions” in the file, for 15 days each or abouts,
    
  - then use the `rates` command in the `appdev` program to turn those TSV
    files into a single CSV file that look like the following:
    
~~~ csv
Chinese Yuan;2017-05-02;9.445190
Chinese Yuan;2017-05-03;9.439220
Chinese Yuan;2017-05-04;9.440640
Chinese Yuan;2017-05-05;9.455820
...
~~~

Here's what running the command looks like:

~~~
$ appdev rates ./rates/rates.csv ./rates
Loading rates currency files from "./rates/"
Parsing rates from "./rates/201705-1.tsv"
Parsing rates from "./rates/201705-2.tsv"
Parsing rates from "./rates/201706-1.tsv"
Parsing rates from "./rates/201706-2.tsv"
Parsing rates from "./rates/201707-1.tsv"
Parsing rates from "./rates/201707-2.tsv"
Wrote 3057 currency rate values for 51 currencies to "./rates/rates.csv"
~~~

Then to load the dataset use the `rates/rates.sql` file:

~~~
$ cd rates && psql -f rates.sql -d appdev
...
DROP TABLE
CREATE TABLE
COPY 3050
CREATE TABLE
INSERT 0 3050
COMMIT
~~~
