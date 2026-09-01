# RFM customer segmentation data mart

A data mart that segments the customers of a food delivery service by RFM -
recency, frequency and monetary value.

Each customer gets a score from 1 to 5 on each of the three dimensions, with
customers distributed evenly across segments. For recency, 1 means the customer
has not ordered in a long time and 5 means a recent order; for frequency and
monetary value, 1 is the lowest activity and 5 the highest.

## Contents

| File | Purpose |
|---|---|
| `orders_view.sql`, `views.sql` | source views over the raw tables |
| `recency.sql`, `frequency.sql`, `monetary_value.sql` | the three RFM metrics |
| `datamart_ddl.sql` | data mart schema |
| `datamart_query.sql` | the query that fills it |
| `data_quality.md` | data quality checks and findings |
| `requirements.md` | the original task |

Written in SQL on PostgreSQL.
