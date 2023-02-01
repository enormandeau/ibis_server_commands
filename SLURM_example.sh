#!/bin/bash
#SBATCH -J JOBNAME                      # Job name
#SBATCH -o JOBNAME-%j.log               # Logfile
#SBATCH -p small                        # Partition
#SBATCH -c 1                            # Number of CPUs
#SBATCH --mem=10G                       # Memory (in megabytes or add G for gigabytes)
#SBATCH --time=0-01:00:00               # Time reserved for the job (days-hours:minutes:seconds)

#SBATCH --mail-type=ALL                 # What emails to receive (NONE, BEGIN, END, FAIL, REQUEUE, ALL)
#SBATCH --mail-user=user@service.com    # Email address to send job updates

# Move to directory where job was submitted
cd $SLURM_SUBMIT_DIR

# Create variables
input_data="02_data/input_file.txt"
output_file="03_results/output_file.txt"

# Load needed software
module load samtools

# Commands to execute
echo "Printing samtools help:"
samtools help
