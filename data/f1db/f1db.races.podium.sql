begin;

truncate public.podiums;

insert into public.podiums
     select races.raceid,
            date,
            races.name as race,
            winner.driverid as winnerid,
            winner.surname as winner,
            r1.points as pts1,
   
            second.driverid as secondid,
            second.surname as second,
            r2.points as pts2,

            third.driverid as thirdid,
            third.surname as third,
            r3.points as pts3

       from races
   
            join results as r1
              on r1.raceid = races.raceid
             and r1.position =1
            join drivers winner
              on r1.driverid = winner.driverid
            
            join results as r2
              on r2.raceid = races.raceid
             and r2.position = 2
            join drivers second
              on r2.driverid = second.driverid
            
            join results as r3
              on r3.raceid = races.raceid
             and r3.position = 3
            join drivers third
              on r3.driverid = third.driverid
            
   order by races.raceid desc;

commit;
