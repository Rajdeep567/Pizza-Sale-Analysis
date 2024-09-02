-- Orders
--  order_id  order_date   order_time

-- order_details
-- order_details_id	  order_id   pizza_id   quantity

-- pizza_types
-- pizza_type_id  name  category  ingredients

-- pizzas
-- pizza_id   pizza_type_id	 size	 price

-- Basic:
-- 1. Retrieve the total number of orders placed.
select distinct count(order_id) as total_orders from orders;

-- 2. Calculate the total revenue generated from pizza sales.
select round(sum(A.quantity * B.price),2) as Total_price 
from order_details as A join pizzas B
on A.pizza_id = B.pizza_id;

-- 3. Identify the highest-priced pizza.
select A.name as Name, B.price as Price,B.size
from pizza_types as A join pizzas as B
on A.pizza_type_id = B.pizza_type_id
order by B.price desc ;

-- it will give incorrect data
-- select A.name as Name, max(B.price) as Price
-- from pizza_types as A join pizzas as B
-- on A.pizza_type_id = B.pizza_type_id;


-- 4. Identify the most common pizza size ordered.
select count(A.order_details_id) as Order_count, B.size as size
from order_details as A join pizzas as B 
on A.pizza_id = B.pizza_id
group by B.size
order by count(A.order_details_id) desc 
LIMIT 1;
-- 5. List the top 5 most ordered pizza types along with their quantities.
SELECT sum(A.quantity) Quantity, C.name Name
FROM order_details AS A JOIN pizzas AS B
ON A.pizza_id = B.pizza_id 
JOIN pizza_types AS C
ON B.pizza_type_id = C.pizza_type_id
GROUP BY C.name 
ORDER BY Quantity desc
LIMIT 5;   
-- 2453   The Classic Deluxe Pizza
-- 2432   The Barbecue Chicken Pizza
-- 2422   The Hawaiian Pizza
-- 2371   The Thai Chicken Pizza
-- 1884   The Italian Supreme Pizza

-- Intermediate:
-- 1. Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT sum(A.quantity) Quantity, C.category Category
FROM order_details AS A JOIN pizzas AS B
ON A.pizza_id = B.pizza_id 
JOIN pizza_types AS C
ON B.pizza_type_id = C.pizza_type_id
GROUP BY C.category 
ORDER BY Quantity desc;   
-- 14888	Classic
-- 11649	Veggie
-- 11987	Supreme
-- 11050	Chicken

-- 2. Determine the distribution of orders by hour of the day.
SELECT hour(order_time) Hours, count(order_id) Total_Orders 
FROM orders 
GROUP BY hour(order_time)
ORDER BY count(order_id) DESC;

-- 3. Join relevant tables to find the category-wise distribution of pizzas.
SELECT category AS Category_Of_Pizzas, count(name) as TOTAL_RECIPIE
FROM pizza_types 
group by category
ORDER BY count(name) DESC;
-- Supreme	9
-- Veggie	9
-- Classic	8
-- Chicken	6

-- 4. Group the orders by date and calculate the average number of pizzas ordered per day.
-- Orders (A)  order_date |  orders_details (B)  quantity  == 138 PER DAY

SELECT ROUND(AVG(Quantity)) AS  AVG_per_day_sale
FROM (SELECT  A.order_date, SUM(B.quantity) as Quantity
	FROM orders A JOIN order_details B
	ON A.order_id = B.order_id
	GROUP BY A.order_date
	ORDER BY  B.quantity) AS order_quantity_each_day;


-- 5. Determine the top 3 most ordered pizza types based on revenue.
-- 'pizzas (A) pizza_type_id	 pizza_id   price |  pizza_types (B) pizza_type_id  name  category
-- orders_details (C) pizza_id   quantity'
SELECT 
	B.name AS POPULAR_PIZZAS_NAME,  SUM(A.PRICE * C.quantity)  AS REVENEU_IN_INDIAN_RUPEES
FROM 
	pizzas AS A JOIN pizza_types AS B
