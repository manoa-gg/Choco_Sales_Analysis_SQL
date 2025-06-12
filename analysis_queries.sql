##Sales Revenue Metric##
/* ANALYSIS: Total Sales Revenue vs Total Boxes Shipped per Sales Person [Query #1]
PURPOSE: Identify discrepancies between sales volume and revenue to optimize
	pricing and sales strategies
--------------------------------------------------*/
with tot_vs As (select sum(total_price) As total_sales,
			 sum(boxes_shipped) As total_boxes_sold, 
             sales_person,
			rank() over(order by sum(total_price) desc) As sales_rank,
            rank() over(order by sum(boxes_shipped) desc) As boxes_rank
			from choco_sales_2
			group by sales_person )
 select * 
 from tot_vs
 order by boxes_rank, sales_rank;
/* INSIGHT: Top 5 salespeople by volume do not match the top 5 by revenue, 
indicating a gap between volume and revenue performance
RECOMMENDATION:
Develop training programs focusing on value-based selling for volume-focused reps.*/

/* ANALYSIS: Sales Achieved by Sales Person Partitioned by Country [Query #2]
PURPOSE: Identify top-performing salespeople across different countries 
	and understand their sales strategies
--------------------------------------------------*/
with tsrc As (select sum(total_price) as part_rev, 
					 sum(boxes_shipped) as part_qty,
                     count(sales_person) as part_sales,
                     sales_person, country,
			rank() over(partition by country order by sum(total_price) desc) As rev_rank,
            rank() over(partition by country order by sum(boxes_shipped) desc) As qty_rank,
            rank() over(partition by country order by count(sales_person) desc) As sales_rank
			from choco_sales_2
			group by sales_person, country),
	ts As (select sum(total_price) as total_rev,
				  sum(boxes_shipped) as total_qty,
				  count(sales_person) as total_sales
		  from choco_sales_2)
select round(tsrc.part_rev/ts.total_rev *100, 2) As perc_rev,
	   round(tsrc.part_qty/ts.total_qty *100, 2) As perc_qty,
       round(tsrc.part_sales/ts.total_sales *100, 2) As perc_sales,
		tsrc.sales_person, tsrc.country, tsrc.part_rev, tsrc.part_qty, 
        tsrc.part_sales, tsrc.rev_rank, tsrc.qty_rank 
from tsrc
cross join ts
where tsrc.part_rev >= 50000 and tsrc.part_qty>= 900
order by tsrc.country, tsrc.rev_rank;
/* INSIGHT: Madelene Upcott ranks #1 in revenue across two different markets (New Zealand & UK), 
demonstrating exceptional cross-market execution. Despite different competitive landscapes, 
she consistently delivers high-value sales (NZ: 67,550 | UK: 71,330), 
suggesting strong client relationships or premium product specialization.
RECOMMENDATION:
Study Madelene Upcott's sales tactics to identify best practices for cross-market success.*/

/* ANALYSIS: Count Number of Sales Achieved from Each Country [Query #3]
PURPOSE: Assess market performance and identify growth opportunities by comparing 
	the number of qualified salespeople across countries
--------------------------------------------------*/
with tsrc As (select sum(total_price) as part_rev, 
					 sum(boxes_shipped) as part_qty,
                     count(sales_person) as part_sales,
                     sales_person, country,
			rank() over(partition by country order by sum(total_price) desc) As rev_rank,
            rank() over(partition by country order by sum(boxes_shipped) desc) As qty_rank,
            rank() over(partition by country order by count(sales_person) desc) As sales_rank
			from choco_sales_2
            group by sales_person, country
            having sum(total_price) >= 50000 and sum(boxes_shipped)>= 900)
select country, count(country) As sales_achieved
from tsrc
group by country;
/* INSIGHT: Australia dominates with 8 qualified salespeople, nearly double Canada and 
New Zealand (4 each), indicating significantly stronger market penetration and 
sales force effectiveness in Australia compared to other regions.
RECOMMENDATION:
Investigate Australia's sales strategies to identify best practices for market penetration and 
sales force effectiveness.*/

