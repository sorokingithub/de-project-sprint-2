drop table if exists dwh.load_dates_customer_report_datamart;
CREATE TABLE dwh.load_dates_customer_report_datamart (
	id int8 GENERATED ALWAYS AS IDENTITY NOT NULL,
	load_dttm timestamp NOT null default now()::timestamp,
	CONSTRAINT load_dates_customer_report_datamart_pk PRIMARY KEY (id)
);
