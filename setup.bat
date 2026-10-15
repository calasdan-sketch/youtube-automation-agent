@echo off
REM ============================================================================
REM  DropWatch YouTube Agent - one-click setup
REM  Double-click this file. It updates itself first, then installs what it
REM  needs, then walks you through the one thing only you can do (your AI key).
REM  Re-running it is always safe: it skips what's already done and repairs
REM  what's broken. Never delete folders or kill its windows by hand.
REM ============================================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title DropWatch YouTube Agent Setup

set "REPO_RAW=https://raw.githubusercontent.com/calasdan-sketch/youtube-automation-agent/master"

if not defined YT_SETUP_RESTARTED (
    REM --- Step 0: Self-update -----------------------------------------------
    REM A ZIP download has no .git, so fetch the setup files fresh. A fix
    REM pushed to the fork reaches this folder the next time you double-click
    REM this file - no re-downloading, no dragging files between folders.
    if not exist ".git" (
        echo  [0/5] Checking for setup updates...
        call :fetch_file "!REPO_RAW!/setup.bat" "setup.bat.new" "DropWatch YouTube Agent Setup"
        if "!FF_OK!"=="1" (
            fc /b setup.bat setup.bat.new >nul 2>nul
            if !errorlevel! neq 0 (
                move /y setup.bat.new setup.bat >nul
                echo  Setup updated itself - restarting with the fixed version...
                echo.
                set "YT_SETUP_RESTARTED=1"
                call "%~dp0setup.bat"
                exit /b 0
            )
            del setup.bat.new >nul 2>nul
        ) else (
            echo  (couldn't reach the update server - continuing with this copy)
        )
        call :fetch_file "!REPO_RAW!/utils/credential-manager.js" "utils\credential-manager.js" "runSetupWizard"
        if "!FF_OK!"=="1" (
            echo  [0/5] Setup files are current.
        ) else (
            echo  (couldn't refresh the wizard - continuing with this copy)
        )
        echo.
    ) else (
        echo  [0/5] Pulling latest...
        git pull --ff-only --quiet >nul 2>nul
        echo.
    )
)

REM --- Step 1: Node.js -------------------------------------------------------
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo  [1/5] Node.js not found. Installing...
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
for /f "tokens=*" %%v in ('node --version') do echo  [1/5] Node.js found %%v

REM --- Step 2: Dependencies --------------------------------------------------
set "NEED_INSTALL=0"
if not exist "node_modules" (
    set "NEED_INSTALL=1"
) else (
    REM node_modules exists but may be half-installed if a previous install
    REM was interrupted. Verify a key module actually loads before trusting it.
    node -e "require('inquirer');require('chalk')" >nul 2>nul
    if !errorlevel! neq 0 set "NEED_INSTALL=1"
)
if "!NEED_INSTALL!"=="1" (
    if exist "node_modules" (
        echo  [2/5] Last install was interrupted - clearing it and starting fresh...
        rmdir /s /q node_modules
    ) else (
        echo  [2/5] Installing pieces... (a few minutes, normal)
        echo.
    )
    call npm install --no-audit --no-fund
    if !errorlevel! neq 0 (
        echo.
        echo  ERROR: npm install failed - usually just the internet.
        echo  Double-click setup.bat again and it picks up where it stopped.
        echo.
        pause
        exit /b 1
    )
) else (
    echo  [2/5] Pieces already installed.
)

REM --- Step 3: Self-test ------------------------------------------------------
echo  [3/5] Running self-test...
call npm test 2>&1 | findstr /c:"All tests passed" >nul
if %errorlevel% neq 0 (
    echo.
    echo  WARNING: self-test reported a problem. Continuing anyway -
    echo  credential setup may still work.
    echo.
) else (
    echo  [3/5] Self-test passed.
)

REM --- Step 4: Credentials (the one thing only you can do) --------------------
echo.
echo  ======================================================================
echo   [4/5] One quick thing, then you're done:
echo.
echo   Your AI key: pick "OpenRouter" and paste the key starting
echo   with sk-or- (free models cost nothing - leave any limit blank).
echo.
echo   Say NO to YouTube for now. Nothing uploads or schedules without
echo   your approval anyway - you can add it any time by re-running this.
echo  ======================================================================
echo.
pause

call npm run credentials:setup

echo.
echo  ======================================================================
echo   Done. Run the agent any time with:  npm start
echo   Nothing uploads or schedules without your approval.
echo  ======================================================================
echo.
pause
exit /b 0

REM ============================================================================
REM  Subroutine: download a URL to a file, verify it contains a marker string.
REM  %1 = URL, %2 = destination path, %3 = marker text the file must contain.
REM  Sets FF_OK=1 on success, FF_OK=0 on any failure. Never leaves a partial
REM  or wrong file behind at the destination.
REM ============================================================================
:fetch_file
set "FF_URL=%~1"
set "FF_DEST=%~2"
set "FF_MARKER=%~3"
set "FF_OK=0"
if exist "%FF_DEST%" del "%FF_DEST%" >nul 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { (New-Object System.Net.WebClient).DownloadFile($env:FF_URL, $env:FF_DEST) } catch { exit 1 }"
if %errorlevel% neq 0 goto :fetch_done
if not exist "%FF_DEST%" goto :fetch_done
findstr /c:"%FF_MARKER%" "%FF_DEST%" >nul 2>nul
if %errorlevel% neq 0 goto :fetch_done
set "FF_OK=1"
:fetch_done
exit /b 0
