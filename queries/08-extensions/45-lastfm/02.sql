  select tags.tag, count(tid_tag.tid)
    from tid_tag, tags
   where tid_tag.tag=tags.rowid and tags.tag ~* 'setzer'
group by tags.tag;
