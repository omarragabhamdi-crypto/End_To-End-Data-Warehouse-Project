----------------------------------------------------------
-- VALIDATION: CUSTOMER DIMENSION
----------------------------------------------------------
---------------------------------------------------------
-- Check total rows
----------------------------------------------------------
SELECT COUNT(*) AS total_customers
FROM gold.dim_customers;
----------------------------------------------------------
-- Check duplicate current customers
----------------------------------------------------------
SELECT
	customer_id,
	COUNT(*)
FROM gold.dim_customers
WHERE is_current = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;
----------------------------------------------------------
-- Check NULL business keys
----------------------------------------------------------
SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;
