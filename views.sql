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
	o.order_id,
	o.order_ts,
	o.user_id,
	o.bonus_payment,
	o.payment,
	o.cost,
	o.bonus_grant,
	po.key as status
from
	production.orders o
left join production.orderstatuses po on
	o.status = po.id
where
	po.key = 'Closed'
	and
	o.order_ts >= '2022-01-01');
