drop table if exists tmp_dwh_customer_delta;

create temp table tmp_dwh_customer_delta AS
with
--самая недавняя дата загрузки в витрину(для читаемости в самом запросе)
latest_upload_date as(
	SELECT COALESCE(MAX(load_dttm),'1900-01-01') as load_dttm FROM dwh.load_dates_customer_report_datamart
)
--дельта с момента последней загрузки
select
	dcs.customer_id AS customer_id,
    dcs.customer_name AS customer_name,
    dcs.customer_address AS customer_address,
    dcs.customer_birthday AS customer_birthday,
    dcs.customer_email AS customer_email,
    dc.craftsman_id AS craftsman_id,
    fo.order_id AS order_id,
    dp.product_id AS product_id,
    dp.product_price AS product_price,
    dp.product_type AS product_type,
    DATE_PART('year', AGE(dcs.customer_birthday)) AS customer_age,
    fo.order_completion_date - fo.order_created_date AS diff_order_date, 
    fo.order_status AS order_status,
    TO_CHAR(fo.order_created_date, 'yyyy-mm') AS report_period,
	dc.load_dttm AS craftsman_load_dttm,
    dcs.load_dttm AS customers_load_dttm,
    dp.load_dttm AS products_load_dttm
FROM dwh.f_order fo
INNER JOIN dwh.d_craftsman dc ON fo.craftsman_id = dc.craftsman_id
INNER JOIN dwh.d_customer dcs ON fo.customer_id = dcs.customer_id
INNER JOIN dwh.d_product dp ON fo.product_id = dp.product_id
cross join latest_upload_date d 
where d.load_dttm<dc.load_dttm or d.load_dttm<dcs.load_dttm or d.load_dttm<dp.load_dttm
;
--промежуточная проверка
--select count(*) from tmp_dwh_customer_delta;
    
with
--помесячная статистика заказчиков
month_aggr as(
	SELECT 
	    dd.customer_id AS customer_id,
	    dd.customer_name AS customer_name,
        dd.customer_address AS customer_address,
        dd.customer_birthday AS customer_birthday,
        dd.customer_email AS customer_email,
	    SUM(dd.product_price) AS customer_money,
	    SUM(dd.product_price) * 0.1 AS platform_money,
	    COUNT(order_id) AS count_order,
	    AVG(dd.product_price) AS avg_price_order,
	    --AVG(T1.customer_age) AS avg_age_customer,
	    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY diff_order_date) AS median_time_order_completed,
	    SUM(CASE WHEN dd.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created,
	    SUM(CASE WHEN dd.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress, 
	    SUM(CASE WHEN dd.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery, 
	    SUM(CASE WHEN dd.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done, 
	    SUM(CASE WHEN dd.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
	    dd.report_period AS report_period
	FROM tmp_dwh_customer_delta AS dd
	GROUP BY dd.customer_id
		,dd.report_period
		,dd.customer_name
        ,dd.customer_address
        ,dd.customer_birthday
        ,dd.customer_email
)
--самый популярный товар за месяц у заказчика
,prefered_customers_product_type_of_month as (
	SELECT
        dd.customer_id, 
        first_value(dd.product_type) over (partition by dd.customer_id, dd.report_period order by COUNT(*) desc) as top_product_category,
        dd.report_period,
        COUNT(*) AS count_product
    FROM tmp_dwh_customer_delta AS dd
        GROUP BY dd.customer_id, dd.product_type, dd.report_period
)
--самый популярный мастер вообще у заказчика (в ТЗ месяц не упомянут)
,prefered_customers_craftsman_overall as (
	SELECT
        dd.customer_id, 
        first_value(dd.craftsman_id) over (partition by dd.customer_id order by COUNT(*) desc) as top_craftsman_id,
        COUNT(*) AS count_product
    FROM tmp_dwh_customer_delta AS dd
        GROUP BY dd.customer_id, dd.craftsman_id
)
merge into dwh.customer_report_datamart trg
using 
(
	select
		ma.*
		,ptop.top_product_category
		,ctop.top_craftsman_id
	from month_aggr ma
	join prefered_customers_product_type_of_month ptop on ma.customer_id=ptop.customer_id and ma.report_period=ptop.report_period
	join prefered_customers_craftsman_overall ctop on ma.customer_id=ctop.customer_id
)as src on trg.customer_id=src.customer_id and trg.report_period=src.report_period
when matched then update set
    customer_name = src.customer_name, 
    customer_address = src.customer_address, 
    customer_birthday = src.customer_birthday, 
    customer_email = src.customer_email, 
    customer_money = src.customer_money, 
    platform_money = src.platform_money, 
    count_order = src.count_order, 
    avg_price_order = src.avg_price_order,
    median_time_order_completed = src.median_time_order_completed, 
    top_product_category = src.top_product_category, 
    top_craftsman_id = src.top_craftsman_id, 
    count_order_created = src.count_order_created, 
    count_order_in_progress = src.count_order_in_progress, 
    count_order_delivery = src.count_order_delivery, 
    count_order_done = src.count_order_done,
    count_order_not_done = src.count_order_not_done
when not matched then insert 
(
	id
	, customer_id
	, customer_name
	, customer_address
	, customer_birthday
	, customer_email
	, customer_money
	, platform_money
	, count_order
	, avg_price_order
	, median_time_order_completed
	, top_product_category
	, top_craftsman_id
	, count_order_created
	, count_order_in_progress
	, count_order_delivery
	, count_order_done
	, count_order_not_done
	, report_period
)
values
(
	default
	,src.customer_id
	,src.customer_name
	,src.customer_address
	,src.customer_birthday
	,src.customer_email
	,src.customer_money
	,src.platform_money
	,src.count_order
	,src.avg_price_order
	,src.median_time_order_completed
	,src.top_product_category
	,src.top_craftsman_id
	,src.count_order_created
	,src.count_order_in_progress
	,src.count_order_delivery
	,src.count_order_done
	,src.count_order_not_done
	,src.report_period
);

INSERT INTO dwh.load_dates_customer_report_datamart(
    load_dttm
)
SELECT GREATEST(
	COALESCE(MAX(craftsman_load_dttm), NOW()), 
	COALESCE(MAX(customers_load_dttm), NOW()), 
	COALESCE(MAX(products_load_dttm), NOW())
) 
FROM tmp_dwh_customer_delta;
select count (*) from dwh.customer_report_datamart



