#!/bin/bash -l
#PBS -N AURORA_TILE_RUN
#PBS -l select=1
#PBS -l walltime=0:10:00
#PBS -l place=scatter
#PBS -l filesystems=flare:home
#PBS -q debug
#PBS -A candle_aesp_CNDA

# --- Configuration ---
NRANKS_PER_NODE=12 # Run 12 ranks per node (1 per tile)
NDEPTH=1         # CPU threads per rank (spacing). Adjust based on performance/binding needs.
NTHREADS=1       # OMP_NUM_THREADS. Set to 1 if each rank uses only its tile resources.
SCRIPT_DIR="/home/rjain/demo_tensorflow" # Directory containing run_h.sh and h.py
# --- End Configuration ---

# Calculate total ranks based on PBS allocation
if [[ -n "$PBS_NODEFILE" ]]; then
    NNODES=`wc -l < $PBS_NODEFILE`
else
    echo "Warning: PBS_NODEFILE is not set. Assuming single node." >&2
    NNODES=1
fi
NTOTRANKS=$(( NNODES * NRANKS_PER_NODE ))


# --- Job Information ---
echo "--------------------"
echo "Job Details:"
echo "Nodes: ${NNODES}"
echo "Ranks per Node: ${NRANKS_PER_NODE}"
echo "Total Ranks: ${NTOTRANKS}"
echo "Depth (Rank Spacing): ${NDEPTH}"
echo "OMP_NUM_THREADS: ${NTHREADS}"
echo "Target: 1 rank per GPU Tile"
echo "--------------------"

# Navigate to script directory
cd "${SCRIPT_DIR}" || { echo "Error: Failed to cd to ${SCRIPT_DIR}."; exit 1; }

echo "Launching MPI job with 1 rank per GPU tile..."

# --- Run the Wrapper Script via mpiexec ---
# Launch 12 ranks per node. The wrapper script (run_h.sh) will handle setting ZE_AFFINITY_MASK
# and passing rank/gpu/tile arguments to the python script.
# CPU binding (--cpu-bind) might need refinement.
mpiexec -n ${NTOTRANKS} -ppn ${NRANKS_PER_NODE} --depth=${NDEPTH} --cpu-bind depth \
        -env OMP_NUM_THREADS=${NTHREADS} \
        -env OMP_PLACES=threads \
        ./run_h.sh # Execute the wrapper script

EXIT_CODE=$?
echo "mpiexec finished with exit code: ${EXIT_CODE}"
exit ${EXIT_CODE}