/* ANALYSIS: Boxes Shipped x Revenue Correlation [Query #4]
PURPOSE: Assess the relationship between boxes shipped and total sales revenue 
	to understand sales dynamics
--------------------------------------------------*/
with bsr As (select sum(total_price) as total_sales,
			 sum(boxes_shipped) as total_boxes_sold, 
             sales_person, country
			from choco_sales_2
			group by sales_person, country)
 select 
 (count(*) * sum(total_sales*total_boxes_sold) - sum(total_sales) * sum(total_boxes_sold))/
 (sqrt(count(*)* sum(total_sales * total_sales) - sum(total_sales) * sum(total_sales))*
 sqrt(count(*) * sum(total_boxes_sold * total_boxes_sold) - sum(total_boxes_sold) * sum(total_boxes_sold)))
 as sales_boxes_correlation
 from bsr;
 /* INSIGHT: The positive correlation (0.51) confirms that higher box shipments generally 
drive higher revenue, but the relationship isn't dominant, indicating other factors like product mix, pricing, and customer type heavily influence revenue.
RECOMMENDATION:
Investigate the impact of product mix, pricing, and customer type on revenue 
to identify opportunities for improving sales performance.*/
 
/* ANALYSIS: Sales Overview by Country [Query #5]
PURPOSE: Evaluate overall sales performance and identify key market strategies by 
	analyzing total revenue, average price per box, and average boxes and revenue per transaction 
    across countries.
--------------------------------------------------*/
 select country, count(country), 
		sum(total_price), sum(boxes_shipped), 
        round((sum(total_price)/ sum(boxes_shipped)), 2) As avg_price,
        round((sum(boxes_shipped)/ count(country)), 2) As avg_box_per_transaction,
        round((sum(total_price)/ count(country)), 2) As avg_rev_per_transaction
 from choco_sales_2
 group by country
 order by sum(total_price) desc;
/* INSIGHT: The UK achieves the highest average revenue per transaction ($5,909) and 
highest boxes per transaction (170), indicating superior sales effectiveness 
compared to other markets, despite ranking second in total revenue.
RECOMMENDATION:
Investigate UK sales strategies to identify best practices for securing larger orders 
and better value realization.*/

/* ANALYSIS: Overview by Month [Query #6]
PURPOSE: Identify monthly sales trends and seasonal impacts on performance
--------------------------------------------------*/
 select `month`, count(distinct sales_person), 
		sum(total_price), sum(boxes_shipped), 
        round((sum(total_price)/ sum(boxes_shipped)), 2) As avg_price,
        round((sum(boxes_shipped)/ count(distinct sales_person)), 2) As avg_box_per_sp,
        round((sum(total_price)/ count(distinct sales_person)), 2) As avg_rev_per_sp
 from choco_sales_2
 group by `month`
 order by sum(total_price) desc;
 /* INSIGHT: January leads in total revenue and average revenue per salesperson, 
suggesting a strong start to the year, possibly due to holiday shopping or new year promotions.
RECOMMENDATION:
	- Analyze January's sales strategies and customer behavior to identify effective tactics.*/

/* ANALYSIS: Running Total Partition by Country [Query #7]
PURPOSE: Track cumulative sales performance over time for each country 
	to identify growth trends and seasonal patterns
--------------------------------------------------*/
select country, `month`,
	   sum(total_price) as tot_rev, sum(boxes_shipped) tot_box,
	   sum(sum(total_price)) over(partition by country order by `month`) As rt_rev,
	   sum(sum(boxes_shipped)) over(partition by country order by `month`) As rt_box
from choco_sales_2
group by country, `month`
order by country, `month`;
/*INSIGHT: Australia consistently shows strong monthly revenue, with a significant cumulative 
total by the end of the year, indicating a stable sales performance throughout the year.
RECOMMENDATION:
Analyze Australia's sales strategies and customer engagement to identify best practices 
for maintaining consistent sales performance.*/

/* ANALYSIS: Top Product per Month Based on Revenue & Quantity [Query #8]
PURPOSE: Identify top-performing products each month to optimize inventory 
	and marketing strategies
--------------------------------------------------*/
with product_rank As (select sum(total_price) as stp, `month`, product, 
						sum(boxes_shipped) as sbs,
						rank () over (partition by `month` 
							order by sum(total_price) desc) as rev_rank,
                        rank () over (partition by `month` 
							order by sum(boxes_shipped) desc) as qty_rank    
						from choco_sales_2
                        group by `month`, product)
