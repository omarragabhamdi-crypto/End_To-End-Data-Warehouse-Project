--CRAETE TABLE 'gold.dim_customers'
----------------------------------------------------------
-- STEP 0: Rebuild Dim Table (Safe Reset) 
-- Purpose:
-- Ensure clean table structure every run
-- Useful in development / testing environments
----------------------------------------------------------
DROP TABLE IF EXISTS gold.dim_customers;
-- Reason: Removes old table to avoid schema conflicts or stale data

CREATE TABLE gold.dim_customers
(
	customer_key INT IDENTITY(1,1),   -- Surrogate key (internal DW key)
	customer_id INT,                 -- Business key from source system
	customer_number NVARCHAR(50),    -- Natural customer identifier
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	country NVARCHAR(50),
	marital_status NVARCHAR(50),
	gender NVARCHAR(10),
	create_date DATE,
	birthdate DATE,
	start_date DATE,                 -- SCD2 start validity date
	end_date DATE,                   -- SCD2 end validity date
	is_current BIT                   -- Flag for active record
);
-- Reason: We rebuild the table to guarantee correct schema for SCD2 design






----------------------------------------------------------
-- DDL SCRIPT: CREATE PRODUCT DIMENSION
-- Purpose:
-- Create Product Dimension Table
----------------------------------------------------------

DROP TABLE IF EXISTS gold.dim_products;
-- Reason:
-- Rebuild clean dimension structure
CREATE TABLE gold.dim_products
(
	product_key INT IDENTITY(1,1),
	-- Surrogate Key
	product_id INT,
	-- Business Product ID
	product_number NVARCHAR(50),
	product_name NVARCHAR(100),
	category NVARCHAR(50),
	subcategory NVARCHAR(50),
	cost DECIMAL(10,2),
	product_line NVARCHAR(50),
	start_date DATE DEFAULT GETDATE(),
	end_date DATE NULL,
	is_current BIT DEFAULT 1
);
-- Reason:
-- Physical dimension table required for stable surrogate key lookups





-- -------------------------------------
-- Create Dimension: gold.dim_products
-- -------------------------------------

CREATE VIEW gold.dim_products AS 
SELECT 
ROW_NUMBER () OVER (ORDER BY prd_id) AS product_key, --Surrogate key
pn.prd_id AS product_id,
pn.prd_key As product_number,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
pc.CAT AS category,
pc.SUBCAT subcategory,
pc.MAINTENANCE AS maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_PX_CAT_G1V2 pc
ON pn.cat_id = pc.id

WHERE prd_end_dt IS NULL --Filter out all historical data


-- -------------------------------------
-- Create Dimension: gold.fact_sales
-- -------------------------------------
CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd 
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id =cu.customer_id


