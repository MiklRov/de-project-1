# Проект 1
# Витрина RFM

## 1.1. Выясните требования к целевой витрине.
Постановка задачи выглядит достаточно абстрактно - постройте витрину. Первым делом вам необходимо выяснить у заказчика детали. Запросите недостающую информацию у заказчика в чате.

Зафиксируйте выясненные требования. Составьте документацию готовящейся витрины на основе заданных вами вопросов, добавив все необходимые детали.

-----------
Задача: построить витрину для RFM-классификации клиентов. 
Отбор данных: 
1. Заказы со статусом CLOSED.
2. Период с начала 2022 год
3. Обновление данных не требуется

Название витрины: dm_rfm_segments (схема analysis)
Источник данных: таблицы из схемы production

Витрина должна состоять из таких полей:
1. user_id
2. recency (число от 1 до 5)
3. frequency (число от 1 до 5)
4. monetary_value (число от 1 до 5)

Критерии присвоения рейтинга:
* Фактор Recency измеряется по последнему заказу. Распределите клиентов по шкале от одного до пяти, где значение 1 получат те, кто либо вообще не делал заказов, либо делал их очень давно, а 5 — те, кто заказывал относительно недавно.
* Фактор Frequency оценивается по количеству заказов. Распределите клиентов по шкале от одного до пяти, где значение 1 получат клиенты с наименьшим количеством заказов, а 5 — с наибольшим.
* Фактор Monetary оценивается по потраченной сумме. Распределите клиентов по шкале от одного до пяти, где значение 1 получат клиенты с наименьшей суммой, а 5 — с наибольшей.

Все клиенты делятся на 5 групп с одинаковым количеством



## 1.2. Изучите структуру исходных данных.

Полключитесь к базе данных и изучите структуру таблиц.

Если появились вопросы по устройству источника, задайте их в чате.

Зафиксируйте, какие поля вы будете использовать для расчета витрины.

-----------

1. recency - order_ts
2. frequency - order_id
3. monetary_value - cost


## 1.3. Проанализируйте качество данных

Изучите качество входных данных. Опишите, насколько качественные данные хранятся в источнике. Так же укажите, какие инструменты обеспечения качества данных были использованы в таблицах в схеме production.

-----------

Качество данных высокое. Оно обеспечено следующими правилами:
* На большинство полей всех таблиц установлено ограничение NOT NULL
* Типы данных указаны согласно логике заполнения
* Категорийные признаки привязаны к таблицам с помощью FOREIGN KEY
* Дублирование записей блокируется с помощью PRIMARY KEY


## 1.4. Подготовьте витрину данных

Теперь, когда требования понятны, а исходные данные изучены, можно приступить к реализации.

### 1.4.1. Сделайте VIEW для таблиц из базы production.**

Вас просят при расчете витрины обращаться только к объектам из схемы analysis. Чтобы не дублировать данные (данные находятся в этой же базе), вы решаете сделать view. Таким образом, View будут находиться в схеме analysis и вычитывать данные из схемы production. 

Напишите SQL-запросы для создания пяти VIEW (по одному на каждую таблицу) и выполните их. Для проверки предоставьте код создания VIEW.

```SQL 
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
```
1.4.2. Напишите DDL-запрос для создания витрины.**
Далее вам необходимо создать витрину. Напишите CREATE TABLE запрос и выполните его на предоставленной базе данных в схеме analysis.

```SQL
create table analysis.dm_rfm_segments (
    user_id int primary key,
    recency smallint check(recency>0
	and recency <= 5),
    frequency smallint check(frequency>0
	and recency <= 5),
    monetary_value smallint check(monetary_value>0
	and monetary_value <= 5)
);
```


1.4.3. Напишите SQL запрос для заполнения витрины
Наконец, реализуйте расчет витрины на языке SQL и заполните таблицу, созданную в предыдущем пункте.

Для решения предоставьте код запроса.

```SQL

create table analysis.tmp_rfm_recency (
 user_id INT not null primary key,
 recency INT not null check(recency >= 1
and recency <= 5)
);

create table analysis.tmp_rfm_frequency (
 user_id INT not null primary key,
 frequency INT not null check(frequency >= 1
and frequency <= 5)
);

create table analysis.tmp_rfm_monetary_value (
 user_id INT not null primary key,
 monetary_value INT not null check(monetary_value >= 1
and monetary_value <= 5)
);

with pivot_table as (
select
	user_id,
	MAX(order_ts) as last_order,
	SUM("cost") as total_amount,
	COUNT(order_id) as order_quantity
from
	analysis.orders
where
	status = 'Closed'
group by
	user_id)

insert
	into
	analysis.dm_rfm_segments
select
	analysis.users.id as user_id,
	ntile(5) over (
	order by (case
		when last_order is null then (
		select
			min(last_order)
		from
			pivot_table)
		else last_order
	end) asc) as recency,
	ntile(5) over (
	order by (case
		when total_amount is null then (
		select
			min(total_amount)
		from
			pivot_table)
		else total_amount
	end) asc) as monetary_value,
	ntile(5) over (
	order by (case
		when order_quantity is null then (
		select
			min(order_quantity)
		from
			pivot_table)
		else order_quantity
	end) asc) as frequency
from pivot_table
right join analysis.users on
pivot_table.user_id = analysis.users.id
order by
analysis.users.id;

select *
from analysis.dm_rfm_segments;
```
## 2. Доработка представлений.

``` Sql
create or replace view analysis.orders as 
(
select 
    po.order_id,
    po.order_ts,
    po.user_id,
    po.bonus_payment,
    po.payment,
    po.cost,
    po.bonus_grant,
    subq.last_status AS status
from production.orders AS po
left join 
	(
    select slog.order_id, stat.key as last_status
    from (
        select order_id, max(dttm) as last_status_update
        from production.orderstatuslog
        group by order_id) as slog
    left join production.orderstatuslog on slog.order_id=production.orderstatuslog.order_id and slog.last_status_update=production.orderstatuslog.dttm 
    left join production.orderstatuses as stat on orderstatuslog.status_id=stat.id) as subq
on po.order_id=subq.order_id
where po.order_ts >='2022-01-01');
```



