select pg_column_size(uuid 'fbb850cc-dd26-4904-96ef-15ad8dfaff07')
       as uuid_bytes,

       pg_column_size('fbb850cc-dd26-4904-96ef-15ad8dfaff07')
       as uuid_string_bytes;
