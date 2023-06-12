-- Create database 

CREATE DATABASE supply_chain;
USE supply_chain;

-- Table Structure for Customers 

CREATE TABLE dim_customers
	(
    	customer_id INT,
      	customer_name VARCHAR(45),
      	city VARCHAR(20)
    );
    
-- Table Structure for Products 

CREATE TABLE dim_products 
	(
    	product_name VARCHAR(20),
      	product_id INT,
      	category VARCHAR(15)
    );
    
-- Table Structure for dates 
DROP TABLE dim_dates;
CREATE TABLE dim_dates
	(
    	date DATE,
      	mmmm_yy VARCHAR(10),
      	week_no VARCHAR(10)
    );
    
 -- Table Structure for target_order
 
 CREATE TABLE dim_target_orders
 	(	
    	customer_id INT,
      	ontime_target_pct INT,
      	infull_target_pct INT,
      	otif_target_pct INT
    );
    
 -- Table Structure for fact_order_lines 
 DROP TABLE fact_order_lines;
 CREATE TABLE fact_order_lines
 	(
    	order_id  VARCHAR(20),
      	order_placement_date VARCHAR(30),
        order_week CHAR(3),
        order_date DATE,
      	customer_id INT,
      	product_id INT,
      	order_qty INT,
      	agreed_delivery_date VARCHAR(30),
      	actual_delivery_date VARCHAR(30),
        delivery_week CHAR(3),
        delivery_date DATE,
      	delivery_qty INT,
      	In_Full INT,
      	On_Time INT,
		On_Time_In_Full INT
    );
    
 -- Dumping data in the fact_order_lines table 
 
 LOAD DATA INFILE 
'I:\fact_order_lines.csv'
 into table fact_order_lines
 fields terminated by ','
 enclosed by '"'
 lines terminated by '\n'
 ignore 1 rows;
    
-- Table Structure for fact_orders_aggregate

CREATE TABLE fact_orders_aggregate
	(
    	order_id VARCHAR(20),
      	customer_id INT,
      	order_placement_date DATE,
      	on_time INT,
      	in_full INT,
      	otif INT
    );
    
 -- Dumping data in the table fact_orders_aggregate
 
 LOAD DATA INFILE 
 'I:\fact_orders_aggregate.csv'
 into table fact_orders_aggregate
 fields terminated by ','
 enclosed by '"'
 lines terminated by '\n'
 ignore 1 rows;
 
 
 -- Glimpse of the table 
 
SELECT 
    *
FROM
    dim_customers;
    
SELECT 
    *
FROM
    dim_dates;

SELECT 
    *
FROM
    dim_products;
    
SELECT 
    *
FROM
    dim_target_orders;   
    
select * from fact_order_lines; 
select * from fact_orders_aggregate;   