create table js(id serial primary key, extra json);
insert into js(extra)
     values ('[1, 2, 3, 4]'),
            ('[2, 3, 5, 8]'),
            ('{"key": "value"}');
