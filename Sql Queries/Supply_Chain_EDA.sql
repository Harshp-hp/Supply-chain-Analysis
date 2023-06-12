-- ********************************** Atliq Mart *****************************

-- Problem Statement

/* Atliq Mart is a Growing FMCG manufacturer headqaurted in Gujarat, India. It is currently operational in three cities Surat, Agmedabad and
Vadodara. They want to expand to other metros/ Tier 1 cities in next 2 years.

Atliq Mart is currently facing a problem where a few customers did not extend their anual contracts due to service issues. It is speculates that
some of the essential products were either not delivered on time or not delivered in full over a continued period, whcih could have resulted in 
bad customer service. Management wants to fix this issue before expanding to other cities and requested their supply chain analytics team to track the 
"On time", and "In Full"    delivery service level for all the customers daily basis so that they can respond swiftly to these issues.

The Supply Chain team decided to use a standard approach to measure the service level in which they will measure "on-time-delivery (OT) %",
"In-Full-Delivery (IF) %" 	, And "OnTime In Full (OTIF) % " of the customer orders daily basis against the target service level set for each 	
Customer.
*/


/* ***************************************Overview***************************************** */

/* Que. 1. 
	Starting with simple overvie of dataset present.
		a) Columns presentin each table
        b) Total customers present
        c) Total Products with their categories available
        d) Total cities they are currently 	operating insert
*/

-- Overview of the dataset 

-- Customers table
SELECT * FROM dim_customers;       

-- Dates table
SELECT * FROM dim_dates;

-- Products table
SELECT * FROM dim_products;

-- Target_orders table 
SELECT * FROM dim_target_orders;

-- Order_lines table 
SELECT * FROM fact_order_lines;

-- Ordes Aggregated table 
SELECT * FROM fact_orders_aggregate;

-- To get total customers present 
SELECT COUNT(distinct customer_id) AS Total_Cusotmers FROM dim_customers;
-- Total Customers are 35.

-- To get total products with their categories available 
SELECT COUNT(DISTINCT product_id) AS Total_products FROM dim_products;
-- Total producta are 18.

-- To get total cities they are currently operating in
SELECT COUNT(DISTINCT city) AS Total_cities FROM dim_customers;
-- Atliq currently operating in 3 cities.

-- What are total number of products and total number of customers?
SELECT COUNT(DISTINCT customer_id) AS Total_Customers, COUNT(DISTINCT product_id) AS Total_Products 
FROM fact_order_lines;

-- What is the average order quantity by customers?
SELECT customer_id, AVG(order_qty) AS Avg_order_qty FROM fact_order_lines GROUP BY customer_id;

-- What is the average delivery rate time for orders by city?

SELECT city, AVG(DATEDIFF(actual_delivery_date, agreed_delivery_date)) AS Avg_delivery_date
FROM fact_order_lines JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
GROUP BY city;

-- What is the average delivery time for on-time orders by city

SELECT city, AVG(DATEDIFF(actual_delivery_date, agreed_delivery_date)) AS Avg_delivery_date
FROM fact_order_lines JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
JOIN fact_orders_aggregate ON fact_order_lines.order_id = fact_orders_aggregate.order_id
WHERE fact_orders_aggregate.on_time = 1
GROUP BY city;

/* Que. 2
		What are total orders, total orders on time, total order infull and total orders (on time infull) (OTIF) by city */
        
WITH  city_order_data AS 
			(
				SELECT 
					dim_customers.city,
					fact_orders_aggregate.order_id,
					fact_orders_aggregate.on_time,
                    fact_orders_aggregate.in_full,
                    fact_orders_aggregate.otif
                FROM fact_orders_aggregate 
					JOIN dim_customers ON fact_orders_aggregate.customer_id = dim_customers.customer_id
              ),
