begin;

drop schema if exists tweet cascade;
drop schema if exists twcache cascade;

\ir tweets.norm.2.sql

\ir dream-theseus.sql
\ir dream-users.sql
\ir dream-followers-love.sql
\ir dream-followers-fairies.sql
\ir dream-nickname-puck.sql
\ir dream-nicknames.sql

\ir tweets.activity.sql
\ir tweets.activity.nokey.sql
\ir dream-view-counters.sql
\ir dream-mat-view.sql

commit;
