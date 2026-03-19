  SELECT datname,
         pg_database_size(datname) as bytes
    FROM pg_database
ORDER BY bytes desc;
