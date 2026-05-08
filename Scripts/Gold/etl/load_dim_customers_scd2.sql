--=========================================================
-- ETL SCRIPT: LOAD DIM_CUSTOMERS (SCD2)
-- Layer     : Gold
-- Source    : silver.crm_cust_info    (master customer data)
--             silver.erp_CUST_AZ12   (birthdate + gender)
--             silver.erp_LOC_A101    (country)
-- Target    : gold.dim_customers
-- Strategy  : Slowly Changing Dimension Type 2 (SCD2)
--             New versions are inserted on attribute change.
--             Old versions are expired (end_date + is_current).
-- Run order : 1 of 3 — must run BEFORE load_dim_products
--                       and BEFORE load_fact_sales
--=========================================================


--=========================================================
-- STEP 1: Build source dataset from Silver Layer
-- Purpose : Extract and join customer data from all three
--           Silver tables into one clean, flat temp table
--           that will be reused in both STEP 2 and STEP 3.
-- Why temp table instead of CTE:
--           A CTE cannot be shared across multiple statements.
--           Using a temp table means the Silver JOIN runs
--           only once — not twice — which is more efficient
--           and guarantees both steps see identical data.
--=========================================================
DROP TABLE IF EXISTS #source_customers;
-- Reason: Ensures no leftover temp table from a previous
--         failed run causes a conflict on this execution

SELECT
    ci.st_id                AS customer_id,
    -- Source : crm_cust_info.st_id
    -- Maps to: gold.dim_customers.customer_id (INT)
    -- Purpose: Business key from the CRM source system
    --          Used to match records between Silver and Gold

    ci.cst_key              AS customer_number,
    -- Source : crm_cust_info.cst_key
    -- Maps to: gold.dim_customers.customer_number (NVARCHAR 50)
    -- Purpose: Natural identifier visible to business users

    ci.cst_firstname        AS first_name,
    -- Source : crm_cust_info.cst_firstname
    -- Maps to: gold.dim_customers.first_name (NVARCHAR 50)
    -- Purpose: Customer first name — tracked for SCD2 changes

    ci.cst_lastname         AS last_name,
    -- Source : crm_cust_info.cst_lastname
    -- Maps to: gold.dim_customers.last_name (NVARCHAR 50)
    -- Purpose: Customer last name — tracked for SCD2 changes

    la.cntry                AS country,
    -- Source : erp_LOC_A101.cntry (resolved via JOIN on cid)
    -- Maps to: gold.dim_customers.country (NVARCHAR 50)
    -- Purpose: Customer country — tracked for SCD2 changes
    -- Why JOIN: Location data lives in a separate ERP table

    ci.cst_marital_status   AS marital_status,
    -- Source : crm_cust_info.cst_marital_status
    -- Maps to: gold.dim_customers.marital_status (NVARCHAR 50)
    -- Purpose: Marital status — tracked for SCD2 changes

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        -- Rule: If CRM has a real gender value, use it.
        --       CRM is the master/authoritative source.
        ELSE COALESCE(ca.GEN, 'n/a')
        -- Rule: If CRM gender is 'n/a', fall back to ERP.
        --       If ERP is also NULL, default to 'n/a'.
    END                     AS gender,
    -- Maps to: gold.dim_customers.gender (NVARCHAR 10)
    -- Purpose: Gender — tracked for SCD2 changes

    ci.cst_create_date      AS create_date,
    -- Source : crm_cust_info.cst_create_date
    -- Maps to: gold.dim_customers.create_date (DATE)
    -- Purpose: Original account creation date from CRM
    --          Not tracked for SCD2 — this value never changes

    ca.bdate                AS birthdate
    -- Source : erp_CUST_AZ12.bdate (resolved via JOIN on cid)
    -- Maps to: gold.dim_customers.birthdate (DATE)
    -- Purpose: Customer date of birth for age-based analysis
    --          Not tracked for SCD2 — this value never changes

INTO #source_customers
-- Materialises the result into a temp table in tempdb
-- Reused in STEP 2 (UPDATE) and STEP 3 (INSERT)

FROM silver.crm_cust_info ci
-- Primary source: CRM customer master
-- One row per active customer from the CRM system

LEFT JOIN silver.erp_CUST_AZ12 ca
    ON ci.cst_key = ca.cid
-- Join type : LEFT JOIN — keeps all CRM customers even if
--             no matching ERP record exists (birthdate and
--             gender from ERP will be NULL for those rows)
-- Join key  : cst_key = cid (customer natural key)
-- Purpose   : Enriches with birthdate and ERP gender fallback

LEFT JOIN silver.erp_LOC_A101 la
    ON ci.cst_key = la.cid;
-- Join type : LEFT JOIN — keeps all customers even if no
--             location record exists (country will be NULL)
-- Join key  : cst_key = cid (customer natural key)
-- Purpose   : Resolves country from the ERP location table


--=========================================================
-- STEP 2: Expire changed customer records (SCD2 close)
-- Purpose : For every customer whose tracked attributes have
--           changed since the last load, mark their current
--           Gold record as inactive by setting:
--             end_date   = today  (validity period closed)
--             is_current = 0      (no longer the live record)
-- This preserves the full history — the old record stays in
-- the table but is no longer the active version.
--=========================================================
UPDATE d
SET
    d.end_date   = GETDATE(),
    -- Sets the end of this record's validity to right now.
    -- Combined with start_date, this gives a full date range
    -- for every historical version of the customer.

    d.is_current = 0
    -- Marks this record as historical (inactive).
    -- fact_sales always joins on is_current = 1, so this
    -- record will no longer be picked up in new fact loads.

FROM gold.dim_customers d
-- Target: the Gold dimension table

JOIN #source_customers s
    ON d.customer_id = s.customer_id
