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

