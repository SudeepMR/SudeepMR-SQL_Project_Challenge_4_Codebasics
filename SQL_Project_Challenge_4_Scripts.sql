-----------------------------------------
-----#CODEBASICS_SQL_PROJECT_CHALLENGE
-----------------------------------------

---Task 1-----------------------------

SELECT distinct(market)
FROM gdb023.dim_customer
where customer = "Atliq Exclusive" and region = "APAC"
order by market

----------------------------------------

---Task 2-------------------------

with firstCTE as
(
select count(distinct(a.product_code)) as unique_products_2020
from gdb023.dim_product as a
join gdb023.fact_sales_monthly as b
on a.product_code=b.product_code
where fiscal_year = 2020
), secondCTE as
(
select count(distinct(a.product_code)) as unique_products_2021
from gdb023.dim_product as a
join gdb023.fact_sales_monthly as b
on a.product_code=b.product_code
where fiscal_year = 2021
)
select firstCTE.unique_products_2020, secondCTE.unique_products_2021, ((secondCTE.unique_products_2021 - firstCTE.unique_products_2020)/firstCTE.unique_products_2020)*100 as percentage_chg
from firstCTE
cross join secondCTE
-----------------------------------------------------
---Task 3------------------

SELECT segment, count(distinct(product_code)) as product_count
FROM gdb023.dim_product
group by segment
order by 2 desc

------------------------------------------------------
---Task 4-------------------

with SomeCTE as
(
select a.segment as segment, count(distinct(a.product_code)) as product_count_2020
from gdb023.dim_product as a
join gdb023.fact_sales_monthly as b
on a.product_code=b.product_code
where fiscal_year = 2020
group by a.segment
), AnotherCTE as
(
select a.segment as segment, count(distinct(a.product_code)) as product_count_2021
from gdb023.dim_product as a
join gdb023.fact_sales_monthly as b
on a.product_code=b.product_code
where fiscal_year = 2021
group by a.segment
)
SELECT SomeCTE.segment, SomeCTE.product_count_2020, AnotherCTE.product_count_2021, (AnotherCTE.product_count_2021-SomeCTE.product_count_2020) as difference
FROM SomeCTE LEFT JOIN
     AnotherCTE ON SomeCTE.segment=AnotherCTE.segment
     order by 4 desc

------------------------------------------------------------
-----Task 5 ----------

with firstCTE as
(
SELECT a.product_code, a.product, min(b.manufacturing_cost) as manufacturing_cost
FROM gdb023.dim_product as a
join gdb023.fact_manufacturing_cost as b
on a.product_code=b.product_code
group by a.product_code, a.product
order by 3
limit 1
), secondCTE as
(
SELECT a.product_code, a.product, max(b.manufacturing_cost) as manufacturing_cost
FROM gdb023.dim_product as a
join gdb023.fact_manufacturing_cost as b
on a.product_code=b.product_code
group by a.product_code, a.product
order by 3 desc
limit 1
)
select *
from firstCTE
union
select *
from secondCTE

-----------------------------------------------------------------
-----Task 6 ------------------

SELECT a.customer_code, a.customer, round(cast(CAST(avg(b.pre_invoice_discount_pct) as decimal(18,5)) as float)*100, 2) as average_discount_percentage
FROM gdb023.dim_customer as a
join gdb023.fact_pre_invoice_deductions as b
on a.customer_code=b.customer_code
where b.fiscal_year='2021'
group by a.customer_code, a.customer
order by 3 desc
limit 5

---------------------------------------------------------------------------
----Task 7 -------------------

with firstCTE as
(
SELECT month(a.date) as month, year(a.date) as year, b.fiscal_year as fiscal_year, a.product_code, (a.sold_quantity*b.gross_price) as Gross_Sales_Amount
FROM gdb023.fact_sales_monthly as a
join gdb023.fact_gross_price as b
on a.product_code=b.product_code and a.fiscal_year=b.fiscal_year
where a.customer_code in(SELECT customer_code FROM gdb023.dim_customer where customer='Atliq Exclusive')
)
select month, year, sum(Gross_Sales_Amount) as Gross_Sales_Amount
from firstCTE
group by 1,2
order by 2

---------------------------------------------------------CONCAT('$', round((sum(Gross_Sales_Amount) / 1000000), 2), ' M') as  Gross_Sales_Amount
----Task 8 ----------

with firstCTE as
(
SELECT date, year(date) as year, quarter(date) as Quarter, sold_quantity
FROM gdb023.fact_sales_monthly
)
select quarter, sum(sold_quantity) as total_sold_quantity
from firstCTE
where year='2020'
group by Quarter
order by 1

---------------------------------------------, CONCAT(round((sum(sold_quantity) / 1000000), 2), ' M') as  total_sold_quantity
----Task 9 ------

with firstCTE as
(
SELECT a.date, c.channel, a.sold_quantity, b.gross_price, (a.sold_quantity*b.gross_price) as total_gross_price, a.fiscal_year
FROM gdb023.fact_sales_monthly as a
join gdb023.fact_gross_price as b
on a.product_code=b.product_code and a.fiscal_year=b.fiscal_year
join gdb023.dim_customer as c
on a.customer_code=c.customer_code
),secondCTE as
(
select channel, sum(total_gross_price) as total_gross_price
from firstCTE
where fiscal_year='2021'
group by 1
order by 2
)
select channel, total_gross_price, CONCAT(round((total_gross_price / 1000000)), ' M') as  gross_sales_mln, round((total_gross_price*100/(select sum(total_gross_price) from secondCTE)), 2) as 'percentage'
from secondCTE
group by 1

-----------------------------------------------------------------------------

----Task 10 ----------------------------

with firstCTE as
(
SELECT product_code, division, product
FROM gdb023.dim_product
), secondCTE as
(
select *
from gdb023.fact_sales_monthly
where fiscal_year='2021'
), thirdCTE as
(
select firstCTE.division as division, secondCTE.product_code as product_code, firstCTE.product as product, sum(sold_quantity) as total_sold_quantity
from firstCTE
join secondCTE
on firstCTE.product_code=secondCTE.product_code
group by 1,2,3
order by 4 desc
), forthCTE as
(
select division, product_code, product, total_sold_quantity, RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity desc) AS ranking
from thirdCTE
)
select *
from forthCTE
where ranking in ('1', '2', '3');