select product, `month`, round((rev_rank + qty_rank)/2, 2) as avg_rank, rev_rank, qty_rank 
from product_rank
where ((rev_rank + qty_rank)/2) <= 5
group by product, `month`
order by `month`, product asc;
/* INSIGHT: Products like "99% dark & pure" and "organic choco syrup" consistently 
rank high in both revenue and quantity, indicating strong market demand and sales performance.
RECOMMENDATION:
Focus on promoting and stocking high-ranking products like "99% dark & pure" and 
"organic choco syrup" to capitalize on their strong performance.*/

/* ANALYSIS: Monthly Sales Growth Rate [Query #9]
PURPOSE: Identify monthly sales growth trends to inform forecasting and strategic planning
------------------------------------------------*/
with 	monthly_sales As (select date_format(date, '%Y-%m') As sales_month,
								sum(total_price) As monthly_revenue,
								lag(sum(total_price)) over (
									order by date_format(date, '%Y-%m')) as prev_month_revenue
                          from choco_sales_2
                          group by sales_month),
		monthly_qty  As (select date_format(date, '%Y-%m') As sales_month,
								sum(boxes_shipped) As monthly_boxes,
								lag(sum(boxes_shipped)) over (
									order by date_format(date, '%Y-%m')) as prev_month_boxes
                          from choco_sales_2
                          group by sales_month)
select monthly_sales.sales_month, monthly_sales.monthly_revenue, monthly_qty.monthly_boxes,
	   round(((monthly_revenue - prev_month_revenue) / 
				prev_month_revenue) * 100, 2) as growth_rate_percent,
	   round(((monthly_boxes - prev_month_boxes) / 
				prev_month_boxes) * 100, 2) as sales_rate_percent
from monthly_sales inner join monthly_qty on 
		monthly_sales.sales_month = monthly_qty.sales_month
order by sales_month;
/* INSIGHT: The growth rate in February was -21.95%, indicating a significant drop in revenue 
compared to January. However, there was a strong rebound in June with a growth rate of 14.91%.
RECOMMENDATION:
Investigate the factors that contributed to the drop in February and the rebound in June 
to better understand sales trends and plan for future growth.*/	

/* ANALYSIS: Share of Sales Based on Revenue and Quantity per Product [Query #10]
PURPOSE: Determine the market share of each product based on revenue and quantity to identify 
	top contributors to sales
--------------------------------------------------------------------------------*/
with ts As   (select sum(total_price) As total_revenue, sum(boxes_shipped) As total_qty  
			 from choco_sales_2),
     dsp As  (select sum(total_price) As dist_revenue,
					 sum(boxes_shipped) As dist_qty,
                     product
			 from choco_sales_2
             group by product)
select dsp.product,
    round((dsp.dist_revenue/ ts.total_revenue)* 100, 2) As percentage_revenue,
    round((dsp.dist_qty/ ts.total_qty)* 100, 2) As percentage_qty
from dsp
cross join ts
order by percentage_revenue desc;
/*INSIGHT: "Smooth Silky Salty" leads in both revenue and quantity share, indicating strong 
overall performance and market acceptance.
RECOMMENDATION:
Focus on promoting and stocking "Smooth Silky Salty" to capitalize on its strong 
performance and market share.*/

