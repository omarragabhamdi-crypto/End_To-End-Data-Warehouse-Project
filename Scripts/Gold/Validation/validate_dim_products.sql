----------------------------------------------------------
-- VALIDATION: PRODUCT DIMENSION
----------------------------------------------------------
SELECT COUNT(*) AS total_products
FROM gold.dim_products;
----------------------------------------------------------
-- Check duplicate products
----------------------------------------------------------
SELECT
	product_number,
	COUNT(*)
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;
---------------------------------------------------------
-- Check NULL product keys
-
SELECT *
FROM gold.dim_products
WHERE product_number IS NULL;
