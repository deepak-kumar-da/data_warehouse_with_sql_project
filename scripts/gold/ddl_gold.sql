/*
====================================================================================
DDL SCRIPTS: Create Gold Views
====================================================================================
Script Purpose:
    This script creates views for the gold layer in the data warehouse.
    The gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs Data Transformation and combines data from Silver layers 
    to produce a clean, enriched and business ready dataset.

Usage: These views can be queried directly for analytics and reporting.
====================================================================================
*/

/* ============================================================================== 
Creating Dimension: gold.dim_customers
============================================================================== */

 -- dropping and creating view
 drop view if exists gold.dim_customers
 go

 create view gold.dim_customers as
 select 
	
	-- organise cst_id by recent date
	ROW_NUMBER() over(order by ci.cst_id) as customer_key,
	
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_first_name as first_name,
	ci.cst_last_name as last_name,
	la.cntry as country,
	ci.cst_marital as marital_status,
	
	-- checking quality of ci.cst_gndr
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr
		 else coalesce(ca.gen,'n/a')
	end as gender,

	ca.bdate as birthdate,
	ci.cst_create_date as create_date
	
	
from silver.crm_cust_info as ci

-- left join table 'silver.erp_cust_az12'
left join silver.erp_cust_az12 as ca
on ci.cst_key = ca.cid

-- left join table 'silver.erp_loc_a101'
left join silver.erp_loc_a101 as la
on ci.cst_key = la.cid

 /* ============================================================================== 
  Creating Dimension: gold.dim_products
  ============================================================================== */

 -- dropping and creating view

drop view if exists gold.dim_products
go

create view gold.dim_products as
select 
	
	-- organise cst_id by start_date and prd_key
	ROW_NUMBER() OVER( order by pn.prd_start_dt, pn.prd_key) as product_key,
	prd_id as product_id,
	prd_key as product_number,
	prd_nm as product_name,
	cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance as maintenance,
	prd_cost as product_cost,
	prd_line as product_line,
	prd_start_dt as start_date

from silver.crm_prd_info as pn

-- left join table 'silver.erp_px_cat_g1v2'
left join silver.erp_px_cat_g1v2 as pc
on pn.cat_id = pc.id

where prd_end_dt is Null   --filter out historical data

 /* ============================================================================== 
  Creating Dimension: gold.fact_sales
  ============================================================================== */

 -- dropping and creating view

drop view if exists gold.fact_sales
 go

create view gold.fact_sales as
select 
sd.sls_ord_num as order_number,
pr.product_id as product_key,
cu.customer_key as customer_key,
sd.sls_order_dt as order_date,
sd.sls_ship_dt as ship_date,
sd.sls_due_dt as due_date,
sd.sls_sales as sales,
sd.sls_quantity as quantity,
sd.sls_price as sales_price

from silver.crm_sales_details as sd

-- left join table 'gold.dim_products'
left join gold.dim_products as pr
on sd.sls_prd_key = pr.product_number

-- left join table 'gold.dim_customers'
left join gold.dim_customers cu
on sd.sls_cust_id = cu.customer_id

