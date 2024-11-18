import os
import subprocess
import filecmp
import difflib
import shutil
import re  # Added for regex support

def setup_directories():
    # Create output directories if they don't exist
    os.makedirs("output_asm", exist_ok=True)
    os.makedirs("output", exist_ok=True)

def run_mips_assembly(input_file, output_file):
    # Assuming you're using MARS MIPS simulator
    # Replace the path with your MARS jar location
    mars_path = "mars.jar"
    
    try:
        # Copy input file to the expected location
        shutil.copy(input_file, "input_matrix.txt")
        
        # Run MARS simulator
        command = [
            "java", "-jar", mars_path, 
            "nc", # no gui
            "lab.asm"
        ]
        
        subprocess.run(command, check=True)
        
        # Copy output to the correct location
        if os.path.exists("output_matrix.txt"):
            shutil.move("output_matrix.txt", output_file)
            
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error running MIPS assembly: {e}")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def compare_outputs(asm_output, cpp_output):
    try:
        with open(asm_output, 'r') as f1, open(cpp_output, 'r') as f2:
            # Strip whitespace and newlines from both files
            asm_content = f1.read().strip()
            cpp_content = f2.read().strip()
            
        if asm_content == cpp_content:
            return True, None
        
        # If contents are different, show the actual values
        diff = f"ASM output: '{asm_content}'\nC++ output: '{cpp_content}'"
        return False, diff
    except Exception as e:
        return False, str(e)

def main():
    setup_directories()
    
    # Get all input files using regex to match varying digits
    input_files = [
        f for f in os.listdir("input") 
        if re.match(r"input_matrix_\d+\.txt$", f)
    ]
    
    results = {
        "total": 0,
        "passed": 0,
        "failed": 0,
        "errors": [],
        "mismatches": [],  # Track mismatched tests
        "error_details": {}  # Store error details for each test
    }
    
    print("Starting test execution...\n")
    
    for input_file in sorted(input_files):
        results["total"] += 1
        # Extract the numeric part using regex
        match = re.search(r"input_matrix_(\d+)\.txt$", input_file)
        if match:
            file_num = match.group(1)
        else:
            print(f"Skipping unrecognized file format: {input_file}")
            continue
        
        input_path = os.path.join("input", input_file)
        asm_output = os.path.join("output_asm", f"output_matrix_{file_num}.txt")
        cpp_output = os.path.join("output", f"output_matrix_{file_num}.txt")
        
        # Run MIPS assembly
        if run_mips_assembly(input_path, asm_output):
            match_result, diff = compare_outputs(asm_output, cpp_output)
            
            if match_result:
                results["passed"] += 1
                print(f"Test {file_num}: ✓")
            else:
                results["failed"] += 1
                results["mismatches"].append(file_num)
                results["error_details"][file_num] = diff
                print(f"Test {file_num}: ✗")
        else:
            results["failed"] += 1
            results["error_details"][file_num] = "Failed to run ASM"
            print(f"Test {file_num}: ✗ (Runtime Error)")

    # Print final summary
    print("\n" + "="*50)
    print("FINAL TEST RESULTS")
    print("="*50)
    print(f"Total Tests Run: {results['total']}")
    print(f"Tests Passed:    {results['passed']}")
    print(f"Tests Failed:    {results['failed']}")
    
    success_rate = (results['passed'] / results['total']) * 100 if results['total'] > 0 else 0
    print(f"\nSuccess Rate: {success_rate:.2f}%")
    
    if results["mismatches"]:
        print("\nFailed Test Cases:")
        print("-"*50)
        for test_num in results["mismatches"]:
            print(f"\nTest {test_num}:")
            print(f"Difference:\n{results['error_details'][test_num]}")

if __name__ == "__main__":
    main()