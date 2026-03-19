SELECT results_eq(
    'SELECT * FROM active_users()',
    $$
      VALUES (42, 'Anna'),
             (19, 'Strongrrl'),
             (39, 'Theory')
    $$,
    'active_users() should return active users'
);
