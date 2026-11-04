@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Диагностика и аудит компьютера

REM ============================================
REM Практическая работа 8. Часть 2: Аудит ПО
REM ============================================

set "REPORT=%~dp0pc_report.txt"
set "TEMP_APPS=%TEMP%\apps_list.txt"
set /a REC_COUNT=0

REM Очищаем отчёт
break > "%REPORT%"

REM ----- Заголовок отчёта -----
call :log "Диагностика компьютера"
call :log "=============================================="
call :log "Дата формирования отчёта: %date% %time%"
call :log ""

REM ----- Сбор данных о системе -----
call :log "Сбор данных о системе..."

REM ОС
set "OS_NAME="
set "OS_VER="
for /f "delims=" %%A in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Caption"') do set "OS_NAME=%%A"
for /f "delims=" %%A in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Version"') do set "OS_VER=%%A"
call :log "Операционная система"
if defined OS_NAME (call :log "  Название: !OS_NAME!") else (call :log "  Название: не удалось получить")
if defined OS_VER (call :log "  Версия: !OS_VER!") else (call :log "  Версия: не удалось получить")
call :log ""

REM Процессор
set "CPU_NAME="
for /f "delims=" %%A in ('powershell -command "(Get-CimInstance Win32_Processor).Name"') do set "CPU_NAME=%%A"
call :log "Процессор"
if defined CPU_NAME (call :log "  !CPU_NAME!") else (call :log "  не удалось получить")
call :log ""

REM Память
set "TotalGB="
set "FreeGB="
for /f "delims=" %%A in ('powershell -command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1048576)"') do set "TotalGB=%%A"
for /f "delims=" %%A in ('powershell -command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1048576)"') do set "FreeGB=%%A"
call :log "Оперативная память"
if defined TotalGB (call :log "  Всего памяти: !TotalGB! ГБ") else (call :log "  Всего памяти: не удалось получить")
if defined FreeGB (call :log "  Свободно памяти: !FreeGB! ГБ") else (call :log "  Свободно памяти: не удалось получить")
call :log ""

REM Диск C
set "UsedDisk="
set "FreeDisk="
set "TotalDisk="
for /f "delims=" %%A in ('powershell -command "[math]::Floor((Get-PSDrive C).Used / 1GB)"') do set "UsedDisk=%%A"
for /f "delims=" %%A in ('powershell -command "[math]::Floor((Get-PSDrive C).Free / 1GB)"') do set "FreeDisk=%%A"
if defined UsedDisk if defined FreeDisk (
    set /a TotalDisk=UsedDisk+FreeDisk
    call :log "Диск C"
    call :log "  Всего места: !TotalDisk! ГБ"
    call :log "  Свободно места: !FreeDisk! ГБ"
) else (
    call :log "Диск C"
    call :log "  не удалось получить данные"
)
call :log ""

REM ----- Сбор списка программ через PowerShell -----
call :log "Опрос реестра для получения списка программ..."
powershell -noprofile -command "$p=@('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'); $a=Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object -ExpandProperty DisplayName | Sort-Object -Unique; [System.IO.File]::WriteAllLines('%TEMP_APPS%', $a, [System.Text.Encoding]::UTF8)"

if not exist "%TEMP_APPS%" (
    call :log "ОШИБКА: Не удалось получить список программ."
    goto :skip_audit
)
for %%A in ("%TEMP_APPS%") do if %%~zA EQU 0 (
    call :log "ОШИБКА: Список программ пуст."
    goto :skip_audit
)

REM Отладка: показываем количество найденных программ
for /f %%C in ('type "%TEMP_APPS%" ^| find /c /v ""') do set "APP_COUNT=%%C"
call :log "Найдено установленных программ: !APP_COUNT!"
call :log ""

REM ----- Анализ: Проверка базового ПО -----
call :log "=============================================="
call :log "РЕКОМЕНДАЦИИ ПО БАЗОВОМУ ОФИСНОМУ ПО"
call :log "=============================================="

call :log "Проверка офисного пакета:"
set "FOUND_APP="
for /f "delims=" %%A in ('findstr /i /c:"Office" /c:"LibreOffice" /c:"OpenOffice" /c:"МойОфис" "%TEMP_APPS%"') do (
    if not defined FOUND_APP set "FOUND_APP=%%A"
)
if defined FOUND_APP (
    call :log "  [ОК] Найден офисный пакет: !FOUND_APP!"
) else (
    call :log "  [!] Не обнаружен офисный пакет. Рекомендуется установить Microsoft Office или LibreOffice."
    set /a REC_COUNT+=1
)
call :log ""

call :log "Проверка браузера:"
set "FOUND_APP="
for /f "delims=" %%A in ('findstr /i /c:"Chrome" /c:"Firefox" /c:"Edge" /c:"Яндекс" "%TEMP_APPS%"') do (
    if not defined FOUND_APP set "FOUND_APP=%%A"
)
if defined FOUND_APP (
    call :log "  [ОК] Найден браузер: !FOUND_APP!"
) else (
    call :log "  [!] Не обнаружен браузер. Рекомендуется установить Google Chrome или Яндекс.Браузер."
    set /a REC_COUNT+=1
)
call :log ""

