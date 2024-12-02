import csv

def format_csv(input_file, output_file):
    with open(input_file, 'r', newline='', encoding='utf-8') as infile:
        # Read the original CSV
        reader = csv.reader(infile, delimiter='\t')  # Change delimiter as needed
        formatted_data = []
        
        for row in reader:
            # For rows that have multiple fields in one cell, split them
            formatted_row = []
            for item in row:
                # Split each item by spaces and extend the formatted_row
                formatted_row.extend(item.split())
            formatted_data.append(formatted_row)

    # Write the formatted data to a new CSV file
    with open(output_file, 'w', newline='', encoding='utf-8') as outfile:
        writer = csv.writer(outfile)
        writer.writerows(formatted_data)
    print("CSV formatting complete.")



