@echo off
setlocal
rem One-click web build: export to .\web, serve it locally, open the browser.
rem Needs the Godot Web export templates once only:
rem   Godot editor -> Project -> Export -> Install Export Templates  (about 1.3 GB)
rem After changing code, force a re-export by running this file with: rebuild
cd /d "%~dp0"

set "GODOT=E:\godot\Godot_v4.7.2-stable_win64_console.exe"
rem export_presets.cfg turns threads off, so Godot looks for the nothreads templates
set "TPL=%APPDATA%\Godot\export_templates\4.7.2.stable\web_nothreads_release.zip"
set "PORT=8765"

if /i "%~1"=="rebuild" del /q "web\index.html" 2>nul

if not exist "%GODOT%" (
    echo [ERROR] Godot not found: %GODOT%
    echo         Edit the GODOT path at the top of this file.
    pause
    exit /b 1
)

where python >nul 2>nul || (
    echo [ERROR] Python not found. It is only used to serve the build over HTTP:
    echo         a wasm build cannot be opened straight from a file:// path.
    pause
    exit /b 1
)

if not exist "web\index.html" (
    if not exist "%TPL%" (
        echo [ERROR] Web export template is not installed:
        echo         %TPL%
        echo.
        echo         Open the Godot editor, then Project - Export - Install Export Templates,
        echo         and run this file again afterwards.
        pause
        exit /b 1
    )
    echo [1/2] Exporting Web build to .\web ...
    rem Godot will not create the export folder itself - it fails with
    rem "target folder does not exist or is not accessible" instead.
    if not exist web mkdir web
    "%GODOT%" --headless --path godot --export-release Web "../web/index.html"
    if not exist "web\index.html" (
        echo [ERROR] Export failed - see the messages above.
        pause
        exit /b 1
    )
)

echo [2/2] Serving http://127.0.0.1:%PORT%/
start "Yunoyu Web Server" /min cmd /c "python -m http.server %PORT% --bind 0.0.0.0 --directory web"
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:%PORT%/"

echo.
echo Play in the browser : http://127.0.0.1:%PORT%/
echo Play on a phone     : same Wi-Fi, then one of these LAN addresses
ipconfig | findstr /i "IPv4"
echo.
echo If the phone cannot load the page, allow Python through Windows Firewall
echo for private networks. Keep the minimized "Yunoyu Web Server" window open
echo while playing; close it to stop the server.
pause