call :log "Проверка программы для PDF:"
set "FOUND_APP="
for /f "delims=" %%A in ('findstr /i /c:"Acrobat" /c:"Foxit" /c:"SumatraPDF" "%TEMP_APPS%"') do (
    if not defined FOUND_APP set "FOUND_APP=%%A"
)
if defined FOUND_APP (
    call :log "  [ОК] Найдена программа: !FOUND_APP!"
) else (
    call :log "  [!] Не обнаружена программа для PDF. Рекомендуется установить Adobe Acrobat Reader."
    set /a REC_COUNT+=1
)
call :log ""

call :log "Проверка архиватора:"
set "FOUND_APP="
for /f "delims=" %%A in ('findstr /i /c:"7-Zip" /c:"WinRAR" /c:"WinZip" "%TEMP_APPS%"') do (
    if not defined FOUND_APP set "FOUND_APP=%%A"
)
if defined FOUND_APP (
    call :log "  [ОК] Найден архиватор: !FOUND_APP!"
) else (
    call :log "  [!] Не обнаружен архиватор. Рекомендуется установить 7-Zip или WinRAR."
    set /a REC_COUNT+=1
)
call :log ""

call :log "Проверка антивируса:"
set "FOUND_APP="
for /f "delims=" %%A in ('findstr /i /c:"Defender" /c:"Kaspersky" /c:"ESET" /c:"Dr.Web" "%TEMP_APPS%"') do (
    if not defined FOUND_APP set "FOUND_APP=%%A"
)
if defined FOUND_APP (
    call :log "  [ОК] Найден антивирус: !FOUND_APP!"
) else (
    call :log "  [!] Не обнаружен антивирус. Рекомендуется установить антивирусное ПО."
    set /a REC_COUNT+=1
)
call :log ""

REM ----- Анализ: Проверка излишнего ПО -----
call :log "=============================================="
call :log "ПРОВЕРКА ИЗЛИШНЕГО НЕПРОФИЛЬНОГО ПО"
call :log "=============================================="
call :log "Внимание: ниже приведен список ПО для проверки, а не для удаления."

call :log "Игровое ПО и платформы:"
set "FOUND_ANY=0"
for /f "delims=" %%A in ('findstr /i /c:"Steam" /c:"Epic Games" /c:"GOG" /c:"Origin" /c:"Ubisoft" /c:"Battle.net" /c:"Riot" /c:"game" /c:"gaming" "%TEMP_APPS%"') do (
    set "APP_NAME=%%A"
    call :log_found "!APP_NAME!"
    set "FOUND_ANY=1"
    set /a REC_COUNT+=1
)
if "!FOUND_ANY!"=="0" call :log "  [ОК] Игровое ПО не обнаружено."
call :log ""

call :log "Торрент-клиенты и файлообменники:"
set "FOUND_ANY=0"
for /f "delims=" %%A in ('findstr /i /c:"torrent" /c:"uTorrent" /c:"BitTorrent" /c:"qBittorrent" /c:"Vuze" "%TEMP_APPS%"') do (
    set "APP_NAME=%%A"
    call :log_found "!APP_NAME!"
    set "FOUND_ANY=1"
    set /a REC_COUNT+=1
)
if "!FOUND_ANY!"=="0" call :log "  [ОК] Торрент-клиенты не обнаружены."
call :log ""

call :log "Мессенджеры для личного общения:"
set "FOUND_ANY=0"
for /f "delims=" %%A in ('findstr /i /c:"Discord" /c:"Telegram" /c:"WhatsApp" /c:"Viber" /c:"Skype" "%TEMP_APPS%"') do (
    set "APP_NAME=%%A"
    call :log_found "!APP_NAME!"
    set "FOUND_ANY=1"
    set /a REC_COUNT+=1
)
if "!FOUND_ANY!"=="0" call :log "  [ОК] Сторонние мессенджеры не обнаружены."
call :log ""

call :log "Инструменты для развлечений:"
set "FOUND_ANY=0"
for /f "delims=" %%A in ('findstr /i /c:"Wallpaper Engine" /c:"OBS" /c:"Soundpad" "%TEMP_APPS%"') do (
    set "APP_NAME=%%A"
    call :log_found "!APP_NAME!"
    set "FOUND_ANY=1"
    set /a REC_COUNT+=1
)
if "!FOUND_ANY!"=="0" call :log "  [ОК] Инструменты для развлечений не обнаружены."
call :log ""

:skip_audit
REM ----- Завершение -----
call :log "=============================================="
call :log "Вывод скрипта является рекомендацией к проверке, а не указанием к удалению."
call :log "Всего выдано рекомендаций: !REC_COUNT!"
call :log "Путь к файлу отчёта: %REPORT%"
call :log "=============================================="

if exist "%TEMP_APPS%" del "%TEMP_APPS%"
pause
exit /b

REM ============================================
REM ПОДПРОГРАММЫ ВЫВОДА
REM ============================================
:log
if "%~1"=="" (
    echo(
    echo( >> "%REPORT%"
) else (
    echo(%~1
    echo(%~1 >> "%REPORT%"
)
exit /b

:log_found
echo(  [!] Обнаружено: %~1
echo(  [!] Обнаружено: %~1 >> "%REPORT%"
exit /b
