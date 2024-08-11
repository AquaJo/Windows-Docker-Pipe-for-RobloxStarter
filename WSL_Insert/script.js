#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const prefix = process.argv[1].split("/").pop().split("\\").pop().trim();

// function to convert paths like D:/ into /mnt/d/ so docker container can access data
function convertWindowsPathToLinuxPath(winPath) {
  // e.g. replace "C:\" by "/mnt/c/"
  let linuxPath = winPath.replace(
    /^([A-Z]):\\/,
    (match, p1) => `/mnt/${p1.toLowerCase()}/`
  );
  // replace all "\" with "/"
  linuxPath = linuxPath.replace(/\\/g, "/");
  return linuxPath;
}

// get environment-variable that passed compose directory in windows format into container (see container build scripts, not compose or dockerfile!!)
const COMPOSE_DIR = process.env.COMPOSE_DIR;
const convertedPath = convertWindowsPathToLinuxPath(COMPOSE_DIR); // convert it to valid linux path

const counterPath = "/WSL/counter.txt"; // counter as unique identifier for a process, feel free setting counter.txt to 0 again if ya want on a new container start or sth.
const currentCounter = getCounter();
const nextCounter = currentCounter + 1;

const commandPath = path.join(
  convertedPath,
  "outstanding",
  "command" + currentCounter + ".txt"
); // commands first come into outstanding directory to be recognized by handler properly
saveCounter(nextCounter);

const execFilePathBaseWin = path.join(
  COMPOSE_DIR,
  "processes",
  "execFile" + currentCounter
);
const execFilePathBase = path.join(
  convertedPath,
  "processes",
  "execFile" + currentCounter
);
let command =
  prefix +
  " " +
  process.argv
    .slice(2)
    .map((arg) => {
      if (
        arg.charAt(0) !== "-" &&
        arg.charAt(0) !== "/" &&
        arg.charAt(0) !== '"' &&
        // Prüfen, ob der String einen Zeilenumbruch enthält
        !arg.includes("\n") &&
        !arg.includes("\r")
      ) {
        return `"${arg}"`;
      } else {
        return arg;
      }
    })
    .join(" ");
// test if a file src is referenced through -File param and make it available in windows (direct windows paths wont work & it will also copy it to the processes folder if its already a windows mount reference)
// if you use -File be sure you don't use spaces in the path as of now!!
const fileParamRegex = / -File ([\/][^\s]+)/;

if (fileParamRegex.test(command)) {
  let filePath = command.match(fileParamRegex)[1];
  const fileExtensionRegex = /(?:\.([^.]+))?$/;
  const match = filePath.match(fileExtensionRegex);
  fileExtension = match[1];
  let newPathWin = execFilePathBaseWin + "." + fileExtension;
  let newPathLinux = execFilePathBase + "." + fileExtension;
  command = command.replace(fileParamRegex, ` -File "${newPathWin}"`);
  // write file to new path while file is still in old path
  fs.writeFileSync(newPathLinux, fs.readFileSync(filePath, "utf8"));
}

const outputPath =
  convertedPath + "/processes/" + "output" + currentCounter + ".txt";

const finishedPath =
  convertedPath + "/processes/" + "finished" + currentCounter + ".txt"; // file that gets created when output is finally finished written down
watchOutput();
//const command = 'cmd.exe "hi" "bye"';
sendCommand();

function sendCommand() {
  // Schreibe den Befehl in die Datei
  fs.writeFile(commandPath, command, (err) => {
    if (err) {
      console.error("Error writing file:", err);
    } else {
      // console.log("Command file written successfully.");
    }
  });
}

function watchOutput() {
  // uses finishedPath to listen when output file is fully finished / streamed
  // maximum wait time (1 minute = 60000 milliseconds)
  const MAX_WAIT_TIME = 60000;

  // polling interval
  const POLLING_INTERVAL = 300;

  let timeoutHandle;

  function checkFile() {
    if (fs.existsSync(finishedPath)) {
      // split lines
      let outputContentData = fs.readFileSync(outputPath, "utf8");
      const lines = outputContentData.split("\n");

      // remove last line if empty
      while (lines.length > 0 && lines[lines.length - 1].trim() === "") {
        lines.pop();
      }

      // log the right output
      console.log(lines.join("\n"));
      //console.log(fs.readFileSync(outputPath, "utf8"));
      clearTimeout(timeoutHandle);
      clearInterval(intervalId);
    }
  }

  function stopPolling() {
    console.log("No file change detected within 1 minute. Stopping watch.");
    process.exit();
  }

  checkFile();

  const intervalId = setInterval(checkFile, POLLING_INTERVAL);

  timeoutHandle = setTimeout(() => {
    clearInterval(intervalId);
    stopPolling();
  }, MAX_WAIT_TIME);
}

function getCounter() {
  if (fs.existsSync(counterPath)) {
    const data = fs.readFileSync(counterPath, "utf8");
    return parseInt(data, 10);
  }
  return 0;
}

function saveCounter(counter) {
  fs.writeFileSync(counterPath, counter.toString(), "utf8");
}
