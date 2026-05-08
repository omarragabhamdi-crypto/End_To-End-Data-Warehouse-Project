--=========================================================
-- ETL SCRIPT: LOAD DIM_PRODUCTS
-- Layer     : Gold
-- Source    : silver.crm_prd_info
--             silver.erp_PX_CAT_G1V2
-- Target    : gold.dim_products
-- Strategy  : TRUNCATE + INSERT (full reload every run)
-- Run order : 2 of 3  — must run AFTER load_dim_customers
--                        and BEFORE load_fact_sales
--=========================================================


--=========================================================
-- STEP 1: Safe Reset — Clear existing dimension data
-- Purpose : Remove all existing rows before reloading
--           TRUNCATE is used instead of DELETE because:
--           1. It is faster (no row-by-row logging)
--           2. It resets the IDENTITY counter so
--              product_key surrogate keys start fresh
--              and stay consistent with the source data
-- Note    : TRUNCATE is safe here because fact_sales
--           does NOT have a FK constraint to dim_products
--           (enforced at ETL level, not DB level)
--=========================================================
TRUNCATE TABLE gold.dim_products;
-- Reason: Guarantees a clean slate before every reload


--=========================================================
-- STEP 2: Load current products from Silver Layer
-- Purpose : Insert one row per active product, enriched
--           with category and subcategory from the ERP
--           category reference table
--
-- Columns NOT in INSERT list (handled by DDL defaults):
--   product_key  — IDENTITY(1,1), auto-generated surrogate key
--   start_date   — DEFAULT GETDATE(), set automatically on insert
--   end_date     — DEFAULT NULL, product is currently active
--   is_current   — DEFAULT 1, marks this as the live record
--=========================================================
INSERT INTO gold.dim_products
(
    product_id,      -- Business key from source CRM system
    product_number,  -- Natural product identifier (e.g. BK-R50R-44)
    product_name,    -- Human-readable product name
    category,        -- Resolved category name (e.g. "Bikes")
    subcategory,     -- Resolved subcategory name (e.g. "Road Bikes")
    cost,            -- Product cost as DECIMAL(10,2)
    product_line     -- Product line code (e.g. "R" for Road)
)
SELECT
    pn.prd_id       AS product_id,
    -- Source : crm_prd_info.prd_id
    -- Maps to: gold.dim_products.product_id (INT)
    -- Purpose: Preserves the original business key from CRM

    pn.prd_key      AS product_number,
    -- Source : crm_prd_info.prd_key
    -- Maps to: gold.dim_products.product_number (NVARCHAR 50)
    -- Purpose: Natural key used in fact_sales JOIN

    pn.prd_nm       AS product_name,
    -- Source : crm_prd_info.prd_nm
    -- Maps to: gold.dim_products.product_name (NVARCHAR 100)
    -- Purpose: Descriptive name for reporting

    pc.CAT          AS category,
    -- Source : erp_PX_CAT_G1V2.CAT (resolved via JOIN on cat_id)
    -- Maps to: gold.dim_products.category (NVARCHAR 50)
    -- Purpose: Human-readable category name
    -- Why JOIN: prd_info only stores cat_id (INT foreign key),
    --           the actual name lives in the ERP category table

    pc.SUBCAT       AS subcategory,
    -- Source : erp_PX_CAT_G1V2.SUBCAT
    -- Maps to: gold.dim_products.subcategory (NVARCHAR 50)
    -- Purpose: Drill-down level below category for analysis

    pn.prd_cost     AS cost,
    -- Source : crm_prd_info.prd_cost
    -- Maps to: gold.dim_products.cost (DECIMAL 10,2)
    -- Purpose: Used in margin and profitability calculations

    pn.prd_line     AS product_line
    -- Source : crm_prd_info.prd_line
    -- Maps to: gold.dim_products.product_line (NVARCHAR 50)
    -- Purpose: High-level product grouping for filtering

FROM silver.crm_prd_info pn
-- Primary source: CRM product master table
-- Contains one row per product version (current + historical)

LEFT JOIN silver.erp_PX_CAT_G1V2 pc
    ON pn.cat_id = pc.id
-- Join type : LEFT JOIN keeps products even if category
--             lookup fails — category will be NULL instead
--             of losing the product row entirely
-- Join key  : pn.cat_id matches pc.id (both are category IDs)
-- Purpose   : Resolves category name and subcategory from
--             the ERP reference table

WHERE pn.prd_end_dt IS NULL;
-- Filter : Load ONLY currently active products
-- IS NULL  = no end date = current live version   -> include
-- NOT NULL = has end date = historical/discontinued -> exclude
-- Reason  : Keeps the dimension clean with one row per product