ON
	A.pizza_type_id = B.pizza_type_id
    JOIN order_details AS C
ON 
	A.pizza_id = C.pizza_id
GROUP BY
	B.name
ORDER BY
	REVENEU_IN_INDIAN_RUPEES DESC
LIMIT 3;
-- The Thai Chicken Pizza	43434.25
-- The Barbecue Chicken Pizza	42768
-- The California Chicken Pizza	41409.5


-- Advanced:
-- 1. Calculate the percentage contribution of each pizza type to total revenue.
-- -- -- ROUND(SUM(A.PRICE * C.quantity)) WILL GIVE TOTAL REVENEU (WITHOUT use of GROUP BY)
SELECT SUM(A.PRICE * C.quantity)
FROM pizzas AS A JOIN order_details AS C
ON A.pizza_id = C.pizza_id; -- TOTAL REVENEU
-- -- -- (SINGLE REVENEU / TOTAL REVENEU) * 100 GIVES PERCENTAGE OF SINGLE REVENEU
SELECT 	B.category AS PIZZAS_category,  
    ROUND( ( 
		SUM(A.PRICE * C.quantity) / ( SELECT SUM(A.PRICE * C.quantity)
									  FROM pizzas AS A JOIN order_details AS C
									  ON A.pizza_id = C.pizza_id
									)
			)*100,2) AS REVENEU_IN_PERCENTAGE
FROM pizzas AS A JOIN pizza_types AS B
ON A.pizza_type_id = B.pizza_type_id 
JOIN order_details AS C
ON A.pizza_id = C.pizza_id
GROUP BY B.category
ORDER BY SUM(A.PRICE) DESC;
    
-- 2. Analyze the cumulative revenue generated over time.
-- 	     REVENEU  | CUMILATIVE_REVENEU
-- DAY1    200         200
-- DAY2    300         500
-- DAY3    500         1000
SELECT A.order_date, SUM(B.quantity * C.price) AS REVENEU
		FROM orders A JOIN order_details B
		ON A.order_id = B.order_id
		JOIN pizzas C
		ON B.pizza_id = C.pizza_id
		GROUP BY A.order_date; -- REVENEU PER DAY
        
SELECT Order_Date, round(REVENEU) Reveneu,
		ROUND( SUM(REVENEU) OVER(ORDER BY ORDER_DATE) ) AS Cumilative_Reveneu
FROM (
		SELECT A.order_date, (SUM(B.quantity * C.price)) AS REVENEU
		FROM orders A JOIN order_details B
		ON A.order_id = B.order_id
		JOIN pizzas C
		ON B.pizza_id = C.pizza_id
		GROUP BY A.order_date
	) AS PER_DAY_REVENEU; -- CUMILATIVE REVENEU 
 
-- 3. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

		-- FETCH REVENEU BY EACH CATEGORY
SELECT C.category, C.name, SUM(A.quantity * B.price)
FROM order_details A JOIN pizzas B
ON A.pizza_id = B.pizza_id
JOIN pizza_types C
ON B.pizza_type_id = C.pizza_type_id
group by C.category, C.name
ORDER BY  C.category;

-- IT WILL CHOOSE ONLY 3 ROW FROM TABLE_B
SELECT Category, Name, Reveneu, SERIAL_NO
FROM ( 
		-- IT WILL RANK THE REVENEU BY CATAGORY FROM TABLE_A
	SELECT Category, Name, Reveneu,
	DENSE_RANK() OVER(PARTITION BY category ORDER BY reveneu DESC) AS SERIAL_NO
	FROM ( 
			-- FETCH REVENEU BY EACH CATEGORY
		SELECT C.category, C.name, ROUND(SUM(A.quantity * B.price)) AS REVENEU
		FROM order_details A JOIN pizzas B
		ON A.pizza_id = B.pizza_id
		JOIN pizza_types C
		ON B.pizza_type_id = C.pizza_type_id
		group by C.category, C.name
		ORDER BY  C.category
		) AS TABLE_A
	)AS TABLE_B
WHERE SERIAL_NO < 4;