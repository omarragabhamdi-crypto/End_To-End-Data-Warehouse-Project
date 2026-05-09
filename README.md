
📌 Project Title :
( **Enhanced-Enterprise-Data-Warehouse-SCD2-StarSchema** )
______________________________________________________________________________
📖 Project Description 

Welcome to the The Data Warehouse Project :

This project demonstrates a complete End-to-End Data Engineering pipeline , starting from raw data ingestion to building a fully structured Data Warehouse and generating actionable business insights,
Designed as a portfolio project , it highlights industry best practices in data engineering .

"I designed the pipeline following Data Modeling lifecycle:
starting from conceptual understanding of business entities ,
then logical structuring of relationships ,
and finally implementing a physical star schema in the Gold layer.
The ETL pipeline transforms raw data into dimension and fact tables
with proper data quality checks..>>

______________________________________________________________________________
🏗️ Data Architecture...
The data architecture for this project follows Medallion Architecture Bronze, Silver, and Gold layers: 
<img width="1444" height="1089" alt="ChatGPT Image May 9, 2026, 01_30_54 AM" src="https://github.com/user-attachments/assets/da348564-8361-426d-b87e-4c4be62e6ebc" />

data_model.drawio...
<img width="1728" height="910" alt="3f780b35-6c80-4e3b-8bb1-3684478fc8aa" src="https://github.com/user-attachments/assets/cf6dac66-53ed-45d6-a11b-f8fd0a9cda1d" />

📝Project Requirements

Building the Data Warehouse (Data Engineering)

Objective
Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

Specifications
Data Sources: Import data from two source systems (ERP and CRM) provided as CSV files.
Data Quality: Cleanse and resolve data quality issues prior to analysis.
Integration: Combine both sources into a single, user-friendly data model designed for analytical queries.
Scope: Focus on the latest dataset only; historization of data is not required.
Documentation: Provide clear documentation of the data model to support both business stakeholders and analytics teams.

____________________________________________________________________________
🚩Repository Structure
## Project Structure
```
data-engineering-project/
│
├── datasets/                           # Source datasets (CSV, ERP, CRM, APIs, etc.)
│   ├── raw/                            # Original raw data before processing
│   ├── staging/                        # Temporary/staging datasets
│   └── processed/                      # Cleaned or transformed datasets
│
├── docs/                               # Project documentation and architecture
│   ├── business_requirements.md        # Business problem and project goals
│   ├── data_architecture.drawio        # Overall architecture diagram
│   ├── data_models.drawio              # Star schema / snowflake schema diagrams
│   ├── data_catalog.md                 # Metadata and column descriptions
│   ├── naming_conventions.md           # Naming standards for tables/files
│   ├── pipeline_design.md              # ETL pipeline explanation
│   └── quality_checks.md               # Data quality rules and validation logic
│
├── scripts/                            # SQL/Python ETL scripts
│   ├── bronze/                         # Extract & raw loading scripts
│   │   ├── ddl_bronze.sql
│   │   └── proc_load_bronze.sql
│   │
│   ├── silver/                         # Cleaning, standardization, validation
│   │   ├── ddl_silver.sql
│   │   ├── proc_clean_data.sql
│   │   └── proc_validate_data.sql
│   │
│   ├── gold/                           # Business-ready analytical layer
│   │   ├── ddl_gold.sql
│   │   ├── dim_customers.sql
│   │   ├── dim_products.sql
│   │   ├── fact_sales.sql
│   │   └── analytical_views.sql
│   │

│
├── tests/                              # Testing and validation scripts
│   ├── data_quality_tests.sql
│   ├── duplicate_checks.sql
│   ├── null_checks.sql
│   └── reconciliation_tests.sql
│
├── dashboards/                         # Power BI / Tableau screenshots or files
│   ├── sales_dashboard.png
│   └── customer_insights.png
│
├── automation/                         # Scheduling and orchestration
│   ├── airflow_dag.py
│   └── sql_agent_jobs.md
│
├── screenshots/                        # Project screenshots for README
│
├── README.md                           # Full project overview
├── requirements.txt                    # Python dependencies

____________________________________________________________________________

🎯 Objectives
Design and implement a scalable Data Warehouse architecture
Transform raw data into clean , reliable, and analysis-ready datasets
Apply data modeling techniques (Star Schema)
Perform data analysis to extract meaningful insights
Simulate real-world Data Engineering workflows
______________________________________________________________________________
🏗️ Architecture Overview
   ETL / ELT Process
1. Extract
Ingest raw data from multiple sources

2. Validate & Clean
Handle missing values
Remove duplicates
Standardize formats

3. Transform
Apply business rules
Create derived columns
Build fact & dimension tables

4. Load
Load processed data into the Data Warehouse
📊 Data Modeling
Implemented Star Schema
Fact Table: stores transactional data
Dimension Tables: store descriptive attributes

📈 Analysis & Insights
Identified key business KPIs
Performed trend analysis
Generated insights to support decision-making

🚀 Key Features
End-to-End pipeline (Raw → Insights)
Data Quality validation layer
Scalable and modular design
Ready for BI integration 
