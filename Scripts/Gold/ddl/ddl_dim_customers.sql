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














