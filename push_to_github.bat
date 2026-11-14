@echo off
echo ========================================================
echo   Pushing Invoice App to GitHub (moh500600/invoice_app)
echo ========================================================
echo.
cd /d "E:\in"
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================================
    echo   SUCCESS: Code uploaded to GitHub successfully!
    echo   Go to: https://github.com/moh500600/invoice_app/actions
    echo   Your Windows EXE is now building!
    echo ========================================================
) else (
    echo ========================================================
    echo   ERROR: Push failed. Check your internet connection.
    echo ========================================================
)
pause
