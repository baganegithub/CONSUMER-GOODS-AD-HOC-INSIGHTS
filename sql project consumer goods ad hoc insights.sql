/* 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/
select market FROM dim_customer WHERE customer='Atliq Exclusive' AND region = 'APAC' GROUP BY market;

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
unique_products_2020 unique_products_2021 percentage_chg */

select * from fact_gross_price;
with unique_2020 as (SELECT count(distinct(product_code)) as unique_product_2020 
               from fact_gross_price where fiscal_year=2020 ),
               
 unique_2021 as ( select count(distinct(product_code)) as unique_product_2021  
 from fact_gross_price where fiscal_year=2021 )
 
 SELECT unique_2020.unique_product_2020,unique_2021.unique_product_2021 ,
        (((unique_2021.unique_product_2021-unique_2020.unique_product_2020)/unique_2020.unique_product_2020)*100) as 
        "Percentage_change"
        FROM unique_2020 CROSS JOIN unique_2021;
 
/* 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
 The final output contains 2 fields, segment product_count*/
 
 select * from dim_product;
 SELECT segment,  count(distinct(product)) as product_count FROM dim_product 
 GROUP BY segment ORDER BY product_count DESC; 
 
/* 4. : Which segment had the most increase in unique products in 2021 vs 2020? The final output contains 
these fields, segment product_count_2020 product_count_2021 difference*/
 select * from fact_gross_price;
 SELECT * from dim_product;
 WITH product_2020 as ( SELECT dim_product.segment, count(DISTINCT(dim_product.product)) as product_count_2020
                        from dim_product inner join fact_gross_price 
                        on dim_product.product_code=fact_gross_price.product_code
						where fact_gross_price.fiscal_year=2020
                        GROUP BY segment),
	 product_2021 as  (SELECT dim_product.segment, count(DISTINCT(dim_product.product)) as product_count_2021
                        from dim_product inner join fact_gross_price 
                        on dim_product.product_code=fact_gross_price.product_code
						where fact_gross_price.fiscal_year=2021
                        GROUP BY segment)
	SELECT product_2020.segment, product_2020.product_count_2020,product_2021.product_count_2021,
          (product_2021.product_count_2021-product_2020.product_count_2020) as Difference
          from product_2020
          JOIN product_2021
          ON product_2020.segment=product_2021.segment
          order by Difference;

/* 5.Get the products that have the highest and lowest manufacturing costs. The final output
 should contain these fields, product_code, product, manufacturing_cost */
 SELECT * FROM fact_manufacturing_cost;
  SELECT * FROM dim_product;
  SELECT  dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
  FROM dim_product
  INNER JOIN fact_manufacturing_cost ON
  dim_product.product_code=fact_manufacturing_cost.product_code 
  WHERE fact_manufacturing_cost.manufacturing_cost= (
   select MAX(manufacturing_cost) FROM fact_manufacturing_cost)
   OR fact_manufacturing_cost.manufacturing_cost=  (
   select MIN(manufacturing_cost) FROM fact_manufacturing_cost);
   
  /* 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
  for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code, customer 
  , average_discount_percentage */
  
  select * from fact_pre_invoice_deductions;
  select * from dim_customer;
  SELECT dim_customer.customer_code, dim_customer.customer ,
  AVG(ROUND((fact_pre_invoice_deductions.pre_invoice_discount_pct),2)*100) AS average_discount_percentage
  FROM	dim_customer  
  INNER JOIN fact_pre_invoice_deductions
  ON  dim_customer.customer_code=fact_pre_invoice_deductions.customer_code
  WHERE	 fact_pre_invoice_deductions.fiscal_year=2021 
  AND dim_customer.market='India'
  GROUP BY dim_customer.customer, dim_customer.customer_code
  ORDER by average_discount_percentage DESC
  LIMIT 5;
  
  /* 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
  This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final
  report contains these columns: Month, Year, Gross sales Amount */
  select * from fact_sales_monthly ; 
  select * from fact_gross_price;
  select * from dim_customer;
  
  SELECT month(fact_sales_monthly.date) as Month, year(fact_sales_monthly.date) as Year,
  SUM(fact_gross_price.gross_price * fact_sales_monthly. sold_quantity) as "Gross Sales amount"
  FROM dim_customer
  INNER JOIN fact_sales_monthly
  ON dim_customer.customer_code= fact_sales_monthly.customer_code
  INNER JOIN fact_gross_price
  ON fact_sales_monthly.product_code=fact_gross_price.product_code
  WHERE dim_customer.customer='Atliq Exclusive'
  GROUP BY Month, Year
  ORDER BY year;
  
  /*8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these
  fields sorted by the total_sold_quantity, Quarter ,total_sold_quantity */
  select * from fact_sales_monthly;
  SELECT   
  CASE 
WHEN MONTH(fact_sales_monthly.date) in (9,10,11) THEN 'Q1'
WHEN MONTH(fact_sales_monthly.date) in (12,1,2) THEN 'Q2'
WHEN MONTH(fact_sales_monthly.date) in ( 3,4,5) THEN 'Q3'
WHEN MONTH(fact_sales_monthly.date) in (6,7,8) THEN 'Q4'
END as "Quarter", sum(fact_sales_monthly.sold_quantity) as "total_sold_quantity"
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY Quarter
order by total_sold_quantity desc;
  
  /* 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
  The final output contains these fields, channel ,gross_sales_mln,  percentag*/
  SELECT * FROM dim_customer;
  SELECT * FROM fact_sales_monthly;
  SELECT * FROM fact_gross_price;
/*1. Need to find gross sales (sold_quantity * gross_price) as Gross_Sales_mln for year 2021
2 % contribution= ((Gross_Sales_mln*100))/SUM(Gross_Sales_mln))
3. group by channel*/
 with cte1 as ( SELECT dim_customer.channel, round(sum(fact_gross_price.gross_price*fact_sales_monthly.sold_quantity))/1000000 as
 'Gross_Sales_mln'
 FROM fact_gross_price
 INNER JOIN fact_sales_monthly
 ON fact_sales_monthly.product_code=fact_gross_price.product_code
 AND fact_gross_price.fiscal_year=fact_sales_monthly.fiscal_year
 INNER JOIN dim_customer
ON dim_customer.customer_code=fact_sales_monthly.customer_code
Where fact_sales_monthly.fiscal_year=2021
GROUP BY dim_customer.channel
)
SELECT *, ROUND(( Gross_Sales_mln*100))/sum(Gross_Sales_mln)
OVER () AS Percentage_contribution
FROM cte1
ORDER BY Percentage_contribution DESC;


/* 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 The final output contains these fields, division ,product_code ,product ,total_sold_quantity 
 rank_order*/
  SELECT * FROM dim_product;
  SELECT * FROM dim_customer;
  SELECT * FROM fact_sales_monthly;
  SELECT * FROM fact_gross_price;
  
  with cte1 as(
  select dim_product.division, dim_product.product_code, dim_product.product,
  SUM(fact_sales_monthly.sold_quantity) as " total_sold_quantity"
  FROM dim_product
  INNER JOIN fact_sales_monthly
  ON dim_product.product_code= fact_sales_monthly.product_code
  WHERE fact_sales_monthly.fiscal_year=2021
  GROUP BY dim_product.division, dim_product.product_code,dim_product.product) ,
   cte2 as( 
  select * , RANK () OVER 
  (PARTITION BY division order by total_sold_quantity desc)
  as rank_order from cte1)
   select * from cte2
   WHERE rank_order<=3;
  


          


    
    

  
  
  
   
  
  
         
  














