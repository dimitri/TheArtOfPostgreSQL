create or replace function tweet.compute_hashtags
 (
   in message  text,
  out hashtags text[]
 )
 returns text[]
 language sql
as $$
  select array_agg(match[1] order by match[1]) as hashtags
    from regexp_matches(message, '(#[^ ,]+)', 'g') as match
$$;

create or replace function tweet.compute_hashtags_tg ()
 returns trigger
 language plpgsql
as $$
declare
begin
  --
  -- When TG_OP is 'INSERT', we give preference to the value provided in the
  -- insert statement by our users.
  --
  -- When TG_OP is 'UPDATE', we neglect OLD.hashtags entirely, and as in the
  -- insert case, we only compute a new hashtags value when the update
  -- command didn't provide/force a value, which is when NEW.hashtags is
  -- NULL.
  --
  NEW.hashtags := COALESCE(NEW.hashtags,
                           tweet.compute_hashtags(NEW.message));

  RETURN NEW;
end;
$$;

CREATE TRIGGER compute_hashtags
        BEFORE INSERT OR UPDATE
            ON tweet.message
      FOR EACH ROW
       EXECUTE PROCEDURE tweet.compute_hashtags_tg()
  
