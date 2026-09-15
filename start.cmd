@echo off
REM ===========================================================
REM  start.cmd - launcher for PowerShell / Command Prompt / double-click
REM
REM  Finds Git Bash and hands start.sh to it, so you do not have
REM  to open Git Bash yourself. Just double-click this file, or run
REM  it from PowerShell:   .\start.cmd
REM
REM  ASCII only on purpose: cmd.exe misreads UTF-8 Korean and tries
REM  to execute those lines as commands.
REM ===========================================================
setlocal
set "SH="
for %%P in (
  "%ProgramFiles%\Git\bin\bash.exe"
  "%ProgramFiles(x86)%\Git\bin\bash.exe"
  "%LocalAppData%\Programs\Git\bin\bash.exe"
) do if not defined SH if exist %%P set "SH=%%~P"
if not defined SH for /f "delims=" %%P in (
'where bash 2^>nul'
) do if not defined SH set "SH=%%P"
if not defined SH (
  echo.
  echo   Git is not installed on this computer.
  echo   Install it from https://git-scm.com/downloads
  echo   then run this file again.
  echo.
  pause
  exit /b 1
)
"%SH%" "%~dp0start.sh" %*
if errorlevel 1 pause
