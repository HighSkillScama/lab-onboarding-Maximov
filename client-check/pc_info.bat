@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
REM ============================================
REM Практическая работа: Диагностика клиентского компьютера
REM Автор: [Maximov M.S.]
REM Дата: [04.11.2026]
REM ============================================

set "REPORT=%~dp0pc_report.txt"

REM ----- Заголовок -----
echo Диагностика компьютера > "%REPORT%"
echo ============================== >> "%REPORT%"
echo.
echo Диагностика компьютера
echo ==============================
echo.

REM ----- Операционная система -----
echo Операционная система
echo Операционная система >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Caption"') do (
    set "OSNAME=%%a"
    echo   Название: !OSNAME!
    echo   Название: !OSNAME! >> "%REPORT%"
)
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Version"') do (
    set "OSVER=%%a"
    echo   Версия: !OSVER!
    echo   Версия: !OSVER! >> "%REPORT%"
)
echo.

REM ----- Процессор -----
echo Процессор
echo Процессор >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_Processor).Name"') do (
    set "CPU=%%a"
    echo   !CPU!
    echo   !CPU! >> "%REPORT%"
)
echo.

REM ----- Оперативная память -----
echo Оперативная память
echo Оперативная память >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1048576)"') do set "TotalGB=%%a"
for /f "delims=" %%a in ('powershell -command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1048576)"') do set "FreeGB=%%a"
echo   Всего памяти: !TotalGB! ГБ
echo   Всего памяти: !TotalGB! ГБ >> "%REPORT%"
echo   Свободно памяти: !FreeGB! ГБ
echo   Свободно памяти: !FreeGB! ГБ >> "%REPORT%"
echo.

REM ----- Диск C -----
echo Диск C
echo Диск C >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "[math]::Floor((Get-PSDrive C).Used / 1GB)"') do set "UsedDisk=%%a"
for /f "delims=" %%a in ('powershell -command "[math]::Floor((Get-PSDrive C).Free / 1GB)"') do set "FreeDisk=%%a"
set /a TotalDisk=UsedDisk+FreeDisk
echo   Всего места: !TotalDisk! ГБ
echo   Всего места: !TotalDisk! ГБ >> "%REPORT%"
echo   Свободно места: !FreeDisk! ГБ
echo   Свободно места: !FreeDisk! ГБ >> "%REPORT%"
echo.

REM ----- Установленные программы (через реестр) -----
echo Установленные программы
echo Установленные программы >> "%REPORT%"
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    if not "%%b"=="" (
        set "PROG=%%b"
        echo   !PROG!
        echo   !PROG! >> "%REPORT%"
    )
)
for /f "tokens=2,*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr /i "DisplayName"') do (
    if not "%%b"=="" (
        set "PROG=%%b"
        echo   !PROG!
        echo   !PROG! >> "%REPORT%"
    )
)
echo.

REM ----- Завершение -----
echo Отчёт сохранён
echo Отчёт сохранён >> "%REPORT%"
echo Файл отчёта: %REPORT%
pause
