import random
import numpy as np

def generate_test_case(case_num):
    while True:
        # Generate parameters with individual constraints
        N = random.randint(3, 7)      # 3 ≤ N ≤ 7
        M = random.randint(2, 4)      # 2 ≤ M ≤ 4
        p = random.randint(0, 4)      # 0 ≤ p ≤ 4
        s = random.randint(1, 3)      # 1 ≤ s ≤ 3

        # Check interrelationship constraints
        # if N + 2*p < M:  # N + 2p ≥ M must be satisfied
        #     continue
            
        # if (N + 2*p - M) % s != 0:  # (N + 2p - M) mod s = 0 must be satisfied
        #     continue
            
        # If all constraints are satisfied, generate matrices
        image = np.round(np.random.uniform(-100, 100, (N, N)), 1)
        kernel = np.round(np.random.uniform(-100, 100, (M, M)), 1)
        
        case_num_str = f"{case_num:05d}"
        
        # Format the output with varying digits
        filename = f"input/input_matrix_{case_num_str}.txt"
        with open(filename, 'w') as f:
            # Write parameters
            f.write(f"{N}.0 {M}.0 {p}.0 {s}.0\n")
            
            # Write image matrix
            image_str = ' '.join(map(str, image.flatten()))
            f.write(f"{image_str}\n")
            
            # Write kernel matrix
            kernel_str = ' '.join(map(str, kernel.flatten()))
            f.write(f"{kernel_str}\n")
        
        return filename

for i in range(1, 51):
    filename = generate_test_case(i)
    print(f"Generated {filename}")