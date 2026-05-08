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
