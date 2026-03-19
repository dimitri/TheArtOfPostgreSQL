   update tweet.users
      set nickname = 'Robin Goodfellow'
    where userid = 17 and uname = 'Puck'
returning users.*;
