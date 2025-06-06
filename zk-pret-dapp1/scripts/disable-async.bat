@echo off 
echo Disabling async features... 
copy /y "config\production.env" ".env.async" >nul 
echo Async features disabled Restart the server to apply changes. 
pause 
