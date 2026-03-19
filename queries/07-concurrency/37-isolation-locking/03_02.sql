begin;

   update tweet.message
      set rts = rts + 1
    where messageid = 1;
returning messageid, rts;

commit;
