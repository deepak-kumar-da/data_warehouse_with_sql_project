/* Checking Null values and Duplicates in Customer Id(primary key) */

select cst_id,count(*)
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null

/* Checking Null values and Duplicates in Customer Id(primary key) */

select cst_id,count(*)
from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null

/* Checking of unwanted spaces in first_names */

select cst_first_name 
from silver.crm_cust_info
where cst_first_name != trim(cst_first_name)

/* Checking of unwanted spaces in last_names */

select cst_last_name 
from silver.crm_cust_info
where cst_last_name != trim(cst_last_name)

/* Data consistency in marital and gender */

select distinct(cst_gndr)
from silver.crm_cust_info

select distinct(cst_marital)
from silver.crm_cust_info

--check duplicate or null product id(prd_id)
select prd_id,count(*)
from bronze.crm_prd_info
group by prd_id
having count(*) >1 or prd_id is null

-- Checking blank spaces
select prd_nm
from bronze.crm_prd_info
where prd_nm != TRIM(prd_nm)

--checking for null or negative no.
select prd_cost
from bronze.crm_prd_info
where prd_cost < 0 or prd_cost is null

--data consistency
select distinct(prd_line)
from bronze.crm_prd_info

--checking valid date order
select *
from bronze.crm_prd_info
where prd_end_dt < prd_start_dt

--fixing date
select 
prd_id,
prd_key,
prd_nm,
prd_start_dt,
lead(prd_start_dt) over(partition by prd_key order by prd_start_dt )-1 as prd_end_dt_test
from bronze.crm_prd_info

--checking for invalid date orders
select
*
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_ship_dt > sls_due_dt

/* Business Rules :-
			
				-> Sum of Sales =  Quantity * Price
				-> negatives , zeros and nulls are not allowed
*/

-- checking null or negative sales,quantity and price 
select
sls_sales,
sls_quantity,
sls_price
from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price 
or sls_sales <= 0 or sls_quantity <=0 or sls_price <= 0
or sls_sales is null or sls_quantity is null or sls_price is null

-- Identify out of range dates

select distinct(BDATE)
from silver.erp_cust_az12
where bdate >GETDATE ()

--Data Consistency

select distinct(gen)
from silver.erp_cust_az12

-- Data Consistency in cntry

select distinct(cntry)
from silver.erp_loc_a101
