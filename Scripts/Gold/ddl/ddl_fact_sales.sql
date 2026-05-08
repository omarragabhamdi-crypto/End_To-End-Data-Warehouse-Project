---------------------------------------------------------
-- STEP 0: Rebuild Fact Table
-- Purpose:
-- Create clean Fact Table structure
-- Fact table stores business transactions
----------------------------------------------------------
DROP TABLE IF EXISTS gold.fact_sales;
-- Reason:
-- Remove old structure before rebuilding
CREATE TABLE gold.fact_sales
(
	sales_key INT IDENTITY(1,1),-- Surrogate key for fact table row
	order_number NVARCHAR(50),  -- Degenerate Dimension  -- Business transaction identifier
	customer_key INT,           -- Foreign key to dim_customers (SCD2)
	product_key INT,            -- Foreign key to dim_products
	order_date DATE,			-- Transaction date
	sales_amount DECIMAL(10,2),	-- Total sales amount
	quantity INT				-- Number of sold items
);
-- Reason:
-- Fact table stores measurable business events
