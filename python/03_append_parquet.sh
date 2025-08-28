#!/bin/bash
#$ -cwd
#$ -pe onenode 1
#$ -l m_mem_free=48G
#$ -l h_vmem=50G
#$ -m abe
#$ -M [email address you registered as username in WRDS]

# 1) cd into the folder with your CSVs and the converter script
cd /scratch/[your_group]/wrds_batch

# 2) start a new log
echo "Parquet conversion started at $(date)" > 03_append_parquet.log

# 3) run the Python converter
python3 03_append_parquet.py &>> 03_append_parquet.log

# 4) stamp the finish time
echo "Parquet conversion finished at $(date)" &>> 03_append_parquet.log
