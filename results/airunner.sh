#!/bin/sh
# SBATCH --job-name=Pachinko

echo Usage:  sbatch airunner.sh chatid
echo Starting $1
JOB_VENVNAME=$1_venv
echo building virtual environment $JOB_VENVNAME
python3 -m venv $JOB_VENVNAME
. ./$JOB_VENVNAME/bin/activate
echo GITing AI Runner
git --version
echo Running AI Runner
python3 --version
echo Cleaning up
rm -rf ./$JOB_VENVNAME
echo $SLURM_JOB_NAME has completed.
