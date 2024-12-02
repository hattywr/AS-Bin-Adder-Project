function Format-Csv {
    param (
        [string]$inputFile,   # Path to the input file
        [string]$outputFile    # Path to the output file
    )

    # Get the directory of the script
    $scriptDirectory = $PSScriptRoot

    # Construct the full path to the input file
    $inputFilePath = Join-Path -Path $scriptDirectory -ChildPath $inputFile

    # Check if the input file exists
    if (-Not (Test-Path $inputFilePath)) {
        Write-Host "Error: Input file '$inputFilePath' not found."
        return
    }

    # Output file path
    $outputFilePath = Join-Path -Path $scriptDirectory -ChildPath $outputFile

    # Use StreamWriter for efficient output
    try {
        $outputStream = [System.IO.StreamWriter]::new($outputFilePath)

        # Use Import-Csv to read the input file with the specified delimiter
        $csvData = Import-Csv -Path $inputFilePath -Delimiter "`t"  # Adjust delimiter as needed

        Write-Host "Successfully read input file: $inputFilePath"

        # Write the header row to the output file
        $headerRow = $csvData[0].PSObject.Properties.Name -join ','
        $outputStream.WriteLine($headerRow)

        foreach ($row in $csvData) {
            # Join the property values of each row into a comma-separated string
            $formattedRow = $row.PSObject.Properties.Value -join ','
            $outputStream.WriteLine($formattedRow)
        }

        Write-Host "CSV formatting complete. Output file created: $outputFilePath"
    }
    catch {
        Write-Host "An error occurred while writing to the output file: $_"
    }
    finally {
        # Ensure the output file stream is closed properly
        if ($outputStream) {
            $outputStream.Close()
        }
    }
}

# Usage
# Change the paths as needed
$inputCsv = 'bins.csv'       # Path to your input file
$outputCsv = 'formatted_output.csv'  # Output file will be saved in the same directory as the script
Format-Csv -inputFile $inputCsv -outputFile $outputCsv
