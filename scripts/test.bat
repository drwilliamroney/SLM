@echo off
setlocal enabledelayedexpansion

echo ########### Loading Configuration ############
for /F "delims== tokens=1,* eol=#" %%i in ('type config\config.txt') do set %%i=%%~j

curl http://localhost:8000/v1/models
curl http://localhost:8000/v1/completions -H "Content-Type: application/json" -d "{\"model\": \"!PRELOADED_MODEL!\",\"prompt\":\"San Francisco is a\"}"

:exit
echo Done.
endlocal

