# MIPS Assembly Linear Regression with Mean Squared Error Calculation

This project implements linear regression in MIPS Assembly, including data parsing, model training, and error evaluation through Mean Squared Error (MSE) calculation. The program reads data points from a file, computes a linear regression line using gradient descent, and outputs the model equation along with the MSE.

---

## Challenges & Accomplishments

Some of the key challenges and accomplishments of this project include:

1. **Reading in Data from File**: Parsing and storing floating-point numbers from a text file in MIPS Assembly is not a trivial task, as there are no built-in syscalls for reading floating point values (that could be positive or negative) from a file. This is solved by reading in the data as a string and then parsing the string to extract the floating-point values. Ironically, the data parsing was probably more challenging than the linear regression algorithm itself!
2. **Low-Level Data Manipulation**: Handling floating-point operations and memory management in assembly presented unique challenges compared to high-level languages, and careful design of procedures helped to manage these complexities.
3. **Implementing Gradient Descent!**: Ensuring the correctness of the gradient descent algorithm in assembly required careful consideration of the mathematical operations involved as well as memory management in the register file. Luckily, the MARS does a great job at providing an interface that let's us visualize the register file and memory.
   
---

## But wait, why implement Linear Regression in Assembly?

Good question :D

Of course, it's not the most practical (nor efficient) way to perform linear regression. However, this project serves as an educational exercise that gives you good practice working with MIPS Assembly while also understanding the fundamentals of linear regression and gradient descent.

---

## Installation Instructions
### Step 1: Download & Install MARS Simulator
The [MARS MIPS simulator](https://computerscience.missouristate.edu/mars-mips-simulator.htm) is required to run this project. Follow these steps to install:

1. Download the latest version of the MARS simulator from [the official page](https://computerscience.missouristate.edu/mars/download.htm).
2. Ensure you have Java installed, as MARS requires Java to run. You can download Java from [the official website](https://www.java.com/en/download/).
3. Once downloaded, run the `Mars.jar` file to start the MIPS simulator. This can be done by double-clicking the file or running `java -jar Mars.jar` from the command line.

### Step 2: Set Up the Project Directory
1. Clone this repository to your local machine:
    ```bash
    git clone https://github.com/Girish-Krishnan/MIPS-Assembly-Linear-Regression.git
    cd MIPS-Assembly-Linear-Regression
    ```
2. Place your dataset file in the `data.txt` path. The file format should include:
   - One line for the `x` values, separated by spaces.
   - Another line for the corresponding `y` values, also separated by spaces.
   - Make sure to add a space at the end of each line to ensure proper parsing.
   - Alternatively, you can modify the data file path in the `.data` section of the assembly file to point to your dataset.
   - See the `data.txt` file in the project directory for an example.

### Step 3: Run the Program
1. Open MARS and load the assembly file (`linear_regression.asm`) from the project directory.
2. Set up the data file path in the `.data` section (default is `./data.txt`). **Note:** the file path should be relative to the MARS working directory, i.e., the directory from which you run MARS.
3. Depending on the size of your dataset, you may need to adjust the sizes of the buffers `x_vals`, `y_vals`, `line1`, and `line2` in the `.data` section. The buffer sizes are in bytes, and each floating point number is represented as an IEEE 754 single-precision floating-point value (which is 4 bytes) and thus requires 4 bytes of buffer space. Hence, if you have `n` data points, you will need `4*n` bytes of buffer space for each array.
4. Feel free to play with the learning rate `alpha` and the number of iterations `iterations` in the `.data` section to optimize the model! You can also try different initial values for `w` and `b`.
5. Assemble and run the program in MARS.

If you are interested in viewing intermediate outputs as the program runs, I've included another file called `linear_regression_debug.asm` that includes additional print statements to help you visualize the data and model parameters at each step. However, I recommend running this version with smaller datasets and with a smaller number of iterations to avoid excessive output that can crash MARS.

### Output
Upon execution, the program will display:
1. The **linear regression equation** (e.g., `y = wx + b`) with the optimized values for `w` and `b`.
2. The **Mean Squared Error (MSE)** for evaluating model accuracy. The lower the MSE, the better the model fits the data.

---

## Code Overview
This project is organized into multiple sections:
1. **File I/O**: Reads data from an external file and parses it into two arrays (`x_vals` and `y_vals`).
2. **Linear Regression with Gradient Descent**:
   - Iteratively optimizes `w` and `b` to minimize the prediction error on the dataset.
   - Includes a learning rate parameter (`alpha`) and adjustable number of iterations for training.
3. **MSE Calculation**: After model training, the program computes the MSE as an accuracy metric by averaging the squared prediction errors.

### Key Code Sections
- **parse_floats**: Parses floating-point numbers from a space-separated string and stores them in memory.
- **Gradient Descent**: Performs weight and bias updates based on the computed gradients from each data point.
- **MSE Calculation**: Iterates through the dataset, calculating and summing squared errors, then divides by `m` for the final MSE.

---

## Example
Given a data file `data.txt` with the following contents:

```
0.0 0.714 1.429 2.143 2.857 3.571 4.286 5.0 5.714 6.429 7.143 7.857 8.571 9.286 10.0 
6.044 8.088 12.033 14.004 14.925 19.82 21.35 21.763 21.178 25.397 26.324 30.061 34.226 31.519 33.779 
```

The program will output:

```
The resulting regression equation is: y = 2.6729465 * x + 7.685805

Mean Squared Error (MSE): 2.5292602
```

The accuracy of the model can be improved by running more iterations or adjusting the learning rate. Smaller learning rates may require more iterations to converge, while larger rates may overshoot the optimal values.

---

## Future Work

Some potential improvements and extensions to this project include:

1. **Normalization:** Implement normalization on the dataset to improve gradient descent convergence, especially for datasets with large variations. This prevents getting `NaN` values due to overflow when the datasets contain a large variation in values.
2. **Command-Line Input:** Add functionality for passing in dataset parameters or file paths at runtime.
3. **Extended Error Metrics:** Implement additional error metrics such as Mean Absolute Error (MAE) or R-squared for a comprehensive evaluation.

---

## Contributions

Contributions are welcome! Feel free to open issues or submit pull requests to improve functionality or add features.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.