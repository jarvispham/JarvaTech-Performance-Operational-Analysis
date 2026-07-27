-- 1. Sales Revenue
-- 1.1 Sales Revenue by Year
SELECT
	YEAR(purchase_ts) AS purchase_year,
	SUM(usd_price) AS Total_Sales
FROM orders
GROUP BY purchase_year
ORDER BY purchase_year;
-- 1.2 Sales Revenue by Month
SELECT
	YEAR(purchase_ts) AS purchase_year,
    MONTH(purchase_ts) AS purchase_month,
	SUM(usd_price) AS Total_Sales
FROM orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- 2. Average Order Value
-- 2.1 AOV by Year
SELECT
	YEAR(purchase_ts) AS purchase_year,
    AVG(usd_price) AS AOV
FROM orders
GROUP BY purchase_year
ORDER BY purchase_year;
-- 2.2 AOV by Month
SELECT
	YEAR(purchase_ts) AS purchase_year,
    MONTH(purchase_ts) AS purchase_month,
	AVG(usd_price) AS AOV
FROM orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- 3. Sales by Products
-- 3.1 Top 3 product with highest sales
SELECT
	od.product_name,
    SUM(od.usd_price) AS Total_Sales
FROM orders AS od
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY od.product_name
ORDER BY Total_Sales DESC
LIMIT 3;
-- 3.2 Top 3 product with lowest sales
SELECT
	od.product_name,
    SUM(od.usd_price) AS Total_Sales
FROM orders AS od
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY od.product_name
ORDER BY Total_Sales
LIMIT 3;

-- 4. Number of Orders by Products
-- 4.1 Top 3 product with highest number of orders
SELECT
	od.product_name,
    COUNT(od.order_id) AS Order_Count
FROM orders AS od
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY od.product_name
ORDER BY Order_Count DESC
LIMIT 3;
-- 4.2 Top 3 product with lowest sales
SELECT
	od.product_name,
    COUNT(od.order_id) AS Order_Count
FROM orders AS od
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY od.product_name
ORDER BY Order_Count
LIMIT 3;

-- 5. Loyalty Program
-- 5.1 Number of members and non-members
SELECT COUNT(user_id) AS Member_Count,
	CASE
		WHEN loyalty_program = 0 THEN "Non-member"
        ELSE "Member"
	END AS Loyalty
FROM customers
GROUP BY Loyalty;
-- 5.2 Number of orders and sales by loyalty
SELECT COUNT(od.order_id) AS Order_Count,
	SUM(od.usd_price) AS Sales,
	CASE
		WHEN cs.loyalty_program = 0 THEN "Non-member"
        ELSE "Member"
	END AS Loyalty
FROM orders AS od
JOIN customers AS cs
ON od.user_id = cs.user_id
GROUP BY Loyalty;

-- 6. Countries
-- 6.1 Top 5 Countries with highest sales
SELECT cs.country_name,
	SUM(od.usd_price) AS Total_Sales
FROM customers AS cs
JOIN orders AS od
ON cs.user_id = od.user_id
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY cs.country_name
ORDER BY Total_Sales DESC
LIMIT 5;
-- 6.2 Top 5 Countries with highest number of orders
SELECT cs.country_name,
	COUNT(od.order_id) AS Order_Count
FROM customers AS cs
JOIN orders AS od
ON cs.user_id = od.user_id
JOIN order_status AS st
ON od.order_id = st.order_id
WHERE st.refund_ts IS NULL
GROUP BY cs.country_name
ORDER BY Order_Count DESC
LIMIT 5;

-- 7. Purchase Platform
SELECT purchase_platform,
	COUNT(order_id) AS Order_Count,
    SUM(usd_price) AS Total_Sales
FROM orders
GROUP BY purchase_platform;

-- 8. Refund
-- 8.1 Refund Overview
SELECT COUNT(refund_ts) AS Refund_Count,
	COUNT(refund_ts)/COUNT(order_id) *100 AS Refund_Rate
FROM order_status;
-- 8.2 Refund Rates by Products
SELECT
	od.product_name,
	COUNT(st.refund_ts) AS Refund_Count,
	COUNT(st.refund_ts)/COUNT(od.order_id) *100 AS Refund_Rate
FROM orders AS od
JOIN order_status AS st
ON od.order_id = st.order_id
GROUP BY product_name
ORDER BY Refund_Rate DESC;
-- 8.3 Refund Rates by Region
SELECT 
    cs.region,
    COUNT(st.refund_ts) AS Refund_Count,
    COUNT(st.refund_ts) / COUNT(od.order_id) * 100 AS Refund_Rate
