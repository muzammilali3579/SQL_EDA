# SQL Analysis Tool

Hello, Sir. Greetings. I have attached my Python and notebook files for evaluation. You can choose which one you want to evaluate, sir. To run the Jupyter file, please follow the steps to get the outputs in the Jupyter Notebook itself. Also, below I have provided the steps to run the Python script file to generate the Word document containing all the required elements from the SPs.

## Requirements

- Python 3.6+
- matplotlib
- python-docx

- 
## Features

- Tokenizes SQL content to find the most and least occurring words.
- Extract comments, variables, return values, table names, and mathematical formulae from SQL content.
- Finds the maximum nesting level of SQL statements.
- Generates visualizations of word counts and nesting levels.
- Compiles all results into a Word document.

## Usage

1. Install the required Python packages using:

    ```bash
    pip install -r requirements.txt
    ```


2. Run the `app.py` script:

    ```bash
    python app.py
    ```

3. The script will generate a Word document named `SQL_Analysis_Results.docx` with all the analysis results.

## File Structure

- `app.py`: The main script performs the analysis and generates the Word document.
- `requirements.txt`: Lists the required Python packages.
- `README.md`: Provides an overview and instructions for the project.


Running the script will produce `SQL_Analysis_Results.docx` with the following sections:
- 20 Most Occurring Words (with a bar chart)
- 20 Least Occurring Words (with a bar chart)
- Comments
- Variables
- Return Values
- Table Names
- Mathematical Formulae
- Maximum Nesting Level (with a bar chart)

## My Unique Insight 

I have selected the nesting levels of each stored procedure's SQL statements for analysis. By analyzing the maximum nesting level of SQL statements within each stored procedure, we can gain insight into the complexity and maintainability of the code. Higher nesting levels may indicate more complex logic, which could be harder to debug and maintain.
