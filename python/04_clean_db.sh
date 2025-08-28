#!/bin/bash
#$ -cwd
#$ -pe onenode 1
#$ -l m_mem_free=48G
#$ -l h_vmem=48G
#$ -m abe
#$ -M [email address you registered as username in WRDS]
#$ -N orbis_clean

cd /scratch/[your group]/wrds_batch

# Start fresh log
echo "Starting cleaning at $(date)" > 04_clean_db.log

# 1) Check DuckDB version
dbv=$(python3 - <<'PYCODE'
import duckdb
print(duckdb.__version__)
PYCODE
)
if [ $? -ne 0 ]; then
  echo "ERROR: Could not import duckdb!" &>> 04_clean_db.log
  exit 1
fi
echo "DuckDB version: $dbv" &>> 04_clean_db.log

# 2) Run your cleaning
echo "Running 04_clean_db.py at $(date)" &>> 04_clean_db.log
if python3 04_clean_db.py &>> 04_clean_db.log; then
  echo "04_clean_db.py finished successfully at $(date)" &>> 04_clean_db.log
else
  echo "ERROR: 04_clean_db.py failed! See above log." &>> 04_clean_db.log
  exit 1
fi

echo "Finished cleaning at $(date)" &>> 04_clean_db.log
