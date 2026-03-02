"""@bruin
name: ingestion.trips
type: python
image: python:3.11
connection: duckdb-default

materialization:
  type: table
  strategy: append

columns:
  - name: pickup_datetime
    type: timestamp
    description: "When the meter was engaged"
  - name: dropoff_datetime
    type: timestamp
    description: "When the meter was disengaged"
@bruin"""

import os
import json
import datetime
import io
import requests
import pandas as pd

def materialize():
  start_date = os.environ["BRUIN_START_DATE"]
  end_date = os.environ["BRUIN_END_DATE"]
  taxi_types = json.loads(os.environ.get("BRUIN_VARS", "{}")).get("taxi_types", ["yellow"])

  def months_between(start_iso: str, end_iso: str):
    start = datetime.date.fromisoformat(start_iso)
    end = datetime.date.fromisoformat(end_iso)
    current = datetime.date(start.year, start.month, 1)
    last = datetime.date(end.year, end.month, 1)
    while current <= last:
      yield current.year, current.month
      if current.month == 12:
        current = datetime.date(current.year + 1, 1, 1)
      else:
        current = datetime.date(current.year, current.month + 1, 1)

  frames = []
  for taxi in taxi_types:
    for year, month in months_between(start_date, end_date):
      url = f"https://d37ci6vzurychx.cloudfront.net/trip-data/{taxi}_tripdata_{year}-{month:02d}.parquet"
      try:
        resp = requests.get(url, timeout=60)
        if resp.status_code != 200:
          print(f"Warning: failed to fetch {url} (status {resp.status_code})")
          continue
        bio = io.BytesIO(resp.content)
        df = pd.read_parquet(bio)
        frames.append(df)
        print(f"Loaded {len(df)} rows from {url}")
      except Exception as exc:
        print(f"Error loading {url}: {exc}")
        continue

  if frames:
    final_dataframe = pd.concat(frames, ignore_index=True)
  else:
    final_dataframe = pd.DataFrame()

  return final_dataframe