/* ANALYSIS: Product-Country Revenue Heatmap [Query #11]
PURPOSE: Identify top-performing products in each country to tailor marketing and 
	distribution strategies
------------------------------------------------------*/
select country,
sum(case when product = 'mint chip choco' then total_price else 0 end) as mint_chip_choco_rev,
sum(case when product = '85% dark bars' then total_price else 0 end) as 85_dark_bars_rev,
sum(case when product = 'peanut butter cubes' then total_price else 0 end) as peanut_butter_cubes_rev,
sum(case when product = 'smooth silky salty' then total_price else 0 end) as smooth_silky_salty_rev, 
sum(case when product = '99% dark & pure' then total_price else 0 end) as 99_dark_pure_rev,  
sum(case when product = 'after nines' then total_price else 0 end) as after_nine_rev,
sum(case when product = '50% dark bites' then total_price else 0 end) as 50_dark_bites_rev, 
sum(case when product = 'orange choco' then total_price else 0 end) as orange_choco_rev,
sum(case when product = 'eclairs' then total_price else 0 end) as eclairs_rev,
sum(case when product = 'drinking choco' then total_price else 0 end) as drinking_choco_rev,
sum(case when product = 'organic choco syrup' then total_price else 0 end) as organic_choco_syrup_rev,
sum(case when product = 'milk bars' then total_price else 0 end) as milk_bars_rev,
sum(case when product = 'spicy special slims' then total_price else 0 end) as spicy_special_slims_rev,
sum(case when product = 'fruit & nut bars' then total_price else 0 end) as fruit_nut_bars_rev,
sum(case when product = 'white choco' then total_price else 0 end) as white_choco_rev,
sum(case when product = 'manuka honey choco' then total_price else 0 end) as manuka_honey_choco_rev,
sum(case when product = 'almond choco' then total_price else 0 end) as almond_choco_rev,
sum(case when product = 'raspberry choco' then total_price else 0 end) as raspberry_choco_rev,
sum(case when product = 'choco coated almonds' then total_price else 0 end) as choco_coated_almonds_rev,
sum(case when product = "baker's choco chips" then total_price else 0 end) as bakers_choco_chips_rev,
sum(case when product = 'caramel stuffed bars' then total_price else 0 end) as caramel_stuffed_bars_rev,
sum(case when product = '70% dark bites' then total_price else 0 end) as 70_dark_bites_rev
from choco_sales_2
group by country;
/* INSIGHT: "Smooth Silky Salty" and "50% Dark Bites" consistently generate high revenue 
across multiple countries, indicating broad market acceptance and strong performance.
RECOMMENDATION:
Focus on promoting and stocking "Smooth Silky Salty" and "50% Dark Bites" 
in all countries to capitalize on their strong performance and market share.*/

/* ANALYSIS: Product-Country Quantity Heatmap [Query #12]
PURPOSE: Identify top-performing products in each country based on quantity sold 
	to tailor inventory and distribution strategies.
-----------------------------------------------------*/
select country,
sum(case when product = 'mint chip choco' then boxes_shipped else 0 end) as mint_chip_choco_qty,
sum(case when product = '85% dark bars' then boxes_shipped else 0 end) as 85_dark_bars_qty,
sum(case when product = 'peanut butter cubes' then boxes_shipped else 0 end) as peanut_butter_cubes_qty,
sum(case when product = 'smooth silky salty' then boxes_shipped else 0 end) as smooth_silky_salty_qty, 
sum(case when product = '99% dark & pure' then boxes_shipped else 0 end) as 99_dark_pure_qty,  
sum(case when product = 'after nines' then boxes_shipped else 0 end) as after_nine_qty,
sum(case when product = '50% dark bites' then boxes_shipped else 0 end) as 50_dark_bites_qty, 
sum(case when product = 'orange choco' then boxes_shipped else 0 end) as orange_choco_qty,
sum(case when product = 'eclairs' then boxes_shipped else 0 end) as eclairs_qty,
sum(case when product = 'drinking choco' then boxes_shipped else 0 end) as drinking_choco_qty,
sum(case when product = 'organic choco syrup' then boxes_shipped else 0 end) as organic_choco_syrup_qty,
sum(case when product = 'milk bars' then boxes_shipped else 0 end) as milk_bars_qty,
sum(case when product = 'spicy special slims' then boxes_shipped else 0 end) as spicy_special_slims_qty,
sum(case when product = 'fruit & nut bars' then boxes_shipped else 0 end) as fruit_nut_bars_qty,
sum(case when product = 'white choco' then boxes_shipped else 0 end) as white_choco_qty,
sum(case when product = 'manuka honey choco' then boxes_shipped else 0 end) as manuka_honey_choco_qty,
sum(case when product = 'almond choco' then boxes_shipped else 0 end) as almond_choco_qty,
sum(case when product = 'raspberry choco' then boxes_shipped else 0 end) as raspberry_choco_qty,
sum(case when product = 'choco coated almonds' then boxes_shipped else 0 end) as choco_coated_almonds_qty,
sum(case when product = "baker's choco chips" then boxes_shipped else 0 end) as bakers_choco_chips_qty,
sum(case when product = 'caramel stuffed bars' then boxes_shipped else 0 end) as caramel_stuffed_bars_qty,
sum(case when product = '70% dark bites' then boxes_shipped else 0 end) as 70_dark_bites_qty
from choco_sales_2
group by country;
/* INSIGHT: "Smooth Silky Salty" and "50% Dark Bites" consistently generate 
high quantities sold across multiple countries, indicating strong consumer demand.
RECOMMENDATION:
Focus on promoting and stocking "Smooth Silky Salty" and "50% Dark Bites" in all countries 
to capitalize on their strong performance and market share.*/

