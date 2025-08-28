#!/bin/bash
#$ -cwd
#$ -pe onenode 1
#$ -l m_mem_free=48G
#$ -l h_vmem=50G
#$ -m abe
#$ -M [email address you registered as username in WRDS]

echo "Job started at $(date)"
python3 06_compustat_batch.py &> 06_compustat_batch.log
echo "Job finished at $(date)"