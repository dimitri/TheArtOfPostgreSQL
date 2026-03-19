select pg_column_size(timestamp without time zone 'now'),
       pg_column_size(timestamp with time zone 'now');