/* ANALYSIS: Country-Sales Person Revenue Heatmap [Query #13]
PURPOSE: Identify top-performing salespeople in each country based on revenue to tailor 
	sales strategies and resource allocation
--------------------------------------------------------*/
select sales_person,
sum(case when country = 'uk' then total_price else 0 end) as uk_rev,
sum(case when country = 'india' then total_price else 0 end) as india_rev,
sum(case when country = 'australia' then total_price else 0 end) as australia_rev,
sum(case when country = 'new zealand' then total_price else 0 end) as new_zealand_rev, 
sum(case when country = 'usa' then total_price else 0 end) as usa_rev,  
sum(case when country = 'canada' then total_price else 0 end) as canada_rev
from choco_sales_2
group by sales_person;
/* INSIGHT: Salespeople like "Madelene Upcott" and "Ches Bonnell" consistently generate high 
revenue across multiple countries, indicating strong sales performance and market acceptance.
RECOMMENDATION:
Focus on promoting and supporting top-performing salespeople like "Madelene Upcott" and 
"Ches Bonnell" to capitalize on their strong performance and market share.*/

/* ANALYSIS: Country-Sales Person Quantity Heatmap [Query #14]
PURPOSE: Identify top-performing salespeople in each country based on quantity sold to tailor 
	sales strategies and resource allocation
-----------------------------------------------------------*/
select sales_person,
sum(case when country = 'uk' then boxes_shipped else 0 end) as uk_qty,
sum(case when country = 'india' then boxes_shipped else 0 end) as india_qty,
sum(case when country = 'australia' then boxes_shipped else 0 end) as australia_qty,
sum(case when country = 'new zealand' then boxes_shipped else 0 end) as new_zealand_qty, 
sum(case when country = 'usa' then boxes_shipped else 0 end) as usa_qty,  
sum(case when country = 'canada' then boxes_shipped else 0 end) as canada_qty
from choco_sales_2
group by sales_person;
/* INSIGHT: Salespeople like "Madelene Upcott" and "Ches Bonnell" consistently generate high quantities 
sold across multiple countries, indicating strong sales performance and market acceptance.
RECOMMENDATION:
Focus on promoting and supporting top-performing salespeople like "Madelene Upcott" and 
"Ches Bonnell" to capitalize on their strong performance and market share. */

select distinct product
from choco_sales_2;

#KPIs and STRATEGIC RECOMMENDATIONS
/*ANALYSIS: Salesperson Performance and Regional/Product Expertise
PURPOSE: Identify top-performing salespeople and their areas of expertise to tailor sales 
strategies and resource allocation.
--------------------------------------------------------------------------------------*/
with	sales_totals as(
			select sales_person, 
			sum(total_price) as total_revenue,
			sum(boxes_shipped) as total_quantity,
			rank() over(order by sum(total_price)desc) as global_rev_rank,
			rank() over(order by sum(boxes_shipped)desc) as global_qty_rank
			from choco_sales_2
			group by sales_person),
		top_regions as(
			select sales_person,
			country as top_country, 
            sum(total_price) as revenue_in_top_country,
            row_number() over(partition by sales_person order by sum(total_price) desc) as country_rank
            from choco_sales_2
            group by sales_person, country),
         top_products as( 
			select sales_person,
			product as top_product,
            sum(total_price) as revenue_from_top_product,
            row_number() over(partition by sales_person order by sum(total_price) desc) as product_rank
            from choco_sales_2
            group by sales_person, product)
