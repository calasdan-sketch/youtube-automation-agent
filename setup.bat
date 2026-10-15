@echo off
REM ============================================================================
REM  DropWatch YouTube Agent - one-click setup
REM  Double-click this file. It installs what it needs and walks you through
REM  the two things only you can do (your freellmapi key, your YouTube login).
REM ============================================================================
setlocal EnableDelayedExpansion

cd /d "%~dp0"
title DropWatch YouTube Agent Setup

echo.
echo  ======================================================================
echo   DropWatch YouTube Agent - Setup
echo  ======================================================================
echo.

REM --- Step 1: Node.js -------------------------------------------------------
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo  [1/4] Node.js not found. Installing...
    echo.
    where winget >nul 2>nul
    if %errorlevel% neq 0 (
        echo  ERROR: Couldn't install Node.js automatically.
        echo.
        echo  Please do this once, then double-click setup.bat again:
        echo    1. Go to https://nodejs.org
        echo    2. Download the LTS version and run the installer
        echo    3. Click Next through everything
        echo.
        pause
        exit /b 1
    )
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    echo.
    echo  Node.js installed. Please CLOSE this window and double-click
    echo  setup.bat again to continue.
    echo.
    pause
    exit /b 0
)
for /f "tokens=*" %%v in ('node --version') do echo  [1/4] Node.js found %%v

REM --- Step 2: Dependencies --------------------------------------------------
if not exist "node_modules" (
    echo  [2/4] Installing pieces... (a few minutes, normal)
    echo.
    call npm install --no-audit --no-fund
    if %errorlevel% neq 0 (
        echo.
        echo  ERROR: npm install failed. Check your internet and try again.
        pause
        exit /b 1
    )
) else (
    echo  [2/4] Pieces already installed.
)

REM --- Step 3: Self-test ------------------------------------------------------
echo  [3/4] Running self-test...
call npm test 2>&1 | findstr /c:"All tests passed" >nul
if %errorlevel% neq 0 (
    echo.
    echo  WARNING: self-test reported a problem. Continuing anyway -
    echo  credential setup may still work.
    echo.
) else (
    echo  [3/4] Self-test passed.
)

REM --- Step 4: Credentials (the two things only you can do) ------------------
echo.
echo  ======================================================================
echo   [4/4] Two quick things, then you're done:
echo.
echo   A. Your freellmapi: have your endpoint URL, API key, and model
echo      name ready. Pick "Custom" when asked.
echo.
echo   B. Your YouTube: you'll create a Google Cloud project once
echo      (I'll open the pages for you) and paste back a code.
echo  ======================================================================
echo.
pause

call npm run credentials:setup

echo.
echo  ======================================================================
echo   Done. Run the agent with:  npm start
echo   Nothing uploads without your approval. Everything defaults to private.
echo  ======================================================================
echo.
pause
