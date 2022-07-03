with total_amount_table as (
select
	user_id,
	SUM("cost") as total_amount
from
	analysis.orders
where
	status = 4
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