select st.sales_person, st.total_revenue,
	   st.total_quantity, st.global_rev_rank,
       st.global_qty_rank, tr.top_country,
       round((tr.revenue_in_top_country/st.total_revenue)*100, 2) as perc_rev_from_top_country,
       tp.top_product,
       round((tp.revenue_from_top_product/ st.total_revenue)*100, 2) as perc_rev_from_top_product
from sales_totals st
left join  top_regions tr
	on st.sales_person = tr.sales_person and tr.country_rank = 1
left join top_products tp
	on st.sales_person = tp.sales_person and tp.product_rank = 1
order by st.global_rev_rank;
/*INSIGHT: Top-performing salespeople like "Ches Bonnell" and "Oby Sorrel" not only generate high 
revenue and quantity sold but also have a significant concentration of their sales in specific 
countries and products, indicating strong regional and product expertise.
RECOMMENDATION:
Leverage the regional and product expertise of top-performing salespeople 
like "Ches Bonnell" and "Oby Sorrel" by assigning them to focus on their top-performing countries 
and products to further enhance sales performance.*/

/*ANALYSIS: Top Products by Salesperson Performance
PURPOSE: Identify the most frequently top-performing products across salespeople to understand 
product popularity and sales effectiveness.
-----------------------------------------------------*/ 
with	sales_totals as(
			select sales_person,
			sum(total_price) as total_revenue,
			sum(boxes_shipped) as total_quantity,
			rank() over(order by sum(total_price)desc) as global_rev_rank,
			rank() over(order by sum(boxes_shipped)desc) as global_qty_rank
			from choco_sales_2
			group by sales_person),
		top_regions as(
			select sales_person,
			country as top_country, 
            sum(total_price) as revenue_in_top_country,
            row_number() over(partition by sales_person order by sum(total_price) desc) as country_rank
            from choco_sales_2
            group by sales_person, country),
         top_products as( 
			select sales_person,
			product as top_product,
            sum(total_price) as revenue_from_top_product,
            row_number() over(partition by sales_person order by sum(total_price) desc) as product_rank
            from choco_sales_2
            group by sales_person, product)
select tp.top_product, count(tp.top_product)
from sales_totals st
left join  top_regions tr
	on st.sales_person = tr.sales_person and tr.country_rank = 1
left join top_products tp
	on st.sales_person = tp.sales_person and tp.product_rank = 1
group by tp.top_product
order by count(tp.top_product) desc;
/*INSIGHT: "Smooth Silky Salty" and "After Nines" are the most frequently top-performing 
products across salespeople, indicating strong market acceptance and sales performance.
RECOMMENDATION:
Focus on promoting and stocking "Smooth Silky Salty" and "After Nines" to capitalize on 
their strong performance and market share.*/

/*ANALYSIS: Product Seasonality Analysis: Monthly Sales Trends & Inventory Recommendations
PURPOSE: Identify seasonal trends in product sales to optimize inventory levels and 
enhance sales performance
------------------------------------------------------------------------------------------*/
with	monthly_sales	as(
		select product,
			date_format(`date`, '%Y-%m') as sales_month,
			sum(total_price) as monthly_rev,
			sum(boxes_shipped) as monthly_qty,
			round(((sum(total_price)- lag(sum(total_price)) 
				over (partition by product order by date_format(`date`, '%Y-%m'))) /
				lag(sum(total_price)) over (partition by product order by date_format(
				`date`, '%Y-%m')))* 100, 2) As growth_rate
		from choco_sales_2
        group by product, sales_month),
        seasonality_flags as(
        select product, sales_month, 
			monthly_rev, monthly_qty,
			growth_rate, 
			rank() over ( partition by product order by monthly_rev desc) as peak_month_rank,
			avg(monthly_rev) over (partition by product) as avg_off_peak_rev
		from monthly_sales)
select product, sales_month, monthly_rev,
	monthly_qty, growth_rate, avg_off_peak_rev,
	case
		when peak_month_rank <= 3 then 'PEAK : Increase Stock'
        else 'OFF-PEAK: Reduce Stock'
	end as inventory_action,
    round((monthly_rev/ avg_off_peak_rev)*100, 2) as inventory_adjustment_percent
    from seasonality_flags
    order by product, sales_month;
