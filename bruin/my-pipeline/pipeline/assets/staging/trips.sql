/* @bruin

# Docs:
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks (built-ins): https://getbruin.com/docs/bruin/quality/available_checks
# - Custom checks: https://getbruin.com/docs/bruin/quality/custom

# TODO: Set the asset name (recommended: staging.trips).
name: staging.trips
# TODO: Set platform type.
# Docs: https://getbruin.com/docs/bruin/assets/sql
# suggested type: duckdb.sql
type: duckdb.sql

# TODO: Declare dependencies so `bruin run ... --downstream` and lineage work.
# Examples:
# depends:
#   - ingestion.trips
#   - ingestion.payment_lookup
depends:
  - ingestion.trips
  - ingestion.payment_lookup

# TODO: Choose time-based incremental processing if the dataset is naturally time-windowed.
# - This module expects you to use `time_interval` to reprocess only the requested window.
materialization:
  # What is materialization?
  # Materialization tells Bruin how to turn your SELECT query into a persisted dataset.
  # Docs: https://getbruin.com/docs/bruin/assets/materialization
  #
  # Materialization "type":
  # - table: persisted table
  # - view: persisted view (if the platform supports it)
  type: table


# TODO: Add one custom check that validates a staging invariant (uniqueness, ranges, etc.)
# Docs: https://getbruin.com/docs/bruin/quality/custom
custom_checks:
  - name: custom_count_positive
    description: Ensures the table is not empty
    query:
      SELECT count(*) > 0 from staging.trips
    value: 1

@bruin */

-- TODO: Write the staging SELECT query.
--
-- Purpose of staging:
-- - Clean and normalize schema from ingestion
-- - Deduplicate records (important if ingestion uses append strategy)
-- - Enrich with lookup tables (JOINs)
-- - Filter invalid rows (null PKs, negative values, etc.)
--
-- Why filter by {{ start_datetime }} / {{ end_datetime }}?
-- When using `time_interval` strategy, Bruin:
--   1. DELETES rows where `incremental_key` falls within the run's time window
--   2. INSERTS the result of your query
-- Therefore, your query MUST filter to the same time window so only that subset is inserted.
-- If you don't filter, you'll insert ALL data but only delete the window's data = duplicates.

-- Staging: Clean and enrich trips data with payment type lookup
SELECT
  t.vendor_id,
  t.tpep_pickup_datetime AS pickup_datetime,
  t.tpep_dropoff_datetime AS dropoff_datetime,
  t.passenger_count,
  t.trip_distance,
  t.ratecode_id,
  t.store_and_fwd_flag,
  t.pu_location_id,
  t.do_location_id,
  t.payment_type,
  COALESCE(pl.payment_type_name, 'unknown') AS payment_type_name,
  t.fare_amount,
  t.extra,
  t.mta_tax,
  t.tip_amount,
  t.tolls_amount,
  t.improvement_surcharge,
  t.total_amount,
  t.congestion_surcharge,
  t.airport_fee,
  t.cbd_congestion_fee
FROM ingestion.trips t
LEFT JOIN ingestion.payment_lookup pl
  ON t.payment_type = pl.payment_type_id
WHERE t.tpep_pickup_datetime IS NOT NULL
  AND t.tpep_dropoff_datetime IS NOT NULL
  AND t.tpep_pickup_datetime >= '{{ start_datetime }}'
  AND t.tpep_pickup_datetime < '{{ end_datetime }}'
  AND t.trip_distance > 0  -- Filter invalid/test trips
  AND t.fare_amount > 0