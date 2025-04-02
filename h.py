import argparse
import os
import time # Added for potential use later

def main():
    parser = argparse.ArgumentParser(description="Process rank, GPU, and Tile info.")
    parser.add_argument("--rank", type=int, required=True, help="Global MPI rank of the process.")
    parser.add_argument("--gpu", type=int, required=True, help="Target GPU ID for this rank.")
    parser.add_argument("--tile", type=int, required=True, help="Target Tile ID on the target GPU.")
    # Add any other arguments your script might need
    # parser.add_argument("--input-file", type=str, help="Some input data.")
    args = parser.parse_args()

    print(f"h.py executing:")
    print(f"  Global Rank: {args.rank}")
    print(f"  Target GPU:  {args.gpu}")
    print(f"  Target Tile: {args.tile}")

    # You can now use args.gpu and args.tile in your script logic,
    # for example, to initialize specific device contexts if using
    # libraries like dpctl or others aware of GPU/Tile selection.

    # --- Original file/directory logic ---
    # Create directory named after rank, gpu, tile for uniqueness
    dir_name = f"output_rank_{args.rank}_gpu_{args.gpu}_tile_{args.tile}"
    file_name = f"hello_rank_{args.rank}.txt"
    file_path = os.path.join(dir_name, file_name)

    try:
        os.makedirs(dir_name, exist_ok=True)
        # print(f"  Directory created/exists: {dir_name}") # Less verbose
    except OSError as e:
        print(f"  Error creating directory {dir_name}: {e}")
        return # Exit if directory fails

    # Write file named after rank
    try:
        with open(file_path, "w") as f:
            f.write(f"Hello from h.py\n")
            f.write(f"Global Rank: {args.rank}\n")
            f.write(f"Target GPU: {args.gpu}\n")
            f.write(f"Target Tile: {args.tile}\n")
            # Add timestamp or other info if desired
            f.write(f"Timestamp: {time.time()}\n")
        print(f"  File written: {file_path}")
    except IOError as e:
        print(f"  Error writing file {file_path}: {e}")
    # --- End original logic ---

    print(f"h.py rank {args.rank} finished.")


if __name__ == "__main__":
    main()
