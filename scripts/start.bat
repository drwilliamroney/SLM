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

"!_CONTAINER_PROGRAM!" network create scalarlm

"!_CONTAINER_PROGRAM!" run --detach -p 8000:8000 !VLLM_RUNARGS! --network scalarlm --name vllm !VLLM_IMAGE! --model=!PRELOADED_MODEL! --dtype=bfloat16

"!_CONTAINER_PROGRAM!" run --detach --network scalarlm -p 3306:3306 --name slurm_acct_db -e MYSQL_RANDOM_ROOT_PASSWORD="yes" -e MYSQL_DATABASE=slurmacctdb -e MYSQL_USER=slurm -e MYSQL_PASSWORD=password mariadb 

"!_CONTAINER_PROGRAM!" run --detach --network scalarlm -p 6817:6817 !SLURM_RUNARGS! --name slurm_controller slurm:!SLURM_VERSION! slurmctld -D
"!_CONTAINER_PROGRAM!" run --detach --network scalarlm -p 6819:6819 !SLURM_RUNARGS! -e MYSQL_USER=slurm -e MYSQL_PASSWORD=password --name slurm_dbd slurm:!SLURM_VERSION! /bin/bash -c "/usr/sbin/startdbd.sh"

:exit
echo Done.
endlocal

