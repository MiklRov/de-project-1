create table analysis.dm_rfm_segments (
    user_id int primary key,
    recency smallint check(recency>0
	and recency <= 5),
    frequency smallint check(frequency>0
	and recency <= 5),
    monetary_value smallint check(monetary_value>0
	and monetary_value <= 5)
);