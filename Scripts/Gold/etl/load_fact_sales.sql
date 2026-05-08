----------------------------------------------------------
-- ETL SCRIPT: LOAD FACT SALES
-- Purpose:
-- Load transactional sales into Star Schema
----------------------------------------------------------
;WITH sales_source AS
(
	SELECT
		sls_ord_num,
		sls_cust_id,
		sls_prd_key,
		sls_order_dt,
		sls_sales,
		sls_quantity
	FROM silver.crm_sales_details
	WHERE sls_sales IS NOT NULL
)

----------------------------------------------------------
-- Insert Fact Records
----------------------------------------------------------

INSERT INTO gold.fact_sales
(
	order_number,
	customer_key,
	product_key,
	order_date,
	sales_amount,
	quantity
)
SELECT
	s.sls_ord_num,
	dc.customer_key,
	dp.product_key,
	s.sls_order_dt,
	s.sls_sales,
	s.sls_quantity
FROM sales_source s

----------------------------------------------------------
-- Customer SCD2 Lookup
----------------------------------------------------------

JOIN gold.dim_customers dc
	ON s.sls_cust_id = dc.customer_id
	AND dc.is_current = 1

----------------------------------------------------------
-- Product Lookup
----------------------------------------------------------

JOIN gold.dim_products dp
	ON s.sls_prd_key = dp.product_number;
