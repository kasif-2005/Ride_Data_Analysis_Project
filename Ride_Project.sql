create table ride(
services varchar(100),
date_of_ride date,
time_of_ride time,
ride_status varchar(50),
source_of_ride varchar(100),
destination varchar (100),
duration int,
ride_id varchar(50),
distance numeric(5,2),
ride_charge numeric(5,2),
misc_charge numeric(5,2),
total_fare numeric(7,2),
payment_method varchar(100)
);

select Round (total_fare, 2)
from ride;

copy ride from 'D:\(DATA) Data Analysis\rides_data.csv' delimiter ',' csv header;

--Show all rides in the table.

select * from ride;

--Display the services, source_of_ride, destination, and total_fare of each ride.

select services, source_of_ride, destination, total_fare from ride;

--Find all rides that are marked as 'Completed'.

select * from ride
where ride_status = 'completed';

--List rides where the total_fare is greater than 100.

select * from ride
where total_fare >100;

--Show the rides sorted by date_of_ride (newest first).

select * from ride
order by date_of_ride desc;

--Count how many rides were completed.

select count(ride) from ride
where ride_status = 'completed';

--Find the average fare of all rides.

select avg(total_fare) from ride;

--Get the total distance traveled across all rides.

select sum(distance) from ride;

--Show the highest fare and lowest fare.

select * from ride
where total_fare = (select max(total_fare)from ride)

union all 

select * from ride
where total_fare = (select min(total_fare)from ride);

--Group rides by payment_method and show the total revenue for each payment method.

select sum(total_fare) as total_revenue, payment_method
from ride
group by payment_method
order by sum(total_fare) desc;

--Find how many rides each service (services) has completed.

select services, count(ride_status) as completed_rides
from ride
group by services, ride_status
having ride_status = 'completed';

--List all rides where misc_charge is greater than ride_charge.

select * from ride
where misc_charge>ride_charge;

--Show the top 5 most expensive rides (highest total_fare).

select * from ride
order by total_fare desc
limit 5;

--Find rides where duration is above the average duration of all rides.

select * from ride
where duration>(select avg(duration)from ride);

--Get the total fare per day (date_of_ride) and order it by highest revenue day.

select date_of_ride, sum(total_fare)as total_revenue from ride
group by date_of_ride
order by sum(total_fare) desc;

--Show the cumulative revenue (running total) by date_of_ride. (Uses window functions in PostgreSQL/MySQL 8+/SQL Server)

select date_of_ride,
sum(total_fare) as daily_total,
sum(sum(total_fare)) over (order by  date_of_ride) as running_total_date
from ride
group by date_of_ride
order by date_of_ride;

--Find the most frequently used destination.

select destination, count(destination) as frequently_used
from ride
group by destination
order by count(destination) desc;

--Calculate the average fare per km (total_fare / distance) for each ride.

select * ,
total_fare/distance as average_fare_km
from ride;

--Create a report that shows:
--Total rides
--Total revenue
--Average fare per ride
--Average duration

select count(ride_id),
sum(total_fare) as total_revenue,
avg(total_fare) as avg_fare_per_ride,
avg(duration) as _avg_dur_per_ride
from ride
where ride_status = 'completed';

--Find rides where total_fare ≠ ride_charge + misc_charge.

select * from ride
where total_fare != ride_charge + misc_charge;

--Identify rides with missing source_of_ride or destination.

select * from ride
where source_of_ride is null or destination is null;

--Show duplicate ride_id values (if any).

select ride_id, count(*) as ride_count
from ride
group by ride_id
having count(*)>1;

--Calculate average fare per km (total_fare / distance) for each ride.

select *, 
(total_fare/distance) as avg_fare_per_km
from ride;

--Find the top 3 services (services) that generated the most revenue.

select services, sum(total_fare) as total_revenue
from ride
group by services
order by sum(total_fare) desc
limit 3;

--Show the average ride duration per service.

select 
services, avg(duration) as avg_ride_dura
from ride
group by services
order by avg(duration) desc;

--Rank all rides per day by total_fare (use RANK() or DENSE_RANK()).

select *, 
rank() over (partition by date_of_ride order by total_fare desc ) as rnk_of_ride_day
from ride
order by date_of_ride, rnk_of_ride_day ;


--For each ride, show the previous ride’s fare (use LAG()).

select *, 
LAG(total_fare) over(partition by services order by total_fare) as prv_ride_fare
from ride
order by services, prv_ride_fare;

--For each ride, show the next ride’s fare (use LEAD()).

select *, 
lead(total_fare) over (partition by services order by total_fare) as nxt_ride_fare
from ride
order by services, nxt_ride_fare;

--Find the percentage contribution of each ride’s fare to that day’s revenue:

select*, 
total_fare*100/sum(total_fare) over (partition by date_of_ride) as total_per
from ride
order by date_of_ride, total_per desc;

--Show average rides per day of the week (Monday, Tuesday, …).

select
to_char(date_of_ride, 'day') as day_of_week,
count(*)::decimal/count(distinct date_of_ride) as avg_ride_per_day
from ride
group by to_char(date_of_ride, 'day')
order by min(date_of_ride);


--Find rides taken during peak hours (e.g., 7–9 AM, 5–7 PM).select ride_id, time_of_ride from ridegroup by time_of_ride, ride_id;

select ride_id, time_of_ride
from ride
where(time_of_ride>= '07:00:00' and time_of_ride >= '09:00:00')
or(time_of_ride>= '17:00:00' and time_of_ride >= '19:00:00')
order by time_of_ride;

--Show total revenue per month.

SELECT 
    TO_CHAR(date_of_ride, 'YYYY-MM') AS month_year,
    SUM(total_fare) AS total_revenue
FROM ride
GROUP BY TO_CHAR(date_of_ride, 'YYYY-MM')
ORDER BY sum(total_fare) desc;

--Total rides, completed rides, cancelled rides, and their percentages.

SELECT
    COUNT(*) AS total_rides,
    COUNT(CASE WHEN ride_status = 'completed' THEN 1 END) AS completed_rides,
    COUNT(CASE WHEN ride_status = 'cancelled' THEN 1 END) AS cancelled_rides,
    ROUND(
        COUNT(CASE WHEN ride_status = 'completed' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS pct_completed,
    ROUND(
        COUNT(CASE WHEN ride_status = 'cancelled' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS pct_cancelled
FROM ride;


--Daily revenue growth: compare each day’s total with the previous day.

select 
date_of_ride,
sum(total_fare) as daily_total,
lag(sum(total_fare)) over (order by date_of_ride) as perv_day_total,
sum(total_fare) - lag(sum(total_fare)) over (order by date_of_ride) as daily_growth
from ride
group by date_of_ride
order by date_of_ride;

--Find the day with the highest average fare per ride.

select date_of_ride,
avg(total_fare) as avg_fare
from ride
group by date_of_ride
order by avg_fare desc
limit 1;
