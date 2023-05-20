

create table IF NOT EXISTS mart.f_customer_retention(
new_customers_count bigint,
returning_customers_count bigint,
refunded_customer_count bigint,
period_name varchar(20),
period_id date,
item_id bigint,
new_customers_revenue bigint,
returning_customers_revenue bigint,
customers_refunded bigint
)
;


with 
ft as
(
	select s.*, dc.date_actual, dc.first_day_of_week  
	from mart.f_sales s
	left join mart.d_calendar dc on s.date_id =dc.date_id 
)
,returning_customers_count as
(
	select first_day_of_week, item_id, customer_id, count(distinct date_id) ret_cust_cnt
	from ft
	group by 1,2,3
	having count(distinct date_id)>1
)
,returning_customers_count_2 as 
(
	select first_day_of_week, item_id, count(distinct customer_id) ret_cust_cnt
	from returning_customers_count
	group by 1,2 order by 1,2
)
,new_customers_count as 
(
	select first_day_of_week, item_id, customer_id, count(distinct date_id) new_cust_cnt
	from ft
	group by 1,2,3
	having count(distinct date_id)=1
)
,new_customers_count_2 as 
(
	select first_day_of_week, item_id, count(distinct customer_id) new_cust_cnt
	from new_customers_count
	group by 1,2 order by 1,2
)
,new_customers_revenue as 
(
	select n.first_day_of_week, n.item_id, sum(f.payment_amount) as payment_amount
	from new_customers_count n
	left join ft f on f.customer_id =n.customer_id and f.item_id =n.item_id
	and f.first_day_of_week=n.first_day_of_week
	group by 1,2 order by 1,2
)
,returning_customers_revenue as 
(
	select n.first_day_of_week, n.item_id, sum(f.payment_amount) as payment_amount
	from returning_customers_count n
	left join ft f on f.customer_id =n.customer_id and f.item_id =n.item_id
	and f.first_day_of_week=n.first_day_of_week
	group by 1,2 order by 1,2
)
,refunded_customer_count as
(
	select first_day_of_week, item_id, count(distinct customer_id) cust_cnt_ref
	from ft
	where quantity<0
	group by 1,2
)
,customers_refunded as
(
	select first_day_of_week, item_id, customer_id, count(distinct date_id) ref_cnt
	from ft
	where quantity<0
	group by 1,2,3
)
,customers_refunded_2 as
(
	select first_day_of_week, item_id, sum(ref_cnt) as ref_cnt
	from customers_refunded
	group by 1,2
)
,dates as 
(
	select distinct first_day_of_week
	from ft
)
,del as 
(
	delete from mart.f_customer_retention c
	using dates d
	where c.period_id = d.first_day_of_week
)


insert into mart.f_customer_retention

select 
n.new_cust_cnt as new_customers_count
, r.ret_cust_cnt as returning_customers_count
, re.cust_cnt_ref as refunded_customer_count
, 'weekly' as period_name
, d.first_day_of_week as period_id
, di.item_id
, ren.payment_amount as new_customers_revenue 
, ret.payment_amount as returning_customers_revenue
, cr.ref_cnt as customers_refunded 
from dates d
left join mart.d_item di on 1=1
left join new_customers_count_2 n on d.first_day_of_week = n.first_day_of_week and n.item_id = di.item_id
left join returning_customers_count_2 r on d.first_day_of_week = r.first_day_of_week and r.item_id = di.item_id
left join refunded_customer_count re on re.first_day_of_week = d.first_day_of_week and re.item_id = di.item_id
left join new_customers_revenue ren on ren.first_day_of_week = d.first_day_of_week and di.item_id = ren.item_id
left join returning_customers_revenue ret on ret.first_day_of_week = d.first_day_of_week and di.item_id = ret.item_id
left join customers_refunded_2  cr on cr.first_day_of_week = d.first_day_of_week and cr.item_id = di.item_id
order by period_id, item_id
;










