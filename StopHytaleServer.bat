@echo off
echo Stopping Hytale Server...

powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'HytaleServer\.jar' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"

echo Done.
