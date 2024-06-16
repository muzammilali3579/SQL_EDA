# SQL Analysis Tool

This project analyzes SQL files to extract various pieces of information and generate a comprehensive Word document with the results.

## Features

- Tokenizes SQL content to find the most and least occurring words.
- Extracts comments, variables, return values, table names, and mathematical formulae from SQL content.
- Finds the maximum nesting level of SQL statements.
- Generates visualizations of word counts and nesting levels.
- Compiles all results into a Word document.

## Requirements

- Python 3.6+
- matplotlib
- python-docx

## Installation

1. Clone the repository or download the `app.py` script.
2. Navigate to the project directory.
3. Install the required Python packages using:

    ```bash
    pip install -r requirements.txt
    ```

## Usage

1. Ensure you have your SQL files ready and update the paths in the script if necessary.
2. Run the `app.py` script:

    ```bash
    python app.py
    ```

3. The script will generate a Word document named `SQL_Analysis_Results.docx` with all the analysis results.

## File Structure

- `app.py`: The main script that performs the analysis and generates the Word document.
- `requirements.txt`: Lists the required Python packages.
- `README.md`: Provides an overview and instructions for the project.

## Example

Ensure that the `data` directory contains the following SQL files:
- `pyprc_cmn_pay_rule_proration_method.sql`
- `pyprc_hcl_aws_cmn_pay_rule_emp_fetch.sql`

Running the script will produce `SQL_Analysis_Results.docx` with the following sections:
- 20 Most Occurring Words (with a bar chart)
- 20 Least Occurring Words (with a bar chart)
- Comments
- Variables
- Return Values
- Table Names
- Mathematical Formulae
- Maximum Nesting Level (with a bar chart)

## License

This project is licensed under the MIT License.
