create or replace
view analysis.orderitems as
select
	*
from
	production.orderitems;

create or replace
view analysis.orderstatuses as
select
	*
from
	production.orderstatuses;

create or replace
view analysis.products as
select
	*
from
	production.products;

create or replace
view analysis.users as
select
	*
from
	production.users;
create or replace
view analysis.orders as 
(
select
	po.order_id,
	po.order_ts,
	po.user_id,
	po.bonus_payment,
	po.payment,
	po.cost,
	po.bonus_grant,
	subq.last_status as status
from
	production.orders as po
left join 
	(
	select
		slog.order_id,
		stat.key as last_status
	from
		(
		select
			order_id,
			max(dttm) as last_status_update
		from
			production.orderstatuslog
		group by
			order_id) as slog
	left join production.orderstatuslog on
		slog.order_id = production.orderstatuslog.order_id
		and slog.last_status_update = production.orderstatuslog.dttm
	left join production.orderstatuses as stat on
		orderstatuslog.status_id = stat.id) as subq
on
	po.order_id = subq.order_id
where
	po.order_ts >= '2022-01-01');

--- datamar_ddl - 
create table analysis.dm_rfm_segments (
    user_id int primary key,
    recency smallint check(recency>0
	and recency <= 5),
    frequency smallint check(frequency>0
	and recency <= 5),
    monetary_value smallint check(monetary_value>0
	and monetary_value <= 5)
);

-- create tmp_table

CREATE TABLE analysis.tmp_rfm_recency (
 user_id INT NOT NULL PRIMARY KEY,
 recency INT NOT NULL CHECK(recency >= 1 AND recency <= 5)
);
CREATE TABLE analysis.tmp_rfm_frequency (
 user_id INT NOT NULL PRIMARY KEY,
 frequency INT NOT NULL CHECK(frequency >= 1 AND frequency <= 5)
);
CREATE TABLE analysis.tmp_rfm_monetary_value (
 user_id INT NOT NULL PRIMARY KEY,
 monetary_value INT NOT NULL CHECK(monetary_value >= 1 AND monetary_value <= 5)
);

-- tmp_rfm_recency.sql
with last_order_table as (
select
	user_id ,
	MAX(order_ts) as last_order
from
	analysis.orders ao
where
	status = 5
group by
	user_id)
insert
	into
	analysis.tmp_rfm_recency
select
	au.id as user_id,
	ntile(5) over (
order by
	(case
		when last_order is null then (
		select
			min(last_order)
		from
			last_order_table)
		else last_order
	end) asc) as recency
from
	last_order_table lot
right join analysis.users au on lot.user_id=au.id
order by
	au.id;

-- analysis.tmp_rfm_frequency
with order_quantity_table as (
select
	user_id,
	COUNT(order_id) as order_quantity
from
	analysis.orders
where
	status = 5
group by
	user_id)
insert
	into
	analysis.tmp_rfm_frequency
select
	au.id as user_id,
	ntile(5) over (
order by
	(case
		when order_quantity is null then (
		select
			MIN(order_quantity)
		from
			order_quantity_table)
		else order_quantity
	end) asc) as frequency
from
	order_quantity_table oqt
right join analysis.users au on oqt.user_id=au.id
order by
	au.id;

-- analysis.tmp_rfm_monetary_value
with total_amount_table as (
select
	user_id,
	SUM("cost") as total_amount
from
	analysis.orders
where
	status = 5
group by
	user_id)
insert
	into
	analysis.tmp_rfm_monetary_value
select
	au.id as user_id,
	ntile(5) over (
order by
	(case
		when total_amount is null then (
		select
			MIN(total_amount)
		from
			total_amount_table)
		else total_amount
	end) asc) as monetary_value
from
	total_amount_table tat
right join analysis.users au on tat.user_id=au.id
order by
	au.id;


-- datamar_query

insert into analysis.dm_rfm_segments
select user_id,
	recency,
	frequency,
	monetary_value
from analysis.tmp_rfm_recency ar
join analysis.tmp_rfm_frequency af using (user_id)
join analysis.tmp_rfm_monetary_value using (user_id);



select *
from analysis.dm_rfm_segments drs
order by user_id
limit 10;

select recency,
	count(1)
from analysis.dm_rfm_segments drs 
group by recency