/*INSIGHT: Products like "Smooth Silky Salty" and "After Nines" show significant peaks in 
certain months, indicating strong seasonal demand. These products should be prioritized for 
increased stock during their peak months.
RECOMMENDATION:
Increase inventory for products like "Smooth Silky Salty" and "After Nines" during their peak 
months to meet high demand and reduce stock during off-peak months to avoid overstocking.*/    
    
/*ANALYSIS: Product Seasonality Analysis: Monthly Sales Trends & Inventory Adjustments
PURPOSE: Identify seasonal trends in product sales to optimize inventory levels and enhance 
sales performance.
---------------------------------------------------------------------------------------*/
with	monthly_sales	as(
		select product,
			date_format(`date`, '%Y-%m') as sales_month,
			sum(total_price) as monthly_rev,
			sum(boxes_shipped) as monthly_qty,
			round(((sum(total_price)- lag(sum(total_price)) 
				over (partition by product order by date_format(`date`, '%Y-%m'))) /
				lag(sum(total_price)) over (partition by product order by date_format(
				`date`, '%Y-%m')))* 100, 2) As growth_rate
		from choco_sales_2
        group by product, sales_month),
        seasonality_flags as(
        select product, sales_month, 
			monthly_rev, monthly_qty,
			growth_rate, 
			avg(monthly_rev) over (partition by product) as avg_off_peak_rev
		from monthly_sales)
select product, sales_month, monthly_rev,
	monthly_qty, growth_rate, avg_off_peak_rev,
	case
		when monthly_rev >= avg_off_peak_rev then 'PEAK : Increase Stock'
        else 'OFF-PEAK: Reduce Stock'
	end as inventory_action,
    round((monthly_rev/ avg_off_peak_rev)*100, 2) as inventory_adjustment_percent
    from seasonality_flags
    order by product, sales_month;    
/*INSIGHT: Products like "Smooth Silky Salty" and "After Nines" show significant peaks 
in certain months, indicating strong seasonal demand. These products should be prioritized 
for increased stock during their peak months.
RECOMMENDATION:
Increase inventory for products like "Smooth Silky Salty" and "After Nines" during their peak 
months to meet high demand and reduce stock during off-peak months to avoid overstocking.*/

/*ANALYSIS: Correlation Between Pricing Strategies and High Sales Volume
PURPOSE: Assess how different pricing strategies impact sales volume to optimize pricing 
and inventory management
---------------------------------------------------------------------*/   
with 	calculation	as(
			select product, price,
				sum(boxes_shipped) as total_qty
			from choco_sales_2
			group by product, price),
        price_tiers as(
			select product, price, total_qty,
				case
					when price <= 30 then 'Budget(<=30$)'
                    when price > 30 and price <=105 then 'Mid-Range (30$-105$)'
                    else 'Premium (> 105$)'
				end as price_tier
			from calculation),
		sales_analysis as(
			select price_tier,
				count(product) as products_in_tier,
				round(avg(price), 2) as avg_price,
                sum(total_qty) as total_qty_shipped,
				round(sum(total_qty)/ count(product), 2) as avg_qty_per_product
            from price_tiers
            group by price_tier)
select 
	price_tier, products_in_tier, avg_price,
    total_qty_shipped, avg_qty_per_product,
    round((total_qty_shipped - lag(total_qty_shipped) over (order by avg_price)) /
		lag(total_qty_shipped) over (order by avg_price) * 100, 2) as sales_growth_vs_prev_tier
from sales_analysis
order by avg_price;        
/*INSIGHT: Budget-priced products (<= $30) have the highest total quantity shipped, indicating 
strong demand for lower-priced items. As price increases, the total quantity shipped decreases 
significantly, with a notable drop between mid-range and premium products.
RECOMMENDATION:
Focus on promoting budget-priced products to capitalize on high demand. Consider strategies 
to increase the appeal of mid-range and premium products, such as bundling or discounts, 
to boost their sales volume.*/

