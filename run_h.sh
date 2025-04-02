#!/bin/bash

# This script is executed by mpiexec for each rank.
# Determines Global Rank, Local Rank, calculates Target GPU/Tile,
# sets ZE_AFFINITY_MASK, and executes h.py passing rank, gpu, and tile info.

# --- Determine Global Rank ID ---
GLOBAL_RANK_ID="-1"
# Using PALS_RANKID as established previously
if [[ -n "$PALS_RANKID" ]]; then
  GLOBAL_RANK_ID="$PALS_RANKID"
else
  echo "Error (Global Rank): run_h.sh could not determine Global MPI rank ID from PALS_RANKID." >&2
  exit 1
fi

# --- Determine Local Rank ID ---
LOCAL_RANK_ID="-1"
if [[ -n "$PALS_LOCAL_RANKID" ]]; then
  LOCAL_RANK_ID="$PALS_LOCAL_RANKID"
else
  echo "Error (Local Rank): run_h.sh could not determine Local MPI rank ID from PALS_LOCAL_RANKID." >&2
  exit 1
fi

# --- Calculate Target GPU Tile and Set Affinity Mask ---
# Assuming 6 GPUs per node, 2 tiles per GPU, mapping local rank 0-11
TARGET_GPU=$(( LOCAL_RANK_ID / 2 ))
TARGET_TILE=$(( LOCAL_RANK_ID % 2 ))
AFFINITY_MASK="${TARGET_GPU}.${TARGET_TILE}"
export ZE_AFFINITY_MASK="${AFFINITY_MASK}" # Set for runtime/driver level affinity

echo "Rank ${GLOBAL_RANK_ID} (Local ${LOCAL_RANK_ID}): Calculated Target GPU=${TARGET_GPU}, Tile=${TARGET_TILE}. Setting ZE_AFFINITY_MASK=${AFFINITY_MASK}"

# --- Execute the Python Script ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PYTHON_SCRIPT="$SCRIPT_DIR/h.py"

echo "Rank ${GLOBAL_RANK_ID}: Launching ${PYTHON_EXE} $PYTHON_SCRIPT --rank ${GLOBAL_RANK_ID} --gpu ${TARGET_GPU} --tile ${TARGET_TILE}"

CONDA_ENV_NAME="new_env_name" # Name of your conda environment - this is made on top of frameworks/base to include required packages run in run_h.sh

# --- Proxy Configuration ---
# Set up proxy for ALCF
# This is necessary for accessing external resources (e.g., git, conda) from ALCF

export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
# git config --global http.proxy http://proxy.alcf.anl.gov:3128
module use /soft/modulefiles

# --- Environment Setup ---
echo "Setting up environment..."
module load frameworks || { echo "Error: Failed to load 'frameworks' module."; exit 1; }
# Add any other modules needed for GPU execution (e.g., level-zero, specific compilers) if not handled by frameworks/base env
# module load <module_name>

echo "Activating Conda env: ${CONDA_ENV_NAME}"
conda activate "${CONDA_ENV_NAME}" || { echo "Error: Failed to activate Conda environment '${CONDA_ENV_NAME}'."; exit 1; }
# --- End Environment Setup ---

echo "Python version: $(python --version)"
echo "Conda environment: $(conda info --envs | grep '*' | awk '{print $1}')"
echo "Current working directory: $(pwd)"
print python path
echo "Python executable: $(which python)"

PYTHON_EXE="$CONDA_PREFIX/bin/python"

# Execute python, passing global rank, target gpu, and target tile as arguments
# Any extra arguments ($@) received by run_h.sh are passed at the end
# Here specify the actual script to run, args should guide the usage of GPUs for different tasks
# e.g., training, validation, etc.
"$PYTHON_EXE" "$PYTHON_SCRIPT" \
    --rank "$GLOBAL_RANK_ID" \
    --gpu "$TARGET_GPU" \
    --tile "$TARGET_TILE" \
    "$@"

EXIT_CODE=$?
echo "Rank ${GLOBAL_RANK_ID}: Python script finished with exit code ${EXIT_CODE}"
exit ${EXIT_CODE}
