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
