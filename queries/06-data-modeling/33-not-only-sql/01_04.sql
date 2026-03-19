select jsonb_pretty(data)
  from magic.cards
 where data @> '{"type":"Enchantment",
                 "artist":"Jim Murray",
                 "colors":["White"]
                }';
