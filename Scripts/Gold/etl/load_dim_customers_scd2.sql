---------------------------------------------------------
-- Step 1: Extract and prepare customer data from Silver Layer
-- Purpose:
-- Create a clean source dataset to compare against the current Gold dimension
----------------------------------------------------------

WITH source_data AS
(
	SELECT
		ci.st_id AS customer_id,                -- Business Key from CRM system
		ci.cst_key AS customer_number,         -- Customer Number
		ci.cst_firstname AS first_name,        -- Customer First Name
		ci.cst_lastname AS last_name,          -- Customer Last Name
		la.cntry AS country,                   -- Customer Country
		ci.cst_marital_status AS marital_status, -- Marital Status
		CASE
			WHEN ci.cst_gndr != 'n/a'
				THEN ci.cst_gndr
			ELSE COALESCE(ca.GEN, 'n/a')
		END AS gender,                         -- CRM is master source for gender
		ci.cst_create_date AS create_date,     -- Customer creation date
		ca.bdate AS birthdate                  -- Customer birthdate
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_CUST_AZ12 ca
		ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_LOC_A101 la
		ON ci.cst_key = la.cid
)

----------------------------------------------------------
-- Step 2: Close old customer versions
-- Purpose:
-- Detect attribute changes and expire old records
----------------------------------------------------------

UPDATE d
SET
	d.end_date = GETDATE(),      -- Mark end of validity period
	d.is_current = 0             -- Old version is no longer current
FROM gold.dim_customers d
JOIN source_data s
	ON d.customer_id = s.customer_id
WHERE d.is_current = 1
AND (
	ISNULL(d.country,'') <> ISNULL(s.country,'')
	OR
	ISNULL(d.marital_status,'') <> ISNULL(s.marital_status,'')
)

----------------------------------------------------------
-- Step 3: Insert new customer versions
-- Purpose:
-- Insert:
-- 1. New customers
-- 2. Changed customer versions
----------------------------------------------------------

;WITH source_data AS
(
	SELECT
		ci.st_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE
			WHEN ci.cst_gndr != 'n/a'
				THEN ci.cst_gndr
			ELSE COALESCE(ca.GEN, 'n/a')
		END AS gender,
		ci.cst_create_date AS create_date,
		ca.bdate AS birthdate
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_CUST_AZ12 ca
		ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_LOC_A101 la
		ON ci.cst_key = la.cid
)

--:Insert new customer versions

INSERT INTO gold.dim_customers
(
	customer_id,
	customer_number,
	first_name,
	last_name,
	country,
	marital_status,
	gender,
	create_date,
	birthdate,
	start_date,
	end_date,
	is_current
)

SELECT
	s.customer_id,
	s.customer_number,
	s.first_name,
	s.last_name,
	s.country,
	s.marital_status,
	s.gender,
	s.create_date,
	s.birthdate,
	GETDATE(),      -- Start date of current version
	NULL,           -- Current active version has no end date
	1               -- Mark as current active version
FROM source_data s
LEFT JOIN gold.dim_customers d
	ON s.customer_id = d.customer_id
	AND d.is_current = 1
WHERE
	d.customer_id IS NULL
	OR
	(
		ISNULL(d.country,'') <> ISNULL(s.country,'')
		OR
		ISNULL(d.marital_status,'') <> ISNULL(s.marital_status,'')
	)
