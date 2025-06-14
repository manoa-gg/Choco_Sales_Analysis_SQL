# [Chocolate Sales Analysis] SQL Analysis Portfolio

## 🚀 Project Overview
| Category          | Description |
|-------------------|-------------|
| **Business Case** | Analyzing sales data from chocolate sales to identify key performance indicators and strategic opportunities for revenue growth. |
| **Data Source**   | Mock chocolate sales dataset |
| **Key Insights**  | Specific products like "Smooth Silky Salty" and "After Nines" show strong sales performance across multiple countries. |

## 🧠 Skills Demonstrated
- **SQL Querying**: Proficient in writing complex SQL queries for data extraction, transformation, and analysis.
- **Data Cleaning**: Expertise in handling missing values, removing duplicates, and standardizing data formats.
- **Data Transformation**: Ability to transform raw data into a structured format suitable for analysis.
- **Statistical Analysis**: Knowledge of statistical methods to analyze data and identify trends (mean, median, mode, standard deviation).
- **Business Insights**: Strong understanding of business metrics and KPIs, and ability to derive actionable insights from data.
- **Strategic Planning**: Capability to translate data insights into strategic recommendations for business growth and operational improvements.

## 📂 File Guide
| File | Purpose | Key Features |
|------|---------|-------------|
| `choco_sales_raw.csv` | Raw dataset | Initial dataset with raw data |
| `choco_sales_cleaned.csv` | Cleaned dataset | Cleaned, transformed, and standardized data |
| `data_prep.sql` | Data preparation | Missing value handling, transformation, deduplication |
| `analysis_queries.sql` | Business insights | Revenue trends, product overview, consumer behavior, store performance |

## 💡 Highlighted Analysis
```sql
# Data Preparation
-- Remove duplicates and handle missing values
with dc As (
    select *,
    row_number() over (
        partition by sales_person, country, product, `date`, amount, boxes_shipped) As row_num
    from choco_sales_1)
delete from choco_sales_1
where transaction_id in (
    select transaction_id
    from dc
    where row_num > 1);

# Data Profiling 
-- Basic data overview
select count(distinct sales_person) as distinct_sales_persons, 
       count(distinct product) as distinct_products, 
       count(distinct country) as distinct_countries
from choco_sales_1;

# Analytics 
-- Monthly Sales Performance
select `month`, count(sales_person) as total_transactions, 
       round(sum(total_price), 2) as monthly_revenue
from choco_sales_2
group by `month`
order by monthly_revenue desc;
