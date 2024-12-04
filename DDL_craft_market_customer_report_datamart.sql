DROP TABLE IF EXISTS dwh.customer_report_datamart;
create table dwh.customer_report_datamart(
	id int8 GENERATED ALWAYS AS IDENTITY NOT NULL,
	customer_id int8 NOT NULL,
	customer_name varchar NOT NULL,
	customer_address varchar NOT NULL,
	customer_birthday date NOT NULL,
	customer_email varchar NOT NULL,
	customer_money numeric(15, 2) NOT NULL,
	platform_money int8 NOT NULL,
	count_order int8 NOT NULL,
	avg_price_order numeric(10, 2) NOT NULL,
	median_time_order_completed numeric(10, 1) NULL,
	top_product_category varchar NOT NULL,
	top_craftsman_id int8 NOT NULL,
	count_order_created int8 NOT NULL,
	count_order_in_progress int8 NOT NULL,
	count_order_delivery int8 NOT NULL,
	count_order_done int8 NOT NULL,
	count_order_not_done int8 NOT NULL,
	report_period varchar NOT NULL,
	CONSTRAINT customer_report_datamart_pk PRIMARY KEY (id)
);

COMMENT ON TABLE dwh.customer_report_datamart IS 'Основная сводка по заказчикам';
COMMENT ON COLUMN dwh.customer_report_datamart.id IS 'идентификатор записи';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_id IS 'идентификатор заказчика';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_name IS 'Ф. И. О. заказчика';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_address IS 'адрес заказчика';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_birthday IS 'дата рождения заказчика';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_email IS 'электронная почта заказчика';
COMMENT ON COLUMN dwh.customer_report_datamart.customer_money IS 'сумма, которую потратил заказчик';
COMMENT ON COLUMN dwh.customer_report_datamart.platform_money IS 'сумма, которую заработала платформа от покупок заказчика за месяц (10% от суммы, которую потратил заказчик)';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order IS 'количество заказов у заказчика за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.avg_price_order IS 'средняя стоимость одного заказа у заказчика за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.median_time_order_completed IS 'медианное время в днях от момента создания заказа до его завершения за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.top_product_category IS 'самая популярная категория товаров у этого заказчика за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.top_craftsman_id IS 'идентификатор самого популярного мастера ручной работы у заказчика.';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order_created IS 'количество созданных заказов за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order_in_progress IS 'количество заказов в процессе изготовки за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order_delivery IS 'количество заказов в доставке за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order_done IS 'количество завершённых заказов за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.count_order_not_done IS 'количество незавершённых заказов за месяц';
COMMENT ON COLUMN dwh.customer_report_datamart.report_period IS 'отчётный период, год и месяц';