all_order_data AS 
				(
					SELECT 	
						city_order_data.city,
                        COUNT(DISTINCT city_order_data.order_id) AS Total_orders,
                        SUM(CASE WHEN city_order_data.on_time = 1 THEN 1 ELSE 0 END ) AS total_on_time,
                        SUM(CASE WHEN city_order_data.in_full = 1 THEN 1 ELSE 0 END) AS total_in_full,
                        SUM(CASE WHEN city_order_data.otif = 1 THEN 1 ELSE 0 END) AS total_otif
                   FROM city_order_data
                   GROUP BY city_order_data.city
                   )
 SELECT 
	all_order_data.city,
    all_order_data.total_orders,
    all_order_data.total_on_time,
    all_order_data.total_in_full,
    all_order_data.total_otif,
	(SELECT 	
		COUNT(DISTINCT order_id) FROM fact_orders_aggregate) AS overall_total_order
     FROM all_order_data;   
                   
                   
/*   Que. 3 
		Provide insight regarding the share distribution of previous question metrics by customers.  */

WITH customer_metrics AS 
	(
		SELECT 
			c.customer_name,
            SUM(ol.order_qty) AS Total_orders,
            SUM(CASE WHEN o.on_time = 1 THEN ol.order_qty ELSE 0 END) AS total_orders_on_time,
            SUM(CASE WHEN o.in_full = 1 THEN ol.order_qty ELSE 0 END) AS total_orders_in_full,
            SUM(CASE WHEN o.otif = 1 THEN ol.order_qty ELSE 0 END) AS total_orders_otif
        FROM fact_order_lines ol
        JOIN dim_customers c  ON ol.customer_id = c.customer_id 
        JOIN fact_orders_aggregate o ON ol.order_id = o.order_id 
        GROUP BY c.customer_name
    ) 
  SELECT 
		customer_name,
        Total_orders,
        total_orders_on_time,
        total_orders_in_full,
        total_orders_otif,
        ROUND(total_orders_on_time/Total_orders *100,2) AS 'on_time_%',
        ROUND(total_orders_in_full/Total_orders *100,2) AS 'in_full_%',
        ROUND(total_orders_otif/Total_orders *100,2) AS 'otif %'
   FROM customer_metrics 
   ORDER BY Total_orders DESC;
   
   /* Que. 4 
		Calcualte % variance between actual and target from on time(OT), infull(IF) and "ON_Time and In Full" metrics by City */
        
 WITH actual AS 
	(
		SELECT 
			dim_customers.city,
            SUM(CASE WHEN fact_orders_aggregate.on_time = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS actual_ot,
            SUM(CASE WHEN fact_orders_aggregate.in_full = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS actual_if,
            SUM(CASE WHEN fact_orders_aggregate.otif = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS actual_otif
        FROM fact_orders_aggregate
        JOIN dim_customers ON fact_orders_aggregate.customer_id = dim_customers.customer_id 
        GROUP BY dim_customers.city
     ),
     target AS (
		SELECT 
			dim_customers.city,
            SUM(dim_target_orders.ontime_target_pct) / COUNT(DISTINCT dim_target_orders.customer_id) AS target_ot,
            SUM(dim_target_orders.infull_target_pct) / COUNT(DISTINCT dim_target_orders.customer_id) AS target_if,
            SUM(dim_target_orders.otif_target_pct) / COUNT(DISTINCT dim_target_orders.customer_id) AS target_otif
        FROM 	
			dim_target_orders
        JOIN dim_customers ON dim_target_orders.customer_id = dim_customers.customer_id
        GROUP BY dim_customers.city
	)
		SELECT 
			actual.city,
            ROUND((actual.actual_ot - target.target_ot) / target.target_ot * 100, 3) AS ot_varience,
            ROUND((actual.actual_if - target.target_if) / target.target_if * 100, 3) AS if_varience,
            ROUND((actual.actual_otif - target.target_otif) / target.target_otif * 100, 3) AS otif_varience
         FROM actual
         JOIN target ON actual.city = target.city;
         
         
/* 
	 Que. 5 
			Top 5 customers by total_quantity_orderd, in full quantity  ordered and "on time and infull" quantity ordered  */
            
  -- Top 5 Cusotmers by Total_quantity_ordered 
  
  SELECT 
	dim_customers.customer_name,
    SUM(fact_order_lines.order_qty) AS Total_order_qty
 FROM 
	dim_customers 
 JOIN fact_order_lines ON dim_customers.customer_id = fact_order_lines.customer_id 
 GROUP BY dim_customers.customer_name
 ORDER BY Total_order_qty DESC 
 LIMIT 5;
 
 -- Top 5 Cusotmers by in_full_qty_ordered
 
 SELECT 
	dim_customers.customer_name,
    SUM(fact_order_lines.delivery_qty) AS Full_qty_ordered
FROM 
		dim_customers
JOIN 
			fact_order_lines ON dim_customers.customer_id = fact_order_lines.customer_id
GROUP BY dim_customers.customer_name
ORDER BY Full_qty_ordered DESC 
LIMIT 5;        

-- Top 5 Customers by "OTIF" ordered Quantity.

WITH otif_ordered_qty AS 
		(
			SELECT 
				fact_order_lines.customer_id,
                SUM(CASE WHEN fact_orders_aggregate.otif = 1 THEN fact_order_lines.delivery_qty ELSE 0 END) AS OTIF_Qty
            FROM fact_order_lines 
            JOIN fact_orders_aggregate ON fact_order_lines.order_id = fact_orders_aggregate.order_id 
            GROUP BY fact_order_lines.customer_id
        )
    SELECT 
		dim_customers.customer_name,
        otif_ordered_qty.OTIF_Qty
    FROM otif_ordered_qty 
    JOIN dim_customers ON otif_ordered_qty.customer_id = dim_customers.customer_id
    ORDER BY OTIF_Qty DESC 
    LIMIT 5;
    
 /* Que. 6 
		Provide actual OT%, IF%, AND OTIF% by Cusotmers */
        
WITH actual AS 
			(
				SELECT 
					dim_customers.customer_name,
                    SUM(CASE WHEN fact_orders_aggregate.on_time = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS  actual_ot,
                    SUM(CASE WHEN fact_orders_aggregate.in_full = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS actual_if,
                    SUM(CASE WHEN fact_orders_aggregate.otif = 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT fact_orders_aggregate.order_id) * 100 AS actual_otif
                FROM fact_orders_aggregate
                JOIN dim_customers ON fact_orders_aggregate.customer_id = dim_customers.customer_id
                GROUP BY dim_customers.customer_name 
			)
		SELECT 
			actual.customer_name,
            ROUND(actual.actual_ot, 2) AS ot_pct,
            ROUND(actual.actual_if, 2) AS if_pct,
            ROUND(actual.actual_otif,2) AS otif_pct
        FROM 
			actual
        ORDER BY actual.customer_name;    
        
  /* Que. 7 
		Categories the orders by Product category for each customer in descending Order */
        
 WITH customer_orders AS (
		SELECT 
			dim_customers.customer_name,
            dim_products.category,
            COUNT(DISTINCT fact_order_lines.order_id) AS Total_Orders
        FROM   fact_order_lines
        JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
        JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
        GROUP BY dim_customers.customer_name, dim_products.category
        )
       SELECT 
			customer_orders.customer_name,
            SUM(CASE WHEN customer_orders.category = "dairy" THEN customer_orders.Total_Orders ELSE 0 END) AS 'Dairy',
            SUM(CASE WHEN customer_orders.category = "food" THEN customer_orders.Total_Orders ELSE 0 END) AS 'Food',
            SUM(CASE WHEN customer_orders.category = "beverages" THEN customer_orders.Total_Orders ELSE 0 END) AS 'Beverages',
			SUM(customer_orders.Total_Orders) AS "Total_Orders"
       FROM 
			customer_orders
       GROUP BY customer_orders.customer_name
       ORDER BY "Total_Orders" DESC ;
            
            
  /*
		Que. 8 
			Categories the orders by Product category for each city in descending order */
            
WITH customer_orders AS 
	(
		SELECT 
			dim_customers.city,
            dim_products.category,
            COUNT(DISTINCT fact_order_lines.order_id) AS total_orders
        FROM 
			fact_order_lines 
        JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
        JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
        GROUP BY dim_customers.city, dim_products.category
       )
       SELECT 
			customer_orders.city,
            SUM(CASE WHEN customer_orders.category = "dairy" THEN customer_orders.total_orders ELSE 0 END) AS 'Dairy',
            SUM(CASE WHEN customer_orders.category = 'food' THEN customer_orders.total_orders ELSE 0 END) AS 'Food',
            SUM(CASE WHEN customer_orders.category = 'beverages' THEN customer_orders.total_orders ELSE 0 END) AS 'Beverages',
            SUM(customer_orders.total_orders) AS "Total_Orders"
       FROM customer_orders
       GROUP BY customer_orders.city 
       ORDER BY "Total_Orders" DESC ;
       
       
       
   /* Que. 9
			Find the top 3 Customers from each city based on thier total orders and what is their OTIF% */
            
            
 WITH customer_orders AS (
		SELECT 
			dim_customers.city,
            dim_customers.customer_name,
            COUNT(fact_orders_aggregate.order_id) AS Total_orders,
            CONCAT((ROUND((COUNT(CASE WHEN otif = 1 THEN (otif) END) / COUNT(otif) * 100),2)), "%") AS "OTIF%",
            ROW_NUMBER() OVER(PARTITION BY dim_customers.city ORDER BY COUNT(fact_orders_aggregate.order_id) DESC) AS Ranking
		FROM fact_orders_aggregate
        JOIN dim_customers ON fact_orders_aggregate.customer_id = dim_customers.customer_id
        GROUP BY dim_customers.city, dim_customers.customer_name
	)
    SELECT * FROM customer_orders WHERE Ranking IN (1,2,3);
            
		
   /* Que. 10
			Which product was most and least ordered bt each customer?
            */
            
  WITH customer_products AS 
	(
		SELECT 
			dim_customers.customer_name,
            dim_products.product_name,
            COUNT(fact_order_lines.product_id) AS Product_count
         FROM fact_order_lines 
         JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
         JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
         GROUP BY dim_customers.customer_name, dim_products.product_name
     )
     SELECT 
			customer_products.customer_name,
            MAX(CASE WHEN customer_products.product_count = 
					(SELECT MAX(product_count) FROM customer_products c2 WHERE c2.customer_name = customer_products.customer_name) THEN
                    customer_products.product_name ELSE NULL END ) AS most_ordered_product,
            MIN(CASE WHEN customer_products.product_count = 
					(SELECT MIN(product_count) FROM customer_products c2 WHERE c2.customer_name = customer_products.customer_name) THEN 
                    customer_products.product_name ELSE NULL END) AS least_ordered_product
     FROM customer_products
	 GROUP BY customer_products.customer_name
     ORDER BY customer_products.customer_name 
	 LIMIT 3;               
     
     /* Que. 11 
			Try to distribute the total product orders by their categories 	and their % share, also show each city's top and worst selling products
            */
   WITH city_categories AS 
	(
		SELECT 
				dim_customers.city,
                dim_products.product_name,
                dim_products.category,
				COUNT(fact_order_lines.order_id) AS total_orders
         FROM fact_order_lines 
         JOIN dim_customers ON fact_order_lines.customer_id = dim_customers.customer_id
         JOIN dim_products ON fact_order_lines.product_id = dim_products.product_id
         GROUP BY dim_customers.city, dim_products.category 
      ),
		categories_totals AS 
       (
			SELECT 
				city,
				SUM(CASE WHEN category = 'dairy' THEN total_orders ELSE 0 END) AS 'dairy_total',
                SUM(CASE WHEN category = 'food' THEN total_orders ELSE 0 END) AS 'food_total',
                SUM(CASE WHEN category = 'beverages' THEN total_orders ELSE 0 END) AS 'beverages_total',
                SUM(total_orders) AS total_orders 
            FROM city_categories
            GROUP BY city
         )
         SELECT 
			city_categories.city,
            city_categories.category,
			city_categories.total_orders,
            CONCAT(ROUND((city_categories.total_orders/categories_totals.total_orders)*100,2) , "%")AS percent_share,
            MAX(CASE WHEN city_categories.total_orders = 
					(SELECT MAX(total_orders) FROM city_categories c2 WHERE c2.city = city_categories.city) THEN 
						city_categories.product_name  ELSE NULL END) as top_selling_products,
            MIN(CASE WHEN city_categories.total_orders = 
					(SELECT MIN(total_orders) FROM city_categories c2 WHERE c2.city = city_categories.city) THEN 
						city_categories.product_name ELSE NULL END) as least_selling_products
         FROM city_categories 
         JOIN categories_totals ON city_categories.city = categories_totals.city
         GROUP BY city_categories.city, city_categories.category
         ORDER BY city_categories.city, percent_share DESC;
         
  /* Que. 12 
			Analyze the trend of on time delivery over the months */

SELECT 
	MONTH(order_date) AS month,
    COUNT(order_id) AS Total_orders,
    SUM(CASE WHEN fact_order_lines.On_Time = 1 THEN 1 ELSE 0 END) AS on_time_orders,
    (SUM(CASE WHEN fact_order_lines.On_Time = 1 THEN 1 ELSE 0 END) / COUNT(fact_order_lines.order_id) *100 ) AS on_time_pct 
FROM 
		fact_order_lines
GROUP BY 
			MONTH(order_date)
ORDER BY 
				MONTH(order_date);
                
/* Que. 13 
			Analyze the trend of In Full delivery over the months */
            
SELECT 
		MONTH(order_date) AS Month,
        COUNT(order_id) AS Total_orders,
        SUM(CASE WHEN fact_order_lines.In_Full = 1 THEN 1 ELSE 0 END ) AS in_full_orders,
        (SUM(CASE WHEN fact_order_lines.In_Full = 1 THEN 1 ELSE 0 END) / COUNT(fact_order_lines.order_id) * 100) AS in_full_pct
FROM 
			fact_order_lines
GROUP BY 
				MONTH(order_date)
ORDER BY 
				MONTH(order_date);	
        
 /* Que. 14 
			Analyze the trend of In Full and On time delivery over months */
            
  SELECT 
		MONTH(order_date) AS Month,
        COUNT(order_id) AS Total_Orders,
        SUM(CASE WHEN fact_order_lines.On_Time_In_Full= 1 THEN 1 ELSE 0 END) AS otif_orders,
        (SUM(CASE WHEN fact_order_lines.On_Time_In_Full = 1 THEN 1 ELSE 0 END) / COUNT(fact_order_lines.order_id) * 100)  AS otif_orders_pct
  FROM 
		fact_order_lines
  GROUP BY 
		MONTH(order_date)
  ORDER BY 
		MONTH(order_date);
        
 /* Que. 15 
			Analyze the customer orders count distribution by day of week */
            
 SELECT 
    WEEKDAY(order_date) AS Day_no,
    CASE WEEKDAY(order_date)
		WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednwsday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
     END AS Day_Name  ,  
	COUNT(order_id) AS Total_orders
 FROM 
	fact_order_lines
 GROUP BY 
	Day_Name
 ORDER BY 
    Total_orders DESC;
      
/* Que.16  provide the average number of days between order placement and delivery for all orders by city. */

SELECT 
	c.city,
    ROUND(AVG(DATEDIFF(delivery_date, order_date)),2) AS Average_days
FROM 
	fact_order_lines ol
JOIN 
	dim_customers c ON ol.customer_id = c.customer_id
GROUP BY 
		c.city
ORDER BY 
		Average_days DESC;
        
 /* Que. Calculate the average lead time for each customer */
 
 SELECT 
	c.customer_name,
    ROUND(AVG(DATEDIFF(delivery_date, order_date)),2) AS Average_Time
FROM 
		fact_order_lines ol
JOIN 
			dim_customers c ON ol.customer_id = c.customer_id
GROUP BY
			c.customer_name
ORDER BY 
				Average_Time;