-- Match Gold records to their Silver counterpart
-- using the business key (customer_id)

WHERE d.is_current = 1
-- Only evaluate currently active records.
-- Historical records (is_current = 0) are already expired
-- and should never be touched again.

  AND (
        ISNULL(d.country,        '') <> ISNULL(s.country,        '')
     -- Detects country change. ISNULL(...,'') normalises NULLs
     -- so that NULL vs NULL is treated as equal (no change)
     -- and NULL vs 'Egypt' is treated as a real change.

     OR ISNULL(d.marital_status, '') <> ISNULL(s.marital_status, '')
     -- Detects marital status change

     OR ISNULL(d.gender,         '') <> ISNULL(s.gender,         '')
     -- Detects gender change

     OR ISNULL(d.first_name,     '') <> ISNULL(s.first_name,     '')
     -- Detects first name change

     OR ISNULL(d.last_name,      '') <> ISNULL(s.last_name,      '')
     -- Detects last name change
  );
-- Any ONE of the above changes triggers a new SCD2 version.
-- birthdate and create_date are intentionally excluded —
-- they are immutable facts that should never change.


--=========================================================
-- STEP 3: Insert new and updated customer versions
-- Purpose : Insert two types of records:
--           1. New customers — appear in Silver but have
--              no record at all in Gold yet
--           2. Changed customers — their old Gold record
--              was just expired in STEP 2; a fresh version
--              with updated attributes is inserted here
-- After this step every customer has exactly one record
-- with is_current = 1 in gold.dim_customers.
--=========================================================
INSERT INTO gold.dim_customers
(
    customer_id,      -- Business key from CRM
    customer_number,  -- Natural identifier
    first_name,       -- Customer first name
    last_name,        -- Customer last name
    country,          -- Customer country
    marital_status,   -- Marital status
    gender,           -- Resolved gender (CRM preferred, ERP fallback)
    create_date,      -- Original CRM account creation date
    birthdate,        -- Date of birth from ERP
    start_date,       -- SCD2: start of this version's validity
    end_date,         -- SCD2: end of validity (NULL = still active)
    is_current        -- SCD2: 1 = live record, 0 = historical
)
SELECT
    s.customer_id,
    -- Source: #source_customers.customer_id
    -- Maps to: gold.dim_customers.customer_id (INT)

    s.customer_number,
    -- Source: #source_customers.customer_number
    -- Maps to: gold.dim_customers.customer_number (NVARCHAR 50)

    s.first_name,
    -- Source: #source_customers.first_name
    -- Maps to: gold.dim_customers.first_name (NVARCHAR 50)

    s.last_name,
    -- Source: #source_customers.last_name
    -- Maps to: gold.dim_customers.last_name (NVARCHAR 50)

    s.country,
    -- Source: #source_customers.country
    -- Maps to: gold.dim_customers.country (NVARCHAR 50)

    s.marital_status,
    -- Source: #source_customers.marital_status
    -- Maps to: gold.dim_customers.marital_status (NVARCHAR 50)

    s.gender,
    -- Source: #source_customers.gender
    -- Maps to: gold.dim_customers.gender (NVARCHAR 10)

    s.create_date,
    -- Source: #source_customers.create_date
    -- Maps to: gold.dim_customers.create_date (DATE)

    s.birthdate,
    -- Source: #source_customers.birthdate
    -- Maps to: gold.dim_customers.birthdate (DATE)

    GETDATE(),
    -- Maps to: gold.dim_customers.start_date (DATE)
    -- Purpose: Marks when this version became active.
    --          For new customers this is their first-ever record.
    --          For changed customers this is when the change
    --          was detected and the new version was created.

    NULL,
    -- Maps to: gold.dim_customers.end_date (DATE)
    -- Purpose: NULL means this record is currently active.
    --          It will be filled in by STEP 2 on a future run
    --          if this customer's attributes change again.

    1
    -- Maps to: gold.dim_customers.is_current (BIT)
    -- Purpose: Flags this as the live, queryable record.
    --          fact_sales joins on is_current = 1 to always
    --          link transactions to the correct customer version.

FROM #source_customers s

LEFT JOIN gold.dim_customers d
    ON  s.customer_id = d.customer_id
    AND d.is_current  = 1
-- Join type : LEFT JOIN — we want ALL source customers,
--             including those with no Gold match yet.
-- Join key  : business key + is_current = 1 ensures we
--             compare against the active Gold record only.

WHERE
    d.customer_id IS NULL
    -- Case 1: No matching Gold record found (new customer).
    -- The LEFT JOIN returned NULL for all Gold columns,
    -- meaning this customer has never been loaded before.

    OR
    (
           ISNULL(d.country,        '') <> ISNULL(s.country,        '')
        OR ISNULL(d.marital_status, '') <> ISNULL(s.marital_status, '')
        OR ISNULL(d.gender,         '') <> ISNULL(s.gender,         '')
        OR ISNULL(d.first_name,     '') <> ISNULL(s.first_name,     '')
        OR ISNULL(d.last_name,      '') <> ISNULL(s.last_name,      '')
    );
    -- Case 2: Existing customer with at least one changed attribute.
    -- Their old record was expired in STEP 2.
    -- This INSERT creates the new current version.
    -- Change detection logic is identical to STEP 2 to guarantee
    -- every expired record gets exactly one new version inserted.


--=========================================================
-- STEP 4: Cleanup
-- Purpose : Remove the temp table from tempdb.
--           Good practice to always clean up explicitly
--           even though SQL Server drops temp tables
--           automatically at end of session.
--=========================================================
DROP TABLE IF EXISTS #source_customers;
-- Reason: Frees tempdb space and avoids confusion if the
--         script is run multiple times in the same session.
