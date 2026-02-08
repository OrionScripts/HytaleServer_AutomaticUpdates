@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%cd%"
set "TMP=%ROOT%\updater\_extract"

echo [Update] Running hytale-downloader...
hytale-downloader\hytale-downloader.exe
if errorlevel 1 (
  echo [Update] ERROR: downloader failed
  exit /b 1
)

REM ---- Find newest version zip in ROOT (not Assets.zip) ----
set "ZIP="
for /f "delims=" %%Z in ('dir /b /a:-d /o-d "%ROOT%\20*.zip"') do (
  set "ZIP=%ROOT%\%%Z"
  set "VER=%%~nZ"
  goto :foundzip
)
:foundzip

if not defined ZIP (
  echo [Update] ERROR: No version zip found
  exit /b 2
)

echo [Update] Using zip: "%ZIP%"

REM ---- Extract ----
echo [Update] Extracting to temp...
if exist "%TMP%" rmdir /s /q "%TMP%"
mkdir "%TMP%"

powershell -NoProfile -Command ^
  "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%TMP%' -Force"
if errorlevel 1 (
  echo [Update] ERROR: extraction failed
  exit /b 3
)

REM ---- Normalize payload root ----
set "PAYLOAD=%TMP%"
if not exist "%PAYLOAD%\Assets.zip" (
  for /f "delims=" %%D in ('dir /b /ad "%TMP%"') do (
    if exist "%TMP%\%%D\Assets.zip" (
      set "PAYLOAD=%TMP%\%%D"
      goto :payloadok
    )
  )
)
:payloadok

if not exist "%PAYLOAD%\Assets.zip" (
  echo [Update] ERROR: Assets.zip not found in payload
  exit /b 4
)

REM ---- Backup current distro ----
set "BK=%ROOT%\Backups\%VER%"
mkdir "%BK%\Server" >nul 2>&1

if exist "%ROOT%\Assets.zip" copy /y "%ROOT%\Assets.zip" "%BK%\Assets.zip" >nul
if exist "%ROOT%\Server\HytaleServer.jar" copy /y "%ROOT%\Server\HytaleServer.jar" "%BK%\Server\HytaleServer.jar" >nul
if exist "%ROOT%\Server\HytaleServer.aot" copy /y "%ROOT%\Server\HytaleServer.aot" "%BK%\Server\HytaleServer.aot" >nul
if exist "%ROOT%\Server\Licenses" xcopy /s /e /i /y "%ROOT%\Server\Licenses" "%BK%\Server\Licenses" >nul

REM ---- APPLY (this is the part you were missing) ----
echo [Update] Applying distribution files...

copy /y "%PAYLOAD%\Assets.zip" "%ROOT%\Assets.zip" >nul
copy /y "%PAYLOAD%\Server\HytaleServer.jar" "%ROOT%\Server\HytaleServer.jar" >nul

if exist "%PAYLOAD%\Server\HytaleServer.aot" (
  copy /y "%PAYLOAD%\Server\HytaleServer.aot" "%ROOT%\Server\HytaleServer.aot" >nul
)

if exist "%PAYLOAD%\Server\Licenses" (
  if exist "%ROOT%\Server\Licenses" rmdir /s /q "%ROOT%\Server\Licenses"
  xcopy /s /e /i /y "%PAYLOAD%\Server\Licenses" "%ROOT%\Server\Licenses" >nul
)

REM ---- CLEANUP ----
echo [Update] Cleaning temp and zip...
rmdir /s /q "%TMP%"
del /f /q "%ZIP%" >nul

echo [Update] Done.
exit /b 0
