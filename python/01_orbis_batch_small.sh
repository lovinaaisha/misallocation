#!/bin/bash
#$ -cwd
#$ -pe onenode 1
#$ -l m_mem_free=48G
#$ -l h_vmem=50G
#$ -m abe
#$ -M [email address you registered as username in WRDS]

echo "Job started at $(date)"
python3 01_orbis_batch_small.py &> 01_orbis_batch_small.log
echo "Job finished at $(date)"