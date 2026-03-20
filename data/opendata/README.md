# Open Data

Various open data files for learning SQL with PostgreSQL.

## Files

### hello
- `hello.sql` - Hello world translations table
- `hello.csv` - CSV data with language and greeting

### Archives de la Planète
- `archives-de-la-planete.sql` - Photo archive metadata schema
- `archives-de-la-planete.csv` - Photo archive data

Source: [Open Data Hauts-de-Seine](https://opendata.hauts-de-seine.fr/explore/dataset/archives-de-la-planete/)

### CIA World Factbook
- `factbook.sql` - World factbook schema
- `factbook.csv` - Country data
- `factbook.xls` - Excel source file
- `factbook-month.py` - Python scripts for data processing

## Usage

```sql
\i opendata/hello.sql
\i opendata/archives-de-la-planete.sql
\i opendata/factbook.sql
```
