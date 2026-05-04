📌 Project Title :
( **End_To End Data Warehouse Project** )
______________________________________________________________________________
📖 Project Description 

Welcome to the The Data Warehouse Project :

This project demonstrates a complete End-to-End Data Engineering pipeline, starting from raw data ingestion to building a fully structured Data Warehouse and generating actionable business insights,
Designed as a portfolio project, it highlights industry best practices in data engineering and analytics.

______________________________________________________________________________
🏗️ Data Architecture
The data architecture for this project follows Medallion Architecture Bronze, Silver, and Gold layers: 
<img width="1938" height="1449" alt="Screenshot 2026-04-30 233912" src="https://github.com/user-attachments/assets/75e1c8b5-4faf-4e05-9e2b-acc5cd9a871d" />

1-Bronze Layer: Stores raw data as-is from the source systems.
Data is ingested from CSV Files into SQL Server Database.

2-Silver Layer: This layer includes data cleansing, standardization, and normalization processes to prepare data for analysis.

3-Gold Layer: Houses business-ready data modeled into a star schema required for reporting and analytics.
______________________________________________________________________________

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

_____________________________________________________________________________


🚩Repository Structure


data-warehouse-project/

│
├── datasets/                                 # Raw datasets used for the project (ERP and CRM data)

│
├── docs/                               # Project documentation and architecture details

│   ├── etl.drawio                      # Draw.io file shows all different techniquies and methods of 

ETL
│   ├── data_architecture.drawio             # Draw.io file shows the project's architecture

│   ├── data_catalog.md                      # Catalog of datasets, including field descriptions and 

metadata

│   ├── data_flow.drawio                             # Draw.io file for the data flow diagram

│   ├── data_models.drawio                          # Draw.io file for data models (star schema)

│   ├── naming-conventions.md            # Consistent naming guidelines for tables, columns, and files

│

├── scripts/                                       # SQL scripts for ETL and transformations

│   ├── bronze/                                  # Scripts for extracting and loading raw data

│   ├── silver/                                 # Scripts for cleaning and transforming data

│   ├── gold/                                   # Scripts for creating analytical models


│
├── tests/                                      # Test scripts and quality files
 
│
├── README.md                                  # Project overview and instructions


├── LICENSE                                  # License information for the repository

├── .gitignore                              # Files and directories to be ignored by Git

└── requirements.txt                         # Dependencies and requirements for the project


_____________________________________________________________________________

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
