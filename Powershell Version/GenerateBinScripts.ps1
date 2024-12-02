function GenerateBinScripts {
    param (
        [string]$warehouse_num,
        [string]$zone
    )

    # Call the formatting script and ensure it completes
    & "$PSScriptRoot\FormatCsv.ps1" 
    Write-Host "Formatting is running..."

    # Input and output file paths
    $scriptDirectory = $PSScriptRoot
    $input_file = Join-Path -Path $scriptDirectory -ChildPath "formatted_output.csv"
    $output_file = Join-Path -Path $scriptDirectory -ChildPath "warehouse_$warehouse_num`_zone_$zone.sql"

    # Check if input CSV exists after running the formatting script
    if (-Not (Test-Path $input_file)) {
        Write-Host "Error: File '$input_file' not found."
        exit
    }

    # Read the CSV file and process the "Bin" and "Content" columns
    try {
        $csv_data = Import-Csv $input_file
        $sql_lines = [System.Collections.Generic.List[string]]::new()  # Use List for better performance

        foreach ($row in $csv_data) {
            $bin_value = $row.Bin
            $content_value = $row.Content

            if ($bin_value -and $content_value) {
                $cell_pattern = 1  # Default to cell pattern 1

                # Determine cell pattern based on content length
                if ($content_value.Length -eq 2) {
                    $cell_pattern = $content_value[0]  # Get first digit for 2-digit content code
                }
                elseif ($content_value.Length -eq 3) {
                    $cell_pattern = "$($content_value[0])$($content_value[1])"  # Get first two digits for 3-digit content code
                }

                # Generate the procedure execution statement
                $procedure = "exec spAddAutomationBinLocation @automationContainerName = '$bin_value', @cellPatternName = '$cell_pattern', @warehouse = '$warehouse_num', @zone = '$zone', @workAreaName = '$zone'"
                $sql_lines.Add($procedure)  # Add to List instead of array
            }
        }

        # Write the SQL statements to the output file
        $sql_lines | Out-File -FilePath $output_file -Encoding utf8

        Write-Host "Data successfully written to $output_file"
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Usage
$warehouse_num = '001'  # Example warehouse number
$zone = 'AS1'           # Example zone
GenerateBinScripts -warehouse_num $warehouse_num -zone $zone
