select customer.id,
       customer.name,
       ctype.name,
       rtime.value::interval as "resp. time",
       etime.value::interval as "esc. time"
  from eav.customer
       join eav.support
         on support.customer = customer.id

       join eav.support_contract as contract
         on support.contract = contract.id

       join eav.support_contract_type as ctype
         on ctype.id = contract.type

       join eav.params as rtime
         on rtime.entity = ctype.name
        and rtime.parameter = 'response time'
       
       join eav.params as etime
         on etime.entity = ctype.name
        and etime.parameter = 'escalation time';
