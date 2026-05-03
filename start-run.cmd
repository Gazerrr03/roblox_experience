@echo off
setlocal
PowerShell -NoExit -ExecutionPolicy Bypass -File "%~dp0scripts\dev.ps1" -Place run %*
