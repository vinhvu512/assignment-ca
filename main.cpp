#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <cmath> // For floor function
#include <filesystem>
#include <string>
#include <vector>
#include <cstdio>  // for snprintf
#include <cstdlib> // for atof
#include <regex>    // Added for regex support

namespace fs = std::filesystem;

using namespace std;

// Define maximum sizes based on constraints
const int N_MAX = 7;
const int M_MAX = 4;
const int P_MAX = 4;
const int S_MAX = 3;
const int PADDED_SIZE_MAX = N_MAX + 2 * P_MAX; // 15
const int OUTPUT_SIZE_MAX = 15;

/**
 * Checks if a floating-point number is a whole number.
 *
 * @param num The floating-point number to check.
 * @return True if the number is whole, false otherwise.
 */
bool is_whole_number(float num) {
    return floor(num) == num;
}

/**
 * Reads a line from the input file and parses it into a flat array of floats.
 *
 * @param file The input file stream.
 * @param numbers The array to store the parsed numbers.
 * @param max_elements The maximum number of elements to read.
 * @return The actual number of elements read.
 */
int read_floats(ifstream &file, float numbers[], int max_elements) {
    string line;
    if (!getline(file, line)) {
        return 0;
    }
    stringstream ss(line);
    float num;
    int count = 0;
    while (ss >> num && count < max_elements) {
        numbers[count++] = num;
    }
    return count;
}

/**
 * Reads the first line of the input file to extract N, M, p, and s.
 *
 * @param file The input file stream.
 * @param N Pointer to store N.
 * @param M Pointer to store M.
 * @param p Pointer to store p.
 * @param s Pointer to store s.
 * @return True if successful, false otherwise.
 */
bool read_parameters(ifstream &file, int &N, int &M, int &p, int &s) {
    string line;
    if (!getline(file, line)) {
        return false;
    }
    stringstream ss(line);
    float N_f, M_f, p_f, s_f;
    if (!(ss >> N_f >> M_f >> p_f >> s_f)) {
        return false;
    }
    // Validate that N_f, M_f, p_f, s_f are whole numbers
    if (!is_whole_number(N_f) || !is_whole_number(M_f) ||
        !is_whole_number(p_f) || !is_whole_number(s_f)) {
        return false;
    }
    // Convert to integers
    N = static_cast<int>(N_f);
    M = static_cast<int>(M_f);
    p = static_cast<int>(p_f);
    s = static_cast<int>(s_f);
    return true;
}

/**
 * Reads a line from the input file and fills a 2D matrix.
 *
 * @param file The input file stream.
 * @param matrix The 2D array to store the matrix.
 * @param rows Number of rows in the matrix.
 * @param cols Number of columns in the matrix.
 * @return True if successful, false otherwise.
 */
bool read_matrix_image(ifstream &file, float matrix[][N_MAX], int rows, int cols) {
    float flat_matrix[N_MAX * N_MAX];
    int count = read_floats(file, flat_matrix, rows * cols);
    if (count != rows * cols) {
        return false;
    }
    // Fill the 2D matrix
    for(int i = 0; i < rows; i++) {
        for(int j = 0; j < cols; j++) {
            matrix[i][j] = flat_matrix[i * cols + j];
        }
    }
    return true;
}

bool read_matrix_kernel(ifstream &file, float matrix[][M_MAX], int rows, int cols) {
    float flat_matrix[M_MAX * M_MAX];
    int count = read_floats(file, flat_matrix, rows * cols);
    if (count != rows * cols) {
        return false;
    }
    // Fill the 2D matrix
    for(int i = 0; i < rows; i++) {
        for(int j = 0; j < cols; j++) {
            matrix[i][j] = flat_matrix[i * cols + j];
        }
    }
    return true;
}

/**
 * Applies symmetric padding to the image matrix.
 *
 * @param image The original image matrix.
 * @param padded_image The padded image matrix.
 * @param N The size of the original image.
 * @param p The padding size.
 */
void pad_image(float image[][N_MAX], float padded_image[][PADDED_SIZE_MAX], int N, int p) {
    // Initialize padded_image with zeros
    for(int i = 0; i < N + 2 * p; i++) {
        for(int j = 0; j < N + 2 * p; j++) {
            padded_image[i][j] = 0.0f;
        }
    }
    // Copy the original image into the center of padded_image
    for(int i = 0; i < N; i++) {
        for(int j = 0; j < N; j++) {
            padded_image[i + p][j + p] = image[i][j];
        }
    }
}

/**
 * Performs the convolution operation.
 *
 * @param padded_image The padded image matrix.
 * @param kernel The kernel matrix.
 * @param output The output matrix to store the convolution result.
 * @param padded_size The size of the padded image.
 * @param M The size of the kernel.
 * @param s The stride.
 * @return The size of the output matrix.
 */
