create table color(id serial primary key, name text);

create table cars
 (
   brand   text,
   model   text,
   color   integer references color(id)
 );

insert into color(name)
     values ('blue'), ('red'),
            ('gray'), ('black');

insert into cars(brand, model, color)
     select brand, model, color.id
      from (
            values('ferari', 'testarosa', 'red'),
                  ('aston martin', 'db2', 'blue'),
                  ('bentley', 'mulsanne', 'gray'),
                  ('ford', 'T', 'black')
           )
             as data(brand, model, color)
           join color on color.name = data.color;
