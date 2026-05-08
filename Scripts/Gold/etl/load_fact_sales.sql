--=========================================================
-- ETL SCRIPT: LOAD FACT_SALES
-- Layer     : Gold
-- Source    : silver.crm_sales_details
-- Target    : gold.fact_sales
-- Depends on: gold.dim_customers  (must be loaded first)
--             gold.dim_products   (must be loaded first)
-- Strategy  : TRUNCATE + INSERT (full reload every run)
-- Run order : 3 of 3 — must run AFTER both dimension loads
--=========================================================


--=========================================================
-- STEP 1: Safe Reset — Clear existing fact data
-- Purpose : Remove all rows from the fact table before
--           reloading so we never end up with duplicates.
-- Why TRUNCATE instead of DELETE:
--           TRUNCATE is faster — it deallocates data pages
--           instead of logging individual row deletions.
--           It also resets the IDENTITY counter on sales_key
--           so surrogate keys are consistent across runs.
-- Prerequisite: dim_customers and dim_products must already
--           be fully loaded before this step runs, because
--           STEP 3 looks up surrogate keys from those tables.
--=========================================================
TRUNCATE TABLE gold.fact_sales;
-- Reason: Guarantees no duplicate transactions exist
--         after the reload completes


--=========================================================
-- STEP 2: Extract clean sales transactions from Silver
-- Purpose : Pull only valid, complete sales records from
--           the Silver layer into a CTE that STEP 3 will
--           use to build the final INSERT.
-- Why CTE instead of querying Silver directly in STEP 3:
--           Separates the extraction logic (what to read)
--           from the loading logic (how to join and insert).
--           Makes the script easier to read and maintain.
--=========================================================
;WITH sales_source AS
-- Semicolon before WITH: defensive practice to terminate
-- any previous statement, preventing syntax errors when
-- this script is run as part of a larger batch.
(
    SELECT
        sls_ord_num,
        -- Source : crm_sales_details.sls_ord_num
        -- Purpose: Degenerate dimension — the original order
        --          number carried directly into the fact table
        --          for traceability back to the source system

        sls_cust_id,
        -- Source : crm_sales_details.sls_cust_id
        -- Purpose: Business key used in STEP 3 to look up
        --          the surrogate customer_key from dim_customers

        sls_prd_key,
        -- Source : crm_sales_details.sls_prd_key
        -- Purpose: Natural product key used in STEP 3 to look
        --          up the surrogate product_key from dim_products

        sls_order_dt,
        -- Source : crm_sales_details.sls_order_dt
        -- Purpose: Date the order was placed — used for
        --          time-based sales analysis

        sls_ship_dt,
        -- Source : crm_sales_details.sls_ship_dt
        -- Purpose: Date the order was shipped — used for
        --          fulfilment and lead time analysis
        --          (was missing from original script)

        sls_due_dt,
        -- Source : crm_sales_details.sls_due_dt
        -- Purpose: Date the order was due — used for
        --          on-time delivery analysis
        --          (was missing from original script)

        sls_sales,
        -- Source : crm_sales_details.sls_sales
        -- Purpose: Total sales amount — key measure in the fact

        sls_quantity
        -- Source : crm_sales_details.sls_quantity
        -- Purpose: Number of units sold — key measure in the fact

    FROM silver.crm_sales_details
    -- Primary source: Silver sales transaction table
    -- One row per order line item

    WHERE sls_sales IS NOT NULL
    -- Filter: Exclude incomplete or corrupt rows where
    --         the sales amount was not captured.
    -- Reason : A fact row with NULL sales_amount would
    --          silently distort aggregations and KPIs.
)


--=========================================================
-- STEP 3: Insert fact records with surrogate key resolution
-- Purpose : For every valid sales transaction, look up the
--           correct surrogate keys from the dimension tables
--           and insert one row into gold.fact_sales.
-- Key design decisions:
--   - INNER JOIN on dim_customers: only loads sales where
--     the customer exists in Gold. Unmatched rows are silently
--     dropped — investigate missing customers in Silver.
--   - INNER JOIN on dim_products: same logic for products.
--   - If you want to keep unmatched rows, switch both to
--     LEFT JOIN and add an "Unknown" row (key = -1) to each
--     dimension table as a catch-all.
--=========================================================
INSERT INTO gold.fact_sales
(
    order_number,   -- Degenerate dimension: original order identifier
    customer_key,   -- FK to gold.dim_customers (surrogate key)
    product_key,    -- FK to gold.dim_products  (surrogate key)
    order_date,     -- Date order was placed
    shipping_date,  -- Date order was shipped
    due_date,       -- Date order was due
    sales_amount,   -- Total transaction value DECIMAL(10,2)
    quantity        -- Units sold INT
    -- sales_key is excluded: IDENTITY(1,1) auto-generated by DDL
)
SELECT
    s.sls_ord_num       AS order_number,
    -- Source : sales_source.sls_ord_num
    -- Maps to: gold.fact_sales.order_number (NVARCHAR 50)
    -- Purpose: Preserves the original business transaction ID

    dc.customer_key,
    -- Source : gold.dim_customers.customer_key
    -- Maps to: gold.fact_sales.customer_key (INT)
    -- Purpose: Surrogate key — links fact to the correct
    --          customer dimension record
    -- Resolved via JOIN below on customer_id + is_current = 1

    dp.product_key,
    -- Source : gold.dim_products.product_key
    -- Maps to: gold.fact_sales.product_key (INT)
    -- Purpose: Surrogate key — links fact to the correct
    --          product dimension record
    -- Resolved via JOIN below on product_number

    s.sls_order_dt      AS order_date,
    -- Source : sales_source.sls_order_dt
    -- Maps to: gold.fact_sales.order_date (DATE)

    s.sls_ship_dt       AS shipping_date,
    -- Source : sales_source.sls_ship_dt
    -- Maps to: gold.fact_sales.shipping_date (DATE)
    -- (was missing from original script — left column NULL)

    s.sls_due_dt        AS due_date,
    -- Source : sales_source.sls_due_dt
    -- Maps to: gold.fact_sales.due_date (DATE)
    -- (was missing from original script — left column NULL)

    s.sls_sales         AS sales_amount,
    -- Source : sales_source.sls_sales
    -- Maps to: gold.fact_sales.sales_amount (DECIMAL 10,2)
    -- Purpose: Core financial measure — revenue per transaction

    s.sls_quantity      AS quantity
    -- Source : sales_source.sls_quantity
    -- Maps to: gold.fact_sales.quantity (INT)
    -- Purpose: Volume measure — units sold per transaction

FROM sales_source s

JOIN gold.dim_customers dc
    ON  s.sls_cust_id = dc.customer_id
    -- Match on business key (sls_cust_id = customer_id)
    -- to find the right customer across all SCD2 versions

    AND dc.is_current = 1
    -- SCD2 filter: always link the transaction to the
    -- currently active customer version.
    -- is_current = 0 rows are historical — we never join to them.
    -- Join type: INNER — drops sales with no matching customer.

JOIN gold.dim_products dp
    ON s.sls_prd_key = dp.product_number;
    -- Match on natural product key (sls_prd_key = product_number)
    -- product_number is the stable business identifier (e.g. BK-R50R-44)
    -- product_key (surrogate) is what gets stored in the fact.
    -- Join type: INNER — drops sales with no matching product.
