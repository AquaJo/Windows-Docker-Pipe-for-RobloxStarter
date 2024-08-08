$scriptRoot = $PSScriptRoot

# set necessary env variables
$env:COMPOSE_DIR = $scriptRoot
$env:VOLUME_C_PATH = "C:/"
$env:VOLUME_D_PATH = "D:/"

# define container name (should match the name in the docker-compose.yml)
$containerName = "roblox_dev_environment_c"

# check if the container is already running
$containerExists = docker ps -a --filter "name=$containerName" --format "{{.Names}}" | ForEach-Object { $_ -eq $containerName }

if (-not $containerExists) {
    Write-Output "Container does not exist."

    # Ask for confirmation to build the container
    $response = Read-Host "Do you want to build and start the container? (y/n)"
    
    if ($response -eq 'y') {
        Write-Output "Building and starting container..."
        docker compose -f "$scriptRoot\docker-compose.yml" up -d --build
    } else {
        Write-Output "Build process aborted by user."
    }
} else {
    Write-Output "Container already exists, skipping build"
}

# start piping
Write-Output "Starting command piping now. If you stop this process windows won't pipe commands from linux docker container anymore"
. "$scriptRoot\handler.ps1"