@echo off
echo === ZK-PRET Setup ===
echo Building ZK-PRET-TEST-V3 project...

cd /d "C:\SATHYA\ZK\ZK-PRET-CHAINAIMLABS\ZK-PRET-TEST-V3"
if errorlevel 1 (
    echo [ERROR] Failed to navigate to ZK-PRET-TEST-V3 directory
    pause
    exit /b 1
)

echo Current directory: %CD%

echo [INFO] Running npm run build...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo [SUCCESS] Build completed successfully!
echo [INFO] Checking for compiled files...

if exist "build\tests\with-sign\GLEIFVerificationTestWithSign.js" (
    echo [SUCCESS] Found: GLEIFVerificationTestWithSign.js
) else (
    echo [WARNING] Missing: GLEIFVerificationTestWithSign.js
)

echo.
echo === Setup Complete ===
echo You can now start the web app with: npm run dev
echo.
pause