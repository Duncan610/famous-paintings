-- FAMOUS PAINTINGS DATABASE ANALYSIS
-- SOURCE: https://www.kaggle.com/datasets/mexwell/famous-paintings

create database if not exists famous_paintings;
use famous_paintings;

-- IMPORTED THE CSV TABLES WITH PYTHON WITH THE FOLLOWING CODE
-- import pandas as pd
-- from sqlalchemy import create_engine

-- engine = create_engine('mysql+mysqlconnector://root:password@localhost/famous_paintings')
-- tables = ['artist', 'canvas_size', 'image_link', 'museum_hours', 'museum', 'product_size', 'subject', 'work']

-- for table in tables:
--     df = pd.read_csv(f'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Data\\famous_paintings\\{table}.csv')
--     df.to_sql(table, con=engine, if_exists='replace', index=False)
    
                     -- ANALYSIS
-- number of unique artists in the dataset
select distinct count(full_name) as number_of_artists
from artist;

-- average years lived by the artists
select 
    round(avg(death-birth),0) as avg_lived
from artist;

-- most dominant nationality
select 
	nationality,
	count(nationality) as nationality_count
from artist
group by nationality; -- (The most dominant nationality among the artists is French)

-- painting styles in the dataset and the most dominant style
select 
	distinct style as distinct_style,
	count(style) as style_count
from artist
group by style
order by  style_count desc; -- (Baroque is the most dominant style used)

-- ranking the artists by age
select
	full_name,
    birth
from artist
order by birth asc; -- the youngest artist is Jan Van Eyck

-- paintings not in museums
select
	work.artist_id,
	a.full_name,
	count(*) as painting_not_in_museum
from famous_paintings.work
join artist as a
on work.artist_id = a.artist_id
where work.museum_id is null
group by work.artist_id, a.full_name;

-- average painting price per style
select 
	w.style,
    round(avg(ps.regular_price),2) as avg_reg_price,
    round(avg(ps.sale_price),2) as avg_sale_price
from work as w
join product_size as ps
on w.work_id = ps.work_id
group by w.style
order by avg_reg_price desc;

-- paintings that are displayed in multiple countries
with cte as (
	select distinct 
    a.full_name,
    m.country
    from artist as a
    join work as w
    on a.artist_id = w.artist_id
    join museum as m
    on w.museum_id = m.museum_id
)
select
	full_name,
    count(distinct country) as number_of_countries,
    group_concat(distinct country order by country separator ', ') as Countries
from cte
group by full_name
having count(distinct country) > 1
order by number_of_countries desc;

-- artists with the most paintings
with cte as (
select
    a.full_name,
    count(w.work_id) as number_of_paintings,
    rank() over (order by count(w.work_id) desc) as popularity_rank
from artist as a
join work as w on a.artist_id = w.artist_id
group by a.full_name
)
select * from cte 
where popularity_rank <=10;

-- the most common subjects of paintings
select 
	distinct subject as distinct_subject,
	count(subject) as count_subject
from subject
group by distinct_subject
order by count_subject desc;

-- checking whether there are paintings where the sale price is not equal to the regular price
select * 
from famous_paintings.product_size
where regular_price != sale_price;

-- Calculating the percentage difference between the sale price and regular price (average)
with cte as(
	select work.style, 
    round(avg(product_size.regular_price),2) as avg_reg_price,
    round(avg(product_size.sale_price),2) as avg_sale_price
    from product_size
    join work 
    on work.work_id = product_size.work_id
    group by work.style
)
select *,
    round(((avg_reg_price - avg_sale_price) / nullif(avg_reg_price, 0)) * 100, 2) as Difference
from cte;

-- Artist and museum containing the most expensive and least expensive paintings
with cte as (
select full_name as artist_name,
    work.name as painting_name,
    work.style as work_style,
    museum.name as museum_name,
    museum.city as museum_city,
    product_size.regular_price as price,
    row_number() over (order by product_size.regular_price desc) as rnk
from artist
    join work 
    on artist.artist_id = work.artist_id
    join museum
    on museum.museum_id = work.museum_id
    join product_size
    on product_size.work_id = work.work_id
)
select 
	artist_name,
    painting_name,
    museum_name,
    museum_city,
    work_style,
    price
from cte
where rnk = 1 or rnk = (select count(1) from cte);

-- painting which its sale price is less than 50% of its regular price
select
	w.name,
    ps.regular_price,
	ps.sale_price
from product_size as ps
join work as w
on ps.work_id = w.work_id
where sale_price < (0.5 * regular_price);

-- most expensive paintings, with museum_name, painting_name, artist_name
select 
    a.full_name as artist_name,
    w.name as painting_name,
    m.name as museum_name,
    ps.regular_price as price
from 
	artist as a
join work as w 
on a.artist_id = w.artist_id
join museum as m 
on w.museum_id = m.museum_id
join product_size as ps 
on w.work_id = ps.work_id
order by ps.regular_price desc
limit 5;

-- Total sales revenue by museum
select distinct
    m.name,
    sum(ps.sale_price) as total_sale_revenue
from museum as m
join work as w
on m.museum_id = w.museum_id
join product_size as ps
on ps.work_id = w.work_id
group by m.name
order by total_sale_revenue;

-- average sale price per artist
select 
	a.full_name,
    avg(ps.sale_price) as avg_sale_price
from artist as a
join work as w
on a.artist_id = w.artist_id
join product_size as ps
on w.work_id = ps.work_id
group by a.full_name
order by avg_sale_price desc;

-- painting count and average count per country
select
    m.country,
    count(w.work_id) as painting_count,
    round(avg(ps.regular_price), 2) as avg_regular_price,
    round(avg(ps.sale_price), 2) as avg_sale_price
from
    museum as m
join work as w 
on m.museum_id = w.museum_id
join product_size as ps 
on w.work_id = ps.work_id
group by m.country
order by painting_count desc;

-- How many museums are open every single day
select 
	  case when day = 'Thusday' then 'Thursday' else day
	  end as days,
	  COUNT(museum_id) as No_of_Museums_Open
from museum_hours
group by day
order by day;

-- city with the most number of museums
select city, count(museum_id) as No_of_Museums
from museum
group by city
order by No_of_Museums desc;

-- country with the most number of museums
select country, count(museum_id) as No_of_Museums
from museum
group by country
order by No_of_Museums desc;

-- view of painting_summary
create view painting_summary as
select
	a.artist_id,
    a.full_name as artist_name,
    m.country as artist_nationality,
    m.name as museum_name,
    w.style as painting_style,
    w.work_id
from
    artist as a
join work as w
on a.artist_id = w.artist_id
join museum as m
on m.museum_id = w.museum_id;











    
	





    




		
        







	