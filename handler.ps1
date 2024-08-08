# Define file paths
$scriptRoot = $PSScriptRoot
$commandFolder = "$PSScriptRoot\outstanding"
$processesFolder = "$PSScriptRoot\processes"
$batchFileBasePath = "$processesFolder\command"
$outputFileBasePath = "$processesFolder\output"
$lockFile = "$scriptRoot\script.lock"

# Function to clear the processes folder
function Clear-ProcessesFolder {
    if (Test-Path $processesFolder) {
        Remove-Item -Path "$processesFolder\*" -Recurse -Force
    } else {
        New-Item -Path $processesFolder -ItemType Directory | Out-Null
    }
}

function Clear-OutstandingFolder {
    if (Test-Path $commandFolder) {
        Remove-Item -Path "$commandFolder\*" -Recurse -Force
    } else {
        New-Item -Path $commandFolder -ItemType Directory | Out-Null
    }
}

function Create-LockFile {
    if (-Not (Test-Path $lockFile)) {
        New-Item -Path $lockFile -ItemType File | Out-Null
    }
}

function Remove-LockFile {
    if (Test-Path $lockFile) {
        Remove-Item -Path $lockFile -Force
    }
}

function Is-ScriptRunning {
    return Test-Path $lockFile
}

# Main script execution
if (-Not (Is-ScriptRunning)) {
    Create-LockFile

    try {
        Clear-ProcessesFolder
        Clear-OutstandingFolder

        # Loop to continuously monitor the directory
        while ($true) {
            $commandFiles = Get-ChildItem -Path $commandFolder -Filter *.txt
            foreach ($commandFile in $commandFiles) {
                # Extract the specifier from the filename (e.g., command34.txt -> 34)
                $specifier = [regex]::Match($commandFile.Name, 'command(\d+)\.txt').Groups[1].Value
                $batchFile = "$processesFolder\command$specifier.ps1"
                $outputFile = "$processesFolder\output$specifier.txt"

                # Rename command.txt to command[specifier].ps1 and move to processes folder
                Rename-Item -Path $commandFile.FullName -NewName "command$specifier.ps1" -ErrorAction Stop

                # Move the renamed batch file to the processes folder
                Move-Item -Path "$commandFolder\command$specifier.ps1" -Destination $batchFile -ErrorAction Stop

                # Start a new job to run the batch file and capture the result
                Start-Job -ScriptBlock {
                    param ($batchFilePath, $outputFilePath, $specifier, $processesFolder)
                    try {
                        $result = & $batchFilePath 2>&1
                        $result | Out-File -FilePath $outputFilePath -Encoding utf8
                    } catch {
                        "Error executing batch file: $_" | Out-File -FilePath $outputFilePath -Encoding utf8
                    }

                    $finishedFile = "$processesFolder\finished$specifier.txt"
                    New-Item -Path $finishedFile -type file -Value "1"
                } -ArgumentList $batchFile, $outputFile, $specifier, $processesFolder
            }

            # Delay before checking again
            Start-Sleep -Seconds 1
        }
    } finally {
        Remove-LockFile
    }
} else {
    Write-Output "Script is already running."
}
