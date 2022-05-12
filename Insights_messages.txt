
create or replace function insights_messages () 
returns void
as $$
begin

insert into insights_messages -- Predictions for floors from parkhelp are used to determine the busyness of the floors. An availability treshhold of 50 is used. 
with a as (
select p.subsystem ,'Busyness' as kpi, t.floor as location , p.prediction as prediction,
case when p.prediction <50 then 'Busy' 
else 'Not Busy' 
end as value, 
p.timestamp

from predictions p, json_to_record(info::json) as t (unit text, floor text) 
where p.vendor='ParkHelp-Occ'
order by p.timestamp desc),

-- Predictions for floors from IPParking are used to determine the busyness of the garge. An availability treshhold of 50 is used.

b as (
select p.subsystem ,'Busyness' as kpi, t.location as location ,p.prediction as prediction ,
case when p.prediction <50 then 'Busy'
else 'Not Busy' 
end as value,
p.timestamp

from predictions p, json_to_record(info::json) as t (unit text, location text) 
where p.vendor='IPParking-Occ'
order by p.timestamp desc),

c as(
select distinct * from b
union all
select * from a
),

-- aggregating the floors data to find the busyness of the entire parking. An availability treshhold of 200 is used. 
d as (

select subsystem, kpi, 'Parking' as location, sum(prediction), 
case when sum(prediction) <200 then 'Busy' 
else 'Not Busy' end as value, 
timestamp
from a group by 1,2,3,6
),

e as (

select subsystem, kpi,location, value, timestamp from a 
union all
select subsystem, kpi,location, value, timestamp from d

)

select * from e order by timestamp desc, location asc

end;
$$ language plpgsql