/*ANALYSIS: Correlation Between Pricing Strategies and High Sales Volume Using Revenue
PURPOSE: Assess how different pricing strategies impact sales volume and revenue 
to optimize pricing and inventory management.
------------------------------------------------------------------------------------*/ 
with 	calculation	as(
			select product, price,
				sum(boxes_shipped) as total_qty,
				sum(total_price) as total_rev
            from choco_sales_2
			group by product, price),
        price_tiers as(
			select product, price, total_qty, total_rev,
				case
					when price <= 30 then 'Budget(<=30$)'
                    when price > 30 and price <=105 then 'Mid-Range (30$-105$)'
                    else 'Premium (> 105$)'
				end as price_tier
			from calculation),
		sales_analysis as(
			select price_tier,
				count(product) as transaction_in_tier,
				round(avg(price), 2) as avg_price,
                sum(total_qty) as total_qty_shipped,
                sum(total_rev) as total_rev_sales,
				round(sum(total_qty)/ count(product), 2) as avg_qty_per_product
            from price_tiers
            group by price_tier)
select 
	price_tier, transaction_in_tier, avg_price,
    total_qty_shipped, avg_qty_per_product, total_rev_sales,
    round((total_rev_sales - lag(total_rev_sales) over (order by avg_price)) /
		lag(total_rev_sales) over (order by avg_price) * 100, 2) as tier_rev_vs_prev_tier,
	round((total_qty_shipped - lag(total_qty_shipped) over (order by avg_price)) /
		lag(total_qty_shipped) over (order by avg_price) * 100, 2) as sales_growth_vs_prev_tier
from sales_analysis
order by avg_price;            
/*INSIGHT: Budget-priced products (<= $30) have the highest total quantity shipped and 
a significant total revenue, indicating strong demand for lower-priced items. As price 
increases, the total quantity shipped decreases significantly, with a notable drop 
between mid-range and premium products. However, mid-range products generate the highest total 
revenue, suggesting a balance between price and volume.
RECOMMENDATION:
Focus on promoting budget-priced products to capitalize on high demand and volume. 
Optimize mid-range products to maintain high revenue while ensuring competitive pricing. 
Consider strategies to increase the appeal of premium products, such as bundling or discounts, 
to boost their sales volume and revenue.*/

/*ANALYSIS: Sales Trend by Day of the Week
PURPOSE: Identify patterns in sales performance across different days of the week to optimize 
staffing and marketing efforts
----------------------------------------*/
select `day`, sum(total_price) as total_rev, sum(boxes_shipped) as total_qty,
avg(total_price) as avg_daily_rev, avg(boxes_shipped) as avg_daily_qty
from choco_sales_2
group by `day`
order by total_rev desc;
/*INSIGHT: Monday has the highest total revenue and quantity sold, indicating strong sales 
performance at the start of the week. Conversely, Friday shows lower sales volume and revenue, 
suggesting a potential slowdown towards the end of the week.
RECOMMENDATION:
Focus on maximizing sales efforts on Monday by ensuring adequate staffing and targeted 
promotions. Investigate the reasons for lower sales on Friday and consider strategies to boost 
sales, such as weekend promotions or extended hours.*/
                    
/*ANALYSIS: Sales Trend by Day of the Month
PURPOSE: Identify patterns in sales performance across different days of the month to 
optimize marketing and operational strategies
-----------------------------------------*/
select `month`, 
sum(total_price) as total_rev, sum(boxes_shipped) as total_qty,
round(sum(total_price)/ count(distinct `date`)) as avg_monthly_rev, 
round(sum(boxes_shipped)/ count(distinct `date`)) as avg_monthly_qty
from choco_sales_2
group by `month`
order by total_rev desc;                    
/*INSIGHT: The first day of the month (Day 1) has the highest total revenue and quantity sold,
indicating strong sales performance at the beginning of the month. Conversely, Month 4 shows 
lower sales volume and revenue, suggesting a potential slowdown towards the middle of the month.
RECOMMENDATION:
Focus on maximizing sales efforts on the first day of the month by ensuring adequate staffing 
and targeted promotions. Investigate the reasons for lower sales on Month 4 and consider 
strategies to boost sales, such as mid-month promotions or special offers.*/