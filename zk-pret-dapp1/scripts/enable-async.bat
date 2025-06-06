@echo off
echo.
echo ========================================
echo   ZK-PRET Async Features Enabler
echo ========================================
echo.
echo Checking current configuration...
echo.

REM Check if async features are already enabled
findstr "ENABLE_ASYNC_JOBS=true" .env >nul
if %errorlevel%==0 (
    echo ✓ Async features are already enabled!
    echo.
    echo Current async features:
    echo   - Background job processing
    echo   - WebSocket real-time updates  
    echo   - Job queue management
    echo   - Progress tracking
    echo.
    echo Restart your server to ensure all features are active:
    echo   npm run dev-async
    echo.
    pause
    exit /b 0
)

echo Adding async configuration to .env file...
echo.
echo # Async Features Configuration >> .env
echo ENABLE_ASYNC_JOBS=true >> .env
echo ENABLE_WEBSOCKETS=true >> .env
echo ENABLE_JOB_PERSISTENCE=false >> .env
echo ENABLE_BROWSER_NOTIFICATIONS=true >> .env
echo ENABLE_JOB_RECOVERY=true >> .env
echo ENABLE_ENHANCED_UI=true >> .env
echo ENABLE_POLLING_FALLBACK=true >> .env
echo.
echo ✓ Async features successfully enabled!
echo.
echo Features now available:
echo   ✓ Background job processing
echo   ✓ WebSocket real-time updates
echo   ✓ Job queue with progress tracking
echo   ✓ Browser notifications
echo   ✓ Enhanced UI with sync/async toggle
echo   ✓ Auto fallback if WebSockets fail
echo.
echo Next steps:
echo   1. Start the enhanced async server:
echo      npm run dev-async
echo.
echo   2. Open http://localhost:3000 in your browser
echo   3. Use the Sync/Async toggle in the top-right
echo   4. Submit jobs and switch tabs freely in async mode!
echo.
pause 
