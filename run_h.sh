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
PYTHON_EXE="$CONDA_PREFIX/bin/python"
PYTHON_SCRIPT="$SCRIPT_DIR/h.py"

echo "Rank ${GLOBAL_RANK_ID}: Launching ${PYTHON_EXE} $PYTHON_SCRIPT --rank ${GLOBAL_RANK_ID} --gpu ${TARGET_GPU} --tile ${TARGET_TILE}"

# Execute python, passing global rank, target gpu, and target tile as arguments
# Any extra arguments ($@) received by run_h.sh are passed at the end
"$PYTHON_EXE" "$PYTHON_SCRIPT" \
    --rank "$GLOBAL_RANK_ID" \
    --gpu "$TARGET_GPU" \
    --tile "$TARGET_TILE" \
    "$@"

EXIT_CODE=$?
echo "Rank ${GLOBAL_RANK_ID}: Python script finished with exit code ${EXIT_CODE}"
exit ${EXIT_CODE}
