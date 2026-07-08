package main

import (
	"strings"
	"testing"
)

func TestPreprocessPsqlScript(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want string
	}{
		{
			name: "quoted substitution (factbook)",
			in: `\set start '2017-02-01'

  select date
    from factbook
   where date >= date :'start'
     and date  < date :'start' + interval '1 month'
order by date;`,
			want: `

  select date
    from factbook
   where date >= date '2017-02-01'
     and date  < date '2017-02-01' + interval '1 month'
order by date;`,
		},
		{
			name: "raw substitution with embedded SQL literal (f1 season)",
			in: `\set season 'date ''1978-01-01'''

  select status, count(*)
    from results
   where date >= :season
     and date <  :season + interval '1 year';`,
			want: `

  select status, count(*)
    from results
   where date >= date '1978-01-01'
     and date <  date '1978-01-01' + interval '1 year';`,
		},
		{
			name: "bare numeric value plus quoted date (sql-101)",
			in: `\set beginning '2017-04-01'
\set months 3

select date
  from races
 where date >= date :'beginning'
   and date <  date :'beginning' + :months * interval '1 month';`,
			want: `


select date
  from races
 where date >= date '2017-04-01'
   and date <  date '2017-04-01' + 3 * interval '1 month';`,
		},
		{
			name: "cast operator must survive untouched",
			in:   `select foo::int, bar::text from baz;`,
			want: `select foo::int, bar::text from baz;`,
		},
		{
			name: "unknown variable left untouched",
			in:   `select :'nope', :nope2 from t;`,
			want: `select :'nope', :nope2 from t;`,
		},
		{
			name: "pset and copy lines stripped",
			in: `\pset format aligned
select 1;
\copy foo from 'bar.csv'`,
			want: `
select 1;
`,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := preprocessPsqlScript(tc.in, map[string]string{})
			if strings.TrimSpace(got) != strings.TrimSpace(tc.want) {
				t.Errorf("mismatch\n--- got ---\n%s\n--- want ---\n%s", got, tc.want)
			}
		})
	}
}
