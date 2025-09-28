select * from Superstore_orders;

/* MoM percentage sales change for all Years */
with cte as (
select YEAR(order_date) as Year_Order, MONTH(order_date) as Month_order, sum(sales) as Total_Sales
from Superstore_orders
group by YEAR(order_date), MONTH(order_date))
,cte2 as (
select Year_Order,Month_order,Total_Sales as Current_Month_Sales
,lag(Total_Sales,1) over(partition by Year_Order order by Year_Order,Month_order) as Prev_Month_Sales
from cte)
select *,concat(round(100.0*(Current_Month_Sales-Prev_Month_Sales)/Prev_Month_Sales,2),'%') as Percentage_Sales_Change
from cte2;

/* YoY percentage sales change for all Years */
with cte as (
select year(order_date) as Year_Order, Sum(sales) as Total_Sales
from Superstore_orders
group by year(order_date))
,cte2 as (
select Year_Order,Total_Sales as Current_Month_Sales, lag(Total_Sales,1) over(order by Year_Order asc) as Prev_Month_Sales
from cte)
select *,concat(round(100.0*(Current_Month_Sales-Prev_Month_Sales)/Prev_Month_Sales,2),'%') as Percentage_Sales_Change
from cte2;

/* Rank top 3 Prodcts by Sales in each category*/
with cte as (
select category,product_id, sum(Sales) as Total_Sales
from Superstore_orders
group by category,product_id)
,cte2 as (
select *,DENSE_RANK()over(partition by category order by Total_Sales desc) as rnk
from cte)
select * from cte2 where rnk <=3;

/* Sales split for all the years for all category for the city 'Los Angeles'*/
with cte as (
select * from Superstore_orders
where city = 'Los Angeles')
select category
,sum(case when year(order_date) = 2018 then sales else null end) as Sales_2018
,sum(case when year(order_date) = 2019 then sales else null end) as Sales_2019
,sum(case when year(order_date) = 2020 then sales else null end) as Sales_2020
,sum(case when year(order_date) = 2021 then sales else null end) as Sales_2021
from cte 
group by category;

/* Top selling products by qty in each sub_category where qty in sub_category>2000 */
with cte as (
select Category,Sub_Category,sum(Quantity) as Total_Qty
from Superstore_orders
group by Category,Sub_Category
having sum(Quantity)>2000)
,cte2 as (
select *,DENSE_RANK()over(partition by category order by Total_Qty desc) as rnk
from cte) 
select * from cte2 where rnk=1;

/* How many such orders per city are there? where those orders took 7 days to ship, order them descending */
with cte as (
select Order_ID,Order_Date,Ship_Date,City
,DATEDIFF(DAY,Order_Date,Ship_Date) as Days_Took_To_Ship
from Superstore_orders)
,cte2 as (
select * from cte where Days_Took_To_Ship = 7)
,cte3 as (
select *,count(Order_ID)over(partition by city) as Count_Of_Cities
from cte2)
select city,Count_Of_Cities 
from cte3
group by city,Count_Of_Cities
order by Count_Of_Cities desc; 

/* Top 3 profit making product in each category for the year 2020 */

with cte as (
select * from Superstore_orders
where YEAR(Order_Date) = 2020)
,cte2 as (
select Category, Product_ID, SUM(Profit) as Total_Profit
from cte 
group by Category, Product_ID)
,cte3 as (
select *, DENSE_RANK()over(partition by Category order by Total_Profit desc) as rnk
from cte2)
select * from cte3 where rnk<=3;

/* Get the segment wise losses for all the years */
with cte as (
select S.Order_Date,Year(Order_Date) as Order_Year,S.Segment,S.Category,S.Sales,r.Returned 
from Superstore_orders s
inner join returns r
on s.Order_ID = r.Order_ID)
select Segment
,sum(case when Order_Year = 2018 then sales else null end) as Sales_2018
,sum(case when Order_Year = 2019 then sales else null end) as Sales_2019
,sum(case when Order_Year = 2020 then sales else null end) as Sales_2020
,sum(case when Order_Year = 2021 then sales else null end) as Sales_2021
from cte
group by Segment;

/* MoM growth for all regions in 'San Francisco' for the year 2020 */
with cte as (
select * from Superstore_orders
where YEAR(order_date) = 2020 and city = 'San Francisco')
,cte2 as (
select format(Order_Date,'yyyy-MM') as Year_Month
,COALESCE(SUM(case when Category = 'Furniture' then Sales else null end),0) as Furniture_Sales
,COALESCE(SUM(case when Category = 'Office Supplies' then Sales else null end),0) as Office_Supplies_Sales
,COALESCE(SUM(case when Category = 'Technology' then Sales else null end),0) as Technology_Sales
from cte
group by format(Order_Date,'yyyy-MM'))
,cte3 as (
Select *
,lag(Furniture_Sales,1)over(order by Year_Month) as Prev_Month_Furniture_Sales
,lag(Office_Supplies_Sales,1)over(order by Year_Month) as Prev_Month_Office_Supplies_Sales
,lag(Technology_Sales,1)over(order by Year_Month) as Prev_Month_Technology_Sales
from cte2)
select Year_Month
,Furniture_Sales
,CONCAT(ROUND(COALESCE(100*(Furniture_Sales-Prev_Month_Furniture_Sales)/NULLIF(Prev_Month_Furniture_Sales,0),0),2),'%') as pct_change_in_furniture_sales
,Office_Supplies_Sales
,CONCAT(ROUND(COALESCE(100*(Office_Supplies_Sales-Prev_Month_Office_Supplies_Sales)/NULLIF(Prev_Month_Office_Supplies_Sales,0),0),2),'%') as pct_change_in_office_sales
,Technology_Sales
,CONCAT(ROUND(COALESCE(100*(Technology_Sales-Prev_Month_Technology_Sales)/NULLIF(Prev_Month_Technology_Sales,0),0),2),'%') as pct_change_in_technolgy_sales
from cte3;