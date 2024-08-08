# [RobloxStarter](https://github.com/AquaJo/RobloxStarter)-Docker-Build & Windows-Feature-Pipe-Prototype

This is a tool that enables working on Roblox-Projects using [RobloxStarter](https://github.com/AquaJo/RobloxStarter) inside of docker, so you don't need to install much of the required tools.
Because Roblox-Starter (former WSL2-Project) is dependant on the Windows-Host it was necessary to build a Host-Command-Integrator for docker, undergoing its sense of isolation.\
**Therefore its also a project that could be used as a docker-build template for enabling some windows commands - functionality inside of a docker-container.\
Use this project at your own "risk"!**

## How to use?

You can use this template directly by cloning this repo & executing the [buildContainer.ps1](./buildContainer.ps1) or by using it as a submodule included in [RobloxStarter](https://github.com/AquaJo/RobloxStarter) and running the desired npm command `npm run docker`.\
Be sure to run the npm command or the ps1 file before each session, so the command-piper is active! It shouldn't overwrite the existing container.

## What do I do?

I mainly make some functionality of windows commands and windows-host access available inside of docker containers by letting them address `powershell.exe` and `cmd.exe`

## Adaptions you'll need to undergo (e.g. in nodejs)

**<ins>Note:</ins> There wil be alot more stuff you might need to fix, but the following lists stuff I needed / noticed when porting RobloxStarter to Docker**

- When you need to parse JSON from a command's output feel free to do a `.toString().trim()` to make it working if its not working from ground up
- Keep in mind this command-piper will only export the output once its finished (if at all)
  - `.on (data)` wont work as expected and fires only one time (if at all) outputting the whole output log
  - to get the last entry feel free to use:\
    `data = data.split("\n"); data = data.length > 1 ? data[data.length - 2].trim() : data[0];`

## TODO

- Handle accumulation of zombie defuncts listed in `ps aux`
- Think about how to make docker supportive inside wsl itself
- Error passing?
- Smarter process handling, logging
- Infinite-Counter-Reset inside docker container processes-specifying?
