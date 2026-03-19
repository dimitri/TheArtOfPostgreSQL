begin;

create table twcache.counters
 (
   messageid  bigint not null references tweet.message(messageid),
   rts        bigint,
   favs       bigint,

   unique(messageid)
 );

create or replace function twcache.tg_update_counters ()
 returns trigger
 language plpgsql
as $$
declare
begin
   insert into twcache.counters(messageid, rts, favs)
        select NEW.messageid,
               case when NEW.action = 'rt' then 1 else 0 end,
               case when NEW.action = 'fav' then 1 else 0 end
   on conflict (messageid)
     do update
           set rts = case when NEW.action = 'rt'
                          then counters.rts + 1

                          when NEW.action = 'de-rt'
                          then counters.rts - 1

                          else counters.rts
                      end,

               favs = case when NEW.action = 'fav'
                           then counters.favs + 1

                           when NEW.action = 'de-fav'
                           then counters.favs - 1

                           else counters.favs
                       end
         where counters.messageid = NEW.messageid;

  RETURN NULL;
end;
$$;

CREATE TRIGGER update_counters
         AFTER INSERT
            ON tweet.activity
      FOR EACH ROW
       EXECUTE PROCEDURE twcache.tg_update_counters();

insert into tweet.activity(messageid, action)
     values (7, 'rt'),
            (7, 'fav'),
            (7, 'de-fav'),
            (8, 'rt'),
            (8, 'rt'),
            (8, 'rt'),
            (8, 'de-rt'),
            (8, 'rt');

select messageid, rts, favs
  from twcache.counters;

rollback;
