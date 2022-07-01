with last_order_table as (
select
	user_id,
	MAX(order_ts) as last_order
from
	analysis.orders
where
	status = 'Closed'
group by
	user_id)

insert
	into
	analysis.tmp_rfm_recency
select
	analysis.users.id as user_id,
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
	last_order_table
right join analysis.users
		using(users.id)
order by
	analysis.users.id;
