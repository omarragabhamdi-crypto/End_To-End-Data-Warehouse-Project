----------------------------------------------------------
-- ETL SCRIPT: LOAD PRODUCT DIMENSION
-- Purpose:
-- Load Product Dimension from Silver Layer
----------------------------------------------------------
TRUNCATE TABLE gold.dim_products;
-- Reason:
-- Reload clean dimension data
INSERT INTO gold.dim_products
(
	product_id,
	product_number,
	product_name,
	category,
	subcategory,
	cost,
	product_line
)
SELECT
	pn.prd_id,
	-- Business Product ID
	pn.prd_key,
	-- Product Number
	pn.prd_nm,
	-- Product Name
	pn.cat_id,
	-- Product Category
	pn.prd_line,
	-- Product Subcategory / Product Line
	pn.prd_cost,
	-- Product Cost
	pn.prd_line
	-- Product Line
FROM silver.crm_prd_info pn;
-- Reason:
-- Load descriptive product attributes into warehouse dimension
