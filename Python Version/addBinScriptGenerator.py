import csv
import sys
import formatASBinFile

def parse_csv_and_write_to_file(warehouse_num, zone):
    # Input and output file paths
    formatASBinFile.format_csv('bins.csv', 'formatted_output.csv')

    input_file = 'formatted_output.csv'
    output_file = f'warehouse_{warehouse_num}_zone_{zone}.sql'

    # List to hold the parsed data (as tuples)
    parsed_data = []

    try:
        # Open the CSV file and read the "Bin" and "Content" columns
        with open(input_file, 'r') as csv_file:
            csv_reader = csv.DictReader(csv_file)

            for row in csv_reader:
                # Only extract the 'Bin' and 'Content' columns
                bin_value = row.get('Bin')
                content_value = row.get('Content')
                
                if bin_value and content_value:
                    parsed_data.append((bin_value, content_value))

        # Write the parsed data to the output text file
        with open(output_file, 'w') as sql_file:
            for data_tuple in parsed_data:
                bin = data_tuple[0]
                content_code = data_tuple[1]
                #default to cell pattern 1
                cell_pattern = 1
                if len(content_code) == 2:
                    #get the first digit of the content code (10,20,40,80)
                    cell_pattern = str(content_code)[0]

                #if we have 16 cell pattern
                elif len(content_code) == 3:
                    cell_pattern = str(content_code)[0] + str(content_code)[1]
                    
                #generate the procedure execution statement                               
                procedure = f"exec spAddAutomationBinLocation @automationContainerName = '{bin}', @cellPatternName = '{cell_pattern}', @warehouse = '{warehouse_num}', @zone = '{zone}', @workAreaName = '{zone}'\n"
                sql_file.write(procedure)

        print(f'Data successfully written to {output_file}')
    
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Ensure the script takes in two parameters from the command line
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <warehouse_num> <zone>")
    else:
        try:
            warehouse_num = str(sys.argv[1])
            zone = sys.argv[2]
            parse_csv_and_write_to_file(warehouse_num, zone)
        except ValueError:
            print("Error: Warehouse number must be an integer.")

