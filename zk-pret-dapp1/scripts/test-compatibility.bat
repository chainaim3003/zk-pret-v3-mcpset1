@echo off 
echo Testing backward compatibility... 
call npm test 
if errorlevel 1 ( 
    echo Compatibility tests failed 
    pause 
    exit /b 1 
) 
echo All compatibility tests passed 
pause 
