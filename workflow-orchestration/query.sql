#3
select count(1)
from public.yellow_tripdata
where extract(year from lpep_pickup_datetime) = 2020;



#4
select count(1)
from public.green_tripdata
where extract(year from lpep_pickup_datetime) = 2020;

#5
select count(1)
from public.green_tripdata
where filename = "yellow_tripdata_2021-04.csv";