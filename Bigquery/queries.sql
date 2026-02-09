CREATE OR REPLACE TABLE `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`
AS
SELECT *
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.external_yellow_tripdata`;

SELECT COUNT(DISTINCT PULocationID)
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.external_yellow_tripdata`;
# Bytes processed
# 0

SELECT COUNT(DISTINCT PULocationID)
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`;
# Bytes processed
# 155.12 MB

SELECT PULocationID
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`;

SELECT PULocationID, DOLocationID
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`;

SELECT COUNT(1)
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`
WHERE fare_amount = 0;

CREATE TABLE `data-engineer-zoomcamp-486517.nytaxi_ext.trips_optimized`
  PARTITION BY DATE(tpep_dropoff_datetime)
  CLUSTER BY VendorID
AS
SELECT *
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.external_yellow_tripdata`;

SELECT DISTINCT VendorID
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15'
ORDER BY VendorID;  # 310.24 MB

SELECT DISTINCT VendorID
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.trips_optimized`
WHERE DATE(tpep_dropoff_datetime) BETWEEN '2024-03-01' AND '2024-03-15'
ORDER BY VendorID;  # 26.84 MB

SELECT COUNT(*)
FROM `data-engineer-zoomcamp-486517.nytaxi_ext.regular_yellow_tripdata`;
