@echo off
setlocal enabledelayedexpansion

echo ########### Loading Configuration ############
for /F "delims== tokens=1,* eol=#" %%i in ('type config\config.txt') do set %%i=%%~j
echo Using Ubuntu version !UBUNTU_VERSION!

echo ###########   Checking for Tools  ############
for %%a in (findstr.exe) do set _GREP_PROGRAM=%%~$PATH:a
for %%a in (curl.exe) do set _CURL_PROGRAM=%%~$PATH:a
for %%a in (git.exe) do set _GIT_PROGRAM=%%~$PATH:a
for %%a in (podman.exe) do set _CONTAINER_PROGRAM=%%~$PATH:a
if "!_CONTAINER_PROGRAM!" == "" (
  for %%a in (docker.exe) do set _CONTAINER_PROGRAM=%%~$PATH:a
) else (
  echo Making sure "!_CONTAINER_PROGRAM!" is running
  "!_CONTAINER_PROGRAM!" machine start > nul
)

echo GREP is !_GREP_PROGRAM!
echo CURL is !_CURL_PROGRAM!
echo GIT is !_GIT_PROGRAM!
echo CONTAINER is !_CONTAINER_PROGRAM!

echo ###########    Detecting GPU Capabilities    ############
set VLLM_TARGET=cpu
rem ***Skipping GPU check***
goto skip_gpu

for %%a in (hipinfo.exe) do set _ROCM_PROGRAM=%%~$PATH:a
if "!_ROCM_PROGRAM!" NEQ "" set VLLM_TARGET=rocm
for %%a in (nvidia-smi.exe) do set _CUDA_PROGRAM=%%~$PATH:a
if "!_CUDA_PROGRAM!" NEQ "" set VLLM_TARGET=

:skip_gpu

echo !VLLM_TARGET!

rem ################### SLURM #################################
echo Building slurm version !SLURM_VERSION! (MD5:!SLURM_MD5!) using !UBUNTU_VERSION!

"!_CONTAINER_PROGRAM!" build --build-arg UBUNTU_VERSION=!UBUNTU_VERSION! --build-arg SLURM_VERSION=!SLURM_VERSION! --build-arg SLURM_MD5=!SLURM_MD5! -f docker\Dockerfile.slurm --tag slurm:!SLURM_VERSION! .

goto exit

rem #########################  Below is keeping in case you need to copy/paste ####################################
"!_CURL_PROGRAM!" https://raw.githubusercontent.com/vllm-project/vllm/refs/heads/main/docker/Dockerfile.!VLLM_TARGET! -o docker\Dockerfile.vllm

for /f "delims==,, tokens=5" %%f in ('!_GREP_PROGRAM! "\-\-mount\=type\=bind,src\=" docker\Dockerfile.vllm') do (
  for %%a in ("%%f") do (
    if exist %%~pf\ (
      echo %%~pf exists
    ) else (
      echo Creating %%~pf
      mkdir %%~pf
    )
  )
  echo Retrieving required file: %%f
  "!_CURL_PROGRAM!" https://raw.githubusercontent.com/vllm-project/vllm/refs/heads/main/%%f -o %%f
)

:exit
echo Done.
endlocal

