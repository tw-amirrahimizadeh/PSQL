create type lenel as (

ssno varchar(100),
"devId" varchar(100),
"eventTime" timestamp,
"eventType" text,
"employeeId" varchar(100),
"eventDescription" text
)


create type luxerone as (

type text,
occupied int,
reserved int,
available int,
locker_type_id int,
out_of_service int
)

create or replace function parse (sys text, table_name text, type text) returns void --Name of the subsystem, the new table with parsed data, and schema of the data which is created before.
as $$
begin
	-- Check if it's creating the parsed table for the first time or it currently exists in the db. The entries of the audit table are saved in a temporary table.
	if exists (select relname from pg_class where relname=$2)
	then 
		execute 
		format('create temp table if not exists temp_table as 
		select * from audit where subsystem=''%s'' and timestamp > (select max(timestamp) from %s)', $1, $2);
	else
		execute 
		format('create temp table if not exists temp_table as 
		select * from audit where subsystem=''%s'' ', $1);
	
	end if;
 -- Parse the data and insert them into the table
	if exists (select relname from pg_class where relname=$2)
	then	
		execute
		format('insert into %s
		select timestamp, (jsonb_populate_recordset(null::%s, payload::jsonb)).* from temp_table',$2,$3);
	else	
		execute
		format('create table if not exists %s as 
		 select timestamp, (jsonb_populate_recordset(null::%s, payload::jsonb)).* from temp_table',$2,$3);
	end if;
	
	drop table temp_table;
end;
$$ language plpgsql;


select parse('lockerAudit','luxerone_lockers', 'luxerone');

select parse('accessEvent','lenel_entries', 'lenel');  
