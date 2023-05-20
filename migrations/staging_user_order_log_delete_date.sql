delete from staging.user_order_log where date_time in (
	select date_time 
    from staging.user_order_log uol
	left join mart.d_calendar as dc on uol.date_time::Date = dc.date_actual
	where uol.date_time::Date = '{{ds}}'
)
;