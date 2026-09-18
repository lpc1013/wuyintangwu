@echo off
setlocal
set "GODOT=E:\godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
    echo [ERROR] Godot not found: %GODOT%
    echo Install Godot 4.7 there, or edit the GODOT path in this file.
    pause
    exit /b 1
)
cd /d "%~dp0"
start "" "%GODOT%" --path "godot"
