# Retail Sales & Customer Analytics

An end-to-end data analytics project that transforms more than one million retail transaction records into actionable sales, product, country, and customer insights using **MySQL** and **Power BI**.

## Project Overview

The project analyzes transactions from a UK-based online retailer between **December 2009 and December 2011**. It examines sales performance, cancellations and returns, product demand, geographical performance, and customer behavior.

The analysis also applies **RFM segmentation**—Recency, Frequency, and Monetary value—to group customers into meaningful business segments.

## Business Objectives

- Measure gross sales, returns, and net sales.
- Identify monthly sales trends and seasonal patterns.
- Compare country-level sales performance.
- Find the highest-performing products.
- Measure customer activity and purchase frequency.
- Segment customers using RFM analysis.
- Identify valuable, inactive, at-risk, and one-time buyers.

## Tools Used

- **MySQL:** Data cleaning, validation, transformation, KPI calculations, and RFM analysis
- **Power BI:** Data modelling, DAX measures, dashboard creation, and interactive reporting
- **Power Query:** Data type correction and report-ready transformation
- **Microsoft Excel/TSV:** Source-data storage and initial inspection
- **GitHub:** Project documentation and version control

## Dataset

- **Dataset:** Online Retail II
- **Source:** UCI Machine Learning Repository
- **Period covered:** December 2009 to December 2011
- **Transaction rows:** Approximately 1.04 million
- **Main fields:** Invoice, stock code, description, quantity, invoice date, unit price, customer ID, and country
- **Source page:** https://doi.org/10.24432/C5CG6D

The full raw dataset is not included in this repository because of its size. Download it from the source above and follow the SQL workflow to reproduce the analysis.

## Data Preparation

The MySQL workflow included:

1. Importing the transaction data from a TSV file.
2. Correcting column data types.
3. Trimming and standardizing text fields.
4. Identifying duplicate records.
5. Separating purchases from cancellations and returns.
6. Reviewing non-product entries such as postage, fees, discounts, and manual adjustments.
7. Creating signed sales values for correct net-sales calculations.
8. Matching cancellations with their related purchases where possible.
9. Creating reusable views for Power BI.
10. Building customer-level RFM scores and segments.

## Main KPIs

| KPI | Result |
| --- | ---: |
| Transaction rows | 1,037,021 |
| Gross sales | £20,110,181.02 |
| Returns/cancellations | £726,555.99 |
| Net sales | £19,383,625.03 |
| Identified customers | 5,852 |
| Countries | 43 |

## Dashboard Pages

### 1. Sales Overview

- Gross sales
- Return value
- Net sales
- Monthly net-sales trend
- Return-rate analysis
- Full-month and partial-month identification

### 2. Country Analysis

- Gross, returned, and net sales by country
- Country ranking by net sales
- International market contribution
- High-return and negative-net-sales markets

### 3. Product Analysis

- Top products by net sales
- Net units sold
- Product descriptions and stock codes
- Review of non-product and adjustment records

### 4. Customer Analysis

- Total identified customers
- Customer frequency and monetary value
- RFM scores
- Customer segment distribution
- Segment contribution to net sales

## Customer Segmentation

| Segment | Customers | Net sales | Average recency | Average frequency |
| --- | ---: | ---: | ---: | ---: |
| Champions | 487 | £9,343,902.68 | 19.1 days | 30.0 |
| Active repeat buyers | 1,124 | £3,157,358.36 | 30.9 days | 8.8 |
| Other buyers | 1,492 | £1,906,050.03 | 74.2 days | 3.7 |
| At risk | 311 | £1,089,184.70 | 332.8 days | 8.3 |
| Inactive buyers | 2,058 | £1,086,769.87 | 434.5 days | 1.7 |
| Recent one-time buyers | 360 | £135,953.64 | 45.0 days | 1.0 |
| Review net credits | 20 | -£3,036.75 | 302.5 days | 1.1 |

## Key Insights

- The **United Kingdom** generated most of the project's net sales, followed by EIRE, the Netherlands, Germany, and France.
- **November 2011** recorded the highest complete-month net sales at approximately **£1.43 million**.
- December 2011 is a partial month ending on December 9 and should not be compared directly with complete months.
- **REGENCY CAKESTAND 3 TIER** was the leading product by net sales.
- Champions represented a relatively small customer group but generated the largest share of identified-customer revenue.
- More than 2,000 customers were classified as inactive, creating an opportunity for re-engagement campaigns.
- Customer `16446` contained an unusually large purchase and cancellation pair; matching the two transactions prevented distorted customer rankings.
- Nigeria recorded slightly negative net sales, meaning its return value exceeded its purchase value during the period.

## Recommended Business Actions

- Protect and reward Champion customers with loyalty benefits and early product access.
- Run targeted reactivation campaigns for At-risk and Inactive buyers.
- Encourage Recent one-time buyers to make a second purchase through personalized offers.
- Maintain inventory availability for consistently high-performing products.
- Investigate countries and products with unusually high return rates.
- Exclude administrative charges and manual adjustments when reporting product performance.

## Repository Contents

```text
retail-sales-customer-analytics/
├── README.md
├── Retail_Analytics_Dashboard.pbix.zip
├── Retail_Analytics_Final_SQL.sql
├── Retail_Analytics_Project_Guide.docx
└── screenshots/
    ├── sales-overview.png
    ├── country-analysis.png
    ├── product-analysis.png
    └── customer-analysis.png
```

## How to Use This Project

1. Download the Online Retail II dataset from the source link.
2. Import the transaction file into MySQL.
3. Open and execute `Retail_Analytics_Final_SQL.sql`.
4. Refresh the data source in Power BI if required.
5. Open the dashboard file to explore the interactive report.

## Important Notes

- Negative quantities and invoice numbers beginning with `C` indicate cancellations or returns.
- Net sales equal gross purchase value minus return/cancellation value.
- Missing customer IDs are included in overall sales but excluded from customer segmentation.
- December 2011 contains only nine days of data.
- RFM segment definitions are business rules created for this project and can be adjusted for other use cases.

## Author

**Tarun Hari Krishna Kollipara**  
Aspiring Data Analyst

---

If you find this project useful, consider starring the repository.
