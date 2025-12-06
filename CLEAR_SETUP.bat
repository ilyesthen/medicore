@echo off
REM Clear MediCore Setup - Use this to test fresh installs
echo ========================================
echo MediCore Setup Cleaner
echo ========================================
echo.
echo This will DELETE all MediCore data:
echo - Configuration file
echo - Database file  
echo - All user data
echo.
pause

echo.
echo Clearing MediCore data...

REM Clear AppData\Roaming
if exist "%APPDATA%\medicore_app" (
    echo Deleting: %APPDATA%\medicore_app
    rmdir /s /q "%APPDATA%\medicore_app"
)

REM Clear AppData\Local
if exist "%LOCALAPPDATA%\medicore_app" (
    echo Deleting: %LOCALAPPDATA%\medicore_app
    rmdir /s /q "%LOCALAPPDATA%\medicore_app"
)

echo.
echo ========================================
echo DONE! MediCore data cleared.
echo Next app launch will show setup wizard.
echo ========================================
pause
