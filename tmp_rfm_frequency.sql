with order_quantity_table as (
select
	user_id,
	COUNT(order_id) as order_quantity
from
	analysis.orders
where
	status = 'Closed'
group by
	user_id)

insert
	into
	analysis.tmp_rfm_frequency
select
	analysis.users.id as user_id,
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
	order_quantity_table
right join analysis.users
		using(users.id)
order by
	analysis.users.id;