FROM
    customers AS cs
        JOIN
    orders AS od ON cs.user_id = od.user_id
        JOIN
    order_status AS st ON od.order_id = st.order_id
GROUP BY cs.region
ORDER BY Refund_Rate DESC;
-- 8.4 Refund Rates by Loyalty
SELECT
	CASE
		WHEN cs.loyalty_program = 0 THEN "Non-member"
        ELSE "Member"
	END AS Loyalty,
	COUNT(st.refund_ts) AS Refund_Count,
	COUNT(st.refund_ts)/COUNT(od.order_id) *100 AS Refund_Rate
FROM customers AS cs
JOIN orders AS od
ON cs.user_id = od.user_id
JOIN order_status AS st
ON od.order_id = st.order_id
GROUP BY Loyalty
ORDER BY Refund_Rate DESC;

-- 9. Fulfillment and Delivery Time
-- 9.1 Overall
WITH delivery AS
(SELECT order_id,
	DATEDIFF(ship_ts, purchase_ts) AS fulfillment_date,
    DATEDIFF(delivery_ts, purchase_ts) AS day_to_ship
FROM order_status
)
SELECT
	AVG(fulfillment_date),
    AVG(day_to_ship)
FROM delivery;
-- 9.2 By products
WITH delivery AS
(SELECT order_id,
	DATEDIFF(ship_ts, purchase_ts) AS fulfillment_date,
    DATEDIFF(delivery_ts, purchase_ts) AS day_to_ship
FROM order_status
)
SELECT od.product_name,
	AVG(fulfillment_date),
    AVG(day_to_ship)
FROM orders AS od
JOIN delivery AS dl
ON od.order_id = dl.order_id
GROUP BY od.product_name;
-- 9.3 By Country
WITH delivery AS (
    SELECT 
        order_id,
        DATEDIFF(ship_ts, purchase_ts) AS fulfillment_days,
        DATEDIFF(delivery_ts, purchase_ts) AS total_delivery_days
    FROM order_status
)
SELECT 
    cs.country_name,
    COUNT(od.order_id) AS total_orders,
    ROUND(AVG(dl.fulfillment_days), 2) AS avg_fulfillment_days,
    ROUND(AVG(dl.total_delivery_days), 2) AS avg_total_delivery_days
FROM orders AS od
JOIN delivery AS dl 
    ON od.order_id = dl.order_id
JOIN (
    SELECT DISTINCT user_id, country_name 
    FROM customers
) AS cs 
    ON od.user_id = cs.user_id
GROUP BY cs.country_name
ORDER BY total_orders DESC;

-- 10. Month-Over-Month Revenue Growth
-- 10.1 Top 3 Month with highest growth
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(purchase_ts, '%Y-%m') AS sales_month,
        SUM(usd_price) AS total_revenue
    FROM orders
    GROUP BY sales_month
),
mom_calc AS (
    SELECT 
        sales_month,
        total_revenue,
        LAG(total_revenue, 1) OVER (ORDER BY sales_month) AS previous_month_revenue,
        ROUND(
            ((total_revenue - LAG(total_revenue, 1) OVER (ORDER BY sales_month)) 
            / LAG(total_revenue, 1) OVER (ORDER BY sales_month)) * 100, 2
        ) AS mom_growth_pct
    FROM monthly_sales
)
SELECT 
    sales_month,
    total_revenue,
    previous_month_revenue,
    mom_growth_pct
FROM mom_calc
WHERE mom_growth_pct IS NOT NULL
ORDER BY mom_growth_pct DESC
LIMIT 3;
-- 10.2 Top 3 Month with highest decrease
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(purchase_ts, '%Y-%m') AS sales_month,
        SUM(usd_price) AS total_revenue
    FROM orders
    GROUP BY sales_month
),
mom_calc AS (
    SELECT 
        sales_month,
        total_revenue,
        LAG(total_revenue, 1) OVER (ORDER BY sales_month) AS previous_month_revenue,
        ROUND(
            ((total_revenue - LAG(total_revenue, 1) OVER (ORDER BY sales_month)) 
            / LAG(total_revenue, 1) OVER (ORDER BY sales_month)) * 100, 2
        ) AS mom_growth_pct
    FROM monthly_sales
)
SELECT 
    sales_month,
    total_revenue,
    previous_month_revenue,
    mom_growth_pct
FROM mom_calc
WHERE mom_growth_pct IS NOT NULL
ORDER BY mom_growth_pct
LIMIT 3;

