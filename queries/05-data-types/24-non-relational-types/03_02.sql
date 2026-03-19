create table docs
 (
   id      serial primary key,
   content xml
 );

insert into docs(content)
     values ('<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<body>hello</body>
</html>');

select id, striptags(content)
  from docs;
