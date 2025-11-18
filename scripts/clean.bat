@echo off
setlocal enabledelayedexpansion

echo ########### Loading Configuration ############
for /F "delims== tokens=1,* eol=#" %%i in ('type config\config.txt') do set %%i=%%~j

echo ###########   Checking for Tools  ############
for %%a in (podman.exe) do set _CONTAINER_PROGRAM=%%~$PATH:a
if "!_CONTAINER_PROGRAM!" == "" (
  for %%a in (docker.exe) do set _CONTAINER_PROGRAM=%%~$PATH:a
) else (
  echo Making sure "!_CONTAINER_PROGRAM!" is running
  "!_CONTAINER_PROGRAM!" machine start > nul
)

echo CONTAINER is !_CONTAINER_PROGRAM!

"!_CONTAINER_PROGRAM!" container stop vllm slurm_acct_db slurm_controller slurm_dbd
"!_CONTAINER_PROGRAM!" container rm vllm slurm_acct_db slurm_controller slurm_dbd
"!_CONTAINER_PROGRAM!" image prune
"!_CONTAINER_PROGRAM!" network prune


:exit
echo Done.
endlocal