int convolve(float padded_image[][PADDED_SIZE_MAX], float kernel[][M_MAX], float output[][OUTPUT_SIZE_MAX],
            int padded_size, int M, int s) {
    int out_size = ((padded_size - M) / s) + 1;
    if (out_size <= 0) {
        return 0;
    }
    // Initialize the output matrix with zeros
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            output[i][j] = 0.0000f;
        }
    }
    // Perform the convolution operation
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            float sum = 0.0f;
            for(int ki = 0; ki < M; ki++) {
                for(int kj = 0; kj < M; kj++) {
                    int pi = i * s + ki;
                    int pj = j * s + kj;
                    sum += padded_image[pi][pj] * kernel[ki][kj];
                }
            }
            output[i][j] = round(sum * 10.0f) / 10.0f;
        }
    }
    return out_size;
}

/**
 * Writes the output matrix to a file.
 *
 * @param filename The name of the output file.
 * @param output The output matrix.
 * @param out_size The size of the output matrix.
 */
bool write_output(const char* filename, float output[][OUTPUT_SIZE_MAX], int out_size) {
    ofstream outfile(filename);
    if (!outfile.is_open()) {
        return false;
    }
    outfile << fixed << setprecision(1);
    for(int i = 0; i < out_size; i++) {
        for(int j = 0; j < out_size; j++) {
            outfile << output[i][j];
            if (j != out_size - 1)
                outfile << " ";
        }
        if (i != out_size - 1)
            outfile << " ";
    }
    outfile.close();
    return true;
}

bool process_single_file(const string& input_path, const string& output_path) {
    // Open the input file
    ifstream infile(input_path);
    if (!infile.is_open()) {
        cerr << "Error: Unable to open " << input_path << endl;
        return false;
    }

    int N, M, p, s;
    // Read parameters
    if (!read_parameters(infile, N, M, p, s)) {
        cerr << "Error: Failed to read or parse N, M, p, s in " << input_path << endl;
        return false;
    }

    // Validate the input constraints
    if (N < 3 || N > N_MAX) {
        cerr << "Error: N must be between 3 and " << N_MAX << " in " << input_path << endl;
        return false;
    }
    if (M < 2 || M > M_MAX) {
        cerr << "Error: M must be between 2 and " << M_MAX << " in " << input_path << endl;
        return false;
    }
    if (p < 0 || p > P_MAX) {
        cerr << "Error: p (padding) must be between 0 and " << P_MAX << " in " << input_path << endl;
        return false;
    }
    if (s < 1 || s > S_MAX) {
        cerr << "Error: s (stride) must be between 1 and " << S_MAX << " in " << input_path << endl;
        return false;
    }

    float image[N_MAX][N_MAX];
    float kernel[M_MAX][M_MAX];
    
    if (!read_matrix_image(infile, image, N, N)) {
        cerr << "Error: Failed to read the image matrix in " << input_path << endl;
        return false;
    }

    if (!read_matrix_kernel(infile, kernel, M, M)) {
        cerr << "Error: Failed to read the kernel matrix in " << input_path << endl;
        return false;
    }

    infile.close();

    float padded_image[PADDED_SIZE_MAX][PADDED_SIZE_MAX];
    pad_image(image, padded_image, N, p);
    int padded_size = N + 2 * p;

    float output[OUTPUT_SIZE_MAX][OUTPUT_SIZE_MAX];
    int out_size = convolve(padded_image, kernel, output, padded_size, M, s);
    
    if (out_size == 0) {
        cerr << "Error: Invalid output size in " << input_path << endl;
        return false;
    }

    if (!write_output(output_path.c_str(), output, out_size)) {
        cerr << "Error: Unable to write to " << output_path << endl;
        return false;
    }

    return true;
}

int main(int argc, char* argv[]) {
    string input_dir = "input";
    string output_dir = "output";

    // Create output directory if it doesn't exist
    if (!fs::exists(output_dir)) {
        fs::create_directory(output_dir);
    }

    int processed = 0;
    int failed = 0;

    // Define a regex to match filenames like input_matrix_XX.txt, input_matrix_XXX.txt, etc.
    regex filename_regex(R"(input_matrix_(\d+)\.txt)");

    // Iterate through all files in input directory
    for (const auto& entry : fs::directory_iterator(input_dir)) {
        string filename = entry.path().filename().string();
        if (entry.path().extension() == ".txt" && regex_match(filename, filename_regex)) {
            string input_path = entry.path().string();
            
            // Extract the numeric part using regex
            smatch match;
            regex_search(filename, match, filename_regex);
            string input_number = match[1];

            string output_filename = "output_matrix_" + input_number + ".txt";
            string output_path = output_dir + "/" + output_filename;

            cout << "Processing " << output_filename << "..." << endl;

            if (process_single_file(input_path, output_path)) {
                processed++;
                cout << "Successfully processed " << output_filename << endl;
            } else {
                failed++;
                cout << "Failed to process " << output_filename << endl;
            }
        }
    }

    cout << "\nProcessing complete!" << endl;
    cout << "Successfully processed: " << processed << " files" << endl;
    cout << "Failed to process: " << failed << " files" << endl;

    return 0;
}
