/*
======================================================================================================
                            Analysis of Trends over Time
======================================================================================================
Purpose: This script performed advanced sales analytics to perform trends.
         It includes:
            - month-over-month trends & year-over-year trends for sales.
            - cumulative analysis for calculating running totals & moving averages.
            - performance analysis examines products to idenity whether they are high performing or low performing.
            - category wise  contribution in sales
            - data segmentation into different performance segments
*/
-- Analyze Sales Performance over time

-- Month over Month (MoM analysis)
select 
datetrunc(month,order_date) as order_date,
sum(sales) as total_sales,
count(distinct customer_key ) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date)

-- Year over Year (YoY analysis)
select 
datetrunc(year,order_date) as order_date,
sum(sales) as total_sales,
count(distinct customer_key ) as total_customers,
sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(year,order_date)
order by datetrunc(year,order_date)

-- Cumulative Analysis

-- total sales & avg sales per month and running total of sales over time
select
order_date,
total_sales,
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales,
avg(total_sales) over (partition by order_date order by order_date) as average_total_sales
from(
	select 
	datetrunc(month,order_date) as order_date,
	sum(sales) as total_sales
	from gold.fact_sales
	where order_date is not null
	group by datetrunc(month,order_date)
)t
order by datetrunc(month,order_date)

-- total & average sales per year and running total of sales over time
select
order_date,
total_sales,
sum(total_sales) over (order by order_date) as running_total_sales,
avg(total_sales) over (order by order_date) as average_total_sales
from(
	select 
	datetrunc(year,order_date) as order_date,
	sum(sales) as total_sales
	from gold.fact_sales
	where order_date is not null
	group by datetrunc(year,order_date)
)t
order by datetrunc(year,order_date)

-- Performance Analysis

-- analysing the yearly performance of products by 
-- comparing sales to both avg and previous sales performance of product

with yearly_product_sales as (
	select
	year(f.order_date) as order_year,
	p.product_name,
	sum(f.sales) as current_sales
	from gold.fact_sales as f 

	left join gold.dim_products as p
	on f.product_key = p.product_key

	where f.order_date is not null
	group by year(f.order_date) , p.product_name
)

select
order_year,
product_name,
current_sales,
avg(current_sales) over(partition by product_name ) as avg_sales,
current_sales - avg(current_sales) over (partition by product_name) as avg_diff,
case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'Above AVG'
	 when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'Below AVG'
	 else 'AVG'
end avg_change,
lag(current_sales) over (partition by product_name order by order_year) as previous_sales,
current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_previous_sales,
case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'Increasing'
	 when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'Decreasing'
	 else 'No Change'
end py_change
from yearly_product_sales
order by product_name,order_year

-- Part to Whole Analysis

-- category that contributes the most overall sales
with category_sales as(
select category, sum(sales) as total_sales

from gold.fact_sales f
left join gold.dim_products p
on p.product_id = f.product_key
group by category)

select category,total_sales,
sum(total_sales) over() as overall_sales,
concat(round((cast(total_sales as float) / sum(total_sales) over()) * 100,2),'%') as percentage_of_total
from category_sales
order by total_sales desc

-- Data Segmentation

-- Segment products into cost ranges & count(product) fall into each segment
with product_segment as(
select product_key, product_name, product_cost,
case when product_cost < 100 then 'Below 100'
	 when product_cost between 100 and 500 then '100-500'
	 when product_cost between 500 and 1000 then '500-1000'
	 else 'Above 1000'
end cost_range
from gold.dim_products
)

select cost_range,
count(product_key) as total_products
from product_segment
group by cost_range
order by total_products desc

/* Assigning customers the tags - vip , regular and new
	VIP : Customer with 12 months trust and spending over 5k
	Regular : Customer with 12 months trust but spending 5k or less
	New : Customers with less than 12 months trust
*/
with customer_spending as (
	select
	c.customer_key,
	sum(f.sales) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	datediff (month, min(order_date),max(order_date)) as lifespan
	from gold.fact_sales f
	left join gold.dim_customers c
	on c.customer_key = f.customer_key
	group by c.customer_key
)

select customer_key,total_spending,lifespan,
case when lifespan > 12 and total_spending > 5000 then 'VIP'
	 when lifespan > 12 and total_spending <= 5000 then 'Regular'
	 else 'New'
end customer_segment
from customer_spending
