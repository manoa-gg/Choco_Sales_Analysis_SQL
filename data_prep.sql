drop database choco_sales;
create database if not exists choco_analysis;
use choco_analysis;

create table choco_sales_1
(sales_person varchar (255),
country varchar (255),
product varchar (255),
`date` date,
amount int,	
boxes_shipped int);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Chocolate Sales.csv' 
into table choco_sales_1
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
ignore 1 lines
(Sales_Person, Country, Product, @date_var, @amount_var, Boxes_Shipped)    
SET `Date` = STR_TO_DATE(@date_var, '%d-%b-%y'),  
    Amount = REPLACE(REPLACE(@amount_var, '$', ''), ',', '');

select *
from choco_sales_1
where (product is null or product = '') 
    or (sales_person is null or sales_person = '')
    or (country is null or country = '')
    or (amount is null or amount = '')
    or (boxes_shipped is null or boxes_shipped = '');
    
update choco_sales_1
set
	sales_person = trim(sales_person), 
    country = trim(country), 
    product = trim(product);
    
select sales_person, country, product, `date`, amount, boxes_shipped, count(*)
from choco_sales_1
group by sales_person, country, product, `date`, amount, boxes_shipped
having count(*) > 1;

update choco_sales_1
set
	sales_person = lower(sales_person),
    country = lower(country),
    product = lower(product);

select *
from choco_sales_1;

SELECT Amount, product, country 
FROM choco_sales_1  
WHERE Amount > (SELECT AVG(Amount) + 2 * STDDEV(Amount) FROM choco_sales_1);

select sales_person, count(sales_person) As csp
from choco_sales_1
group by sales_person
order by csp desc;

select product, count(product) As cp
from choco_sales_1
group by product
order by cp desc;

select country, count(country) As cc
from choco_sales_1
group by country
order by cc desc;

alter table choco_sales_1
add column `month` int,
add column price int,
add column `day` varchar (255),
rename column amount to total_price;

update choco_sales_1
set `month` = month(`date`),
	price = (total_price / boxes_shipped),
    `day` = date_format(`date`, '%W');

select distinct product
from choco_sales_1;

drop table choco_sales_2;

create table choco_sales_2
(sales_person varchar (255),
country varchar (255),
product varchar (255),
`date` date,
total_price int,	
boxes_shipped int,
`month` int,
price double,
`day` varchar (255));

insert into choco_sales_2
select *
from choco_sales_1;

select *
from choco_sales_2;

select `day`, count(`day`)
from choco_sales_2
group by `day`;

select `month`, count(`month`)
from choco_sales_2
group by `month`
order by count(`month`) desc;

select min(`date`), max(`date`), min(total_price), max(total_price),
	min(boxes_shipped), max(boxes_shipped), min(price), max(price)
from choco_sales_2;

select stddev(`date`), stddev(total_price), stddev(boxes_shipped), stddev(price)
from choco_sales_2;

select avg(total_price), avg(boxes_shipped), avg(price)
from choco_sales_2;

update choco_sales_2
set price = cast(total_price as decimal(10, 2)) / boxes_shipped;

update choco_sales_2
set product = 
	case
		when product = 'white choc' then 'white choco'
        when product = 'drinking coco' then 'drinking choco' 
        when product = 'smooth sliky salty' then 'smooth silky salty'
	end
where product in ('white choc', 'drinking coco', 'smooth sliky salty');

alter table choco_sales_2
modify column price decimal (10,2);

select product, min(price)
from choco_sales_2
group by product
order by min(price) asc;

select product, max(boxes_shipped)
from choco_sales_2
group by product
order by max(boxes_shipped) desc;