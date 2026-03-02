/* @bruin

# Docs:
# - SQL assets: https://getbruin.com/docs/bruin/assets/sql
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks: https://getbruin.com/docs/bruin/quality/available_checks

# TODO: Set the asset name (recommended: reports.trips_report).
name: reports.trips_report

# TODO: Set platform type.
# Docs: https://getbruin.com/docs/bruin/assets/sql
# suggested type: duckdb.sql
type: duckdb.sql

# TODO: Declare dependency on the staging asset(s) this report reads from.
depends:
  - staging.trips

# TODO: Choose materialization strategy.
# For reports, `time_interval` is a good choice to rebuild only the relevant time window.
# Important: Use the same `incremental_key` as staging (e.g., pickup_datetime) for consistency.
materialization:
  type: table


# TODO: Define report columns + primary key(s) at your chosen level of aggregation.
columns:
  - name: vendor_id
    type: INTEGER
    description: "Taxi vendor ID (1=Yellow, 2=Uber, etc.)"
    primary_key: true
  - name: report_date
    type: DATE
    description: "Report date (aggregation by pickup date)"
    primary_key: true
  - name: trip_count
    type: BIGINT
    description: "Total number of trips"
    checks:
      - name: non_negative
  - name: total_fare_amount
    type: DOUBLE
    description: "Sum of all fares"
    checks:
      - name: non_negative
  - name: total_tips
    type: DOUBLE
    description: "Sum of all tips"
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: DOUBLE
    description: "Average trip distance"
    checks:
      - name: non_negative
  - name: avg_fare_per_trip
    type: DOUBLE
    description: "Average fare amount per trip"
    checks:
      - name: non_negative
  - name: avg_passengers
    type: DOUBLE
    description: "Average passengers per trip"
    checks:
      - name: non_negative
  - name: total_revenue
    type: DOUBLE
    description: "Total revenue (fare + tips + surcharges)"
    checks:
      - name: non_negative

@bruin */

-- Purpose of reports:
-- - Aggregate staging data for dashboards and analytics
-- Required Bruin concepts:
-- - Filter using `{{ start_datetime }}` / `{{ end_datetime }}` for incremental runs
-- - GROUP BY your dimension + date columns

SELECT
  vendor_id,
  CAST(pickup_datetime AS DATE) AS report_date,
  COUNT(*) AS trip_count,
  SUM(fare_amount) AS total_fare_amount,
  SUM(tip_amount) AS total_tips,
  AVG(trip_distance) AS avg_trip_distance,
  AVG(fare_amount) AS avg_fare_per_trip,
  AVG(passenger_count) AS avg_passengers,
  SUM(fare_amount + tip_amount + COALESCE(congestion_surcharge, 0) + COALESCE(airport_fee, 0) + COALESCE(cbd_congestion_fee, 0)) AS total_revenue
FROM staging.trips
WHERE pickup_datetime >= '{{ start_datetime }}'
  AND pickup_datetime < '{{ end_datetime }}'
GROUP BY vendor_id, CAST(pickup_datetime AS DATE)
ORDER BY report_date DESC, vendor_id