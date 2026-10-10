@echo off
REM =============================================================================
REM build.bat - TeenyOS image builder
REM
REM Layout:
REM   LBA 0..83      : boot sector + kernel (83 sectors)
REM   LBA 84..199    : apps + padding
REM   LBA 200..203   : Spleen 5x8 font
REM   LBA 204..331   : wallpaper 0 (64 KB)
REM   LBA 332..459   : wallpaper 1 (64 KB)
REM   LBA 460..587   : wallpaper 2 (64 KB)
REM   padded to 10 MB HDD image
REM =============================================================================

setlocal enabledelayedexpansion
cd /d "%~dp0"

set KERNEL_SRC=teenyos.asm
set KERNEL_BIN=teenyos_kernel.bin
set IMAGE=teenyos.img
set KERNEL_SECTORS=256
set KERNEL_BYTES=%KERNEL_SECTORS%*512
set HDD_BYTES=10485760
set FONT_OFFSET=153600
set FONT_FILE=font\spleen-5x8.bin
set WALLPAPER_FILE=wallpaper.raw
set WALLPAPER2_FILE=wallpaper2.raw
set WALLPAPER3_FILE=wallpaper3.raw
set QEMU="C:\Program Files\qemu\qemu-system-x86_64.exe"

REM Suppress the label-redef-late cascade so real errors stay visible.
set NASM_FLAGS=-f bin -w-label-redef-late

echo.
echo === TeenyOS build ===
echo.

echo [1/8] Assembling kernel: %KERNEL_SRC%
nasm %NASM_FLAGS% "%KERNEL_SRC%" -o "%KERNEL_BIN%"
if errorlevel 1 goto :fail

set /a EXPECTED=%KERNEL_BYTES% + 512
for %%A in ("%KERNEL_BIN%") do set ACTUAL=%%~zA
echo       kernel binary size: %ACTUAL% bytes (expected %EXPECTED%)

if not "%ACTUAL%"=="%EXPECTED%" (
    echo ERROR: kernel binary is %ACTUAL% bytes, expected %EXPECTED%.
    goto :fail
)

echo [2/8] Building apps
set APP_LIST=
for /d %%D in (apps\*) do (
    if exist "%%D\make.bat" (
        echo       building %%~nxD
        pushd "%%D"
        call make.bat
        popd
        if errorlevel 1 goto :fail
        for %%F in ("%%D\*.app") do set APP_LIST=!APP_LIST! "%%F"
    )
)

echo [3/8] Writing kernel to image
copy /b "%KERNEL_BIN%" "%IMAGE%" >nul
if errorlevel 1 goto :fail

echo [4/8] Appending apps
if "%APP_LIST%"=="" (
    echo       no apps found
) else (
    for %%A in (%APP_LIST%) do (
        echo       appending %%~nxA
        copy /b "%IMAGE%"+%%A "%IMAGE%.tmp" >nul
        if errorlevel 1 goto :fail
        move /y "%IMAGE%.tmp" "%IMAGE%" >nul
        if errorlevel 1 goto :fail
    )
)

echo [5/8] Padding to font offset (LBA 200)
for %%A in ("%IMAGE%") do set IMG_SIZE=%%~zA
if %IMG_SIZE% LSS %FONT_OFFSET% (
    set /a FONT_PAD=%FONT_OFFSET% - %IMG_SIZE%
    fsutil file createnew pad.bin !FONT_PAD! >nul
    if errorlevel 1 goto :fail
    copy /b "%IMAGE%"+pad.bin "%IMAGE%.tmp" >nul
    move /y "%IMAGE%.tmp" "%IMAGE%" >nul
    del pad.bin >nul
)

echo [6/8] Appending font: %FONT_FILE%
if not exist "%FONT_FILE%" (
    echo ERROR: font file not found: %FONT_FILE%
    goto :fail
)
copy /b "%IMAGE%"+"%FONT_FILE%" "%IMAGE%.tmp" >nul
if errorlevel 1 goto :fail
move /y "%IMAGE%.tmp" "%IMAGE%" >nul

echo [7/8] Appending 3 wallpapers (64 KB each)
call :append_wp "%WALLPAPER_FILE%"
call :append_wp "%WALLPAPER2_FILE%"
call :append_wp "%WALLPAPER3_FILE%"
echo [7.5/8] Appending test.wav at LBA 700
if not exist test.wav (
    echo       test.wav missing - filling with zeros
    fsutil file createnew wav_pad.bin 65536 >nul
    copy /b "%IMAGE%"+wav_pad.bin "%IMAGE%.tmp" >nul
    move /y "%IMAGE%.tmp" "%IMAGE%" >nul
    del wav_pad.bin >nul
    goto :pad_hdd
)
for %%A in (test.wav) do set WAV_SIZE=%%~zA
echo       test.wav = !WAV_SIZE! bytes
if !WAV_SIZE! LSS 65536 (
    set /a WAV_PAD=65536 - !WAV_SIZE!
    fsutil file createnew wav_pad.bin !WAV_PAD! >nul
    copy /b test.wav+wav_pad.bin wav_padded.bin >nul
    del wav_pad.bin >nul
) else (
    copy /b test.wav wav_padded.bin >nul
)
copy /b "%IMAGE%"+wav_padded.bin "%IMAGE%.tmp" >nul
move /y "%IMAGE%.tmp" "%IMAGE%" >nul
del wav_padded.bin >nul
goto :pad_hdd

:append_wp
if not exist "%~1" (
    echo       %~1 missing - filling with zeros
    fsutil file createnew wp_tmp.bin 65536 >nul
    copy /b "%IMAGE%"+wp_tmp.bin "%IMAGE%.tmp" >nul
    move /y "%IMAGE%.tmp" "%IMAGE%" >nul
    del wp_tmp.bin >nul
    goto :eof
)
for %%A in ("%~1") do set WP_SIZE=%%~zA
echo       %~1 = !WP_SIZE! bytes
if !WP_SIZE! LSS 65536 (
    set /a WP_PAD=65536 - !WP_SIZE!
    fsutil file createnew wp_tmp.bin !WP_PAD! >nul
    copy /b "%~1"+wp_tmp.bin wp_padded.bin >nul
    del wp_tmp.bin >nul
) else (
    copy /b "%~1" wp_padded.bin >nul
)
copy /b "%IMAGE%"+wp_padded.bin "%IMAGE%.tmp" >nul
move /y "%IMAGE%.tmp" "%IMAGE%" >nul
del wp_padded.bin >nul
goto :eof

:pad_hdd
echo [8/8] Padding to 10 MB HDD
for %%A in ("%IMAGE%") do set IMG_SIZE=%%~zA
set /a PAD_SIZE=%HDD_BYTES% - %IMG_SIZE%
if %PAD_SIZE% GTR 0 (
    fsutil file createnew pad.bin %PAD_SIZE% >nul
    if errorlevel 1 goto :fail
    copy /b "%IMAGE%"+pad.bin "%IMAGE%.tmp" >nul
    move /y "%IMAGE%.tmp" "%IMAGE%" >nul
    del pad.bin >nul
)

for %%A in ("%IMAGE%") do set FINAL_SIZE=%%~zA
set /a FINAL_SECTORS=%FINAL_SIZE% / 512

echo.
echo Build complete: %IMAGE%
echo   size:    %FINAL_SIZE% bytes
echo   sectors: %FINAL_SECTORS%
echo.

REM --- Launch QEMU ---
if not exist %QEMU% (
    echo WARNING: QEMU not found at %QEMU%
    echo Run manually:
    echo   qemu-system-i386 -drive format=raw,file=%IMAGE%,index=0,media=disk
    goto :eof
)

echo Launching TeenyOS in QEMU...
echo.
%QEMU% -drive format=raw,file=%IMAGE%,index=0,media=disk
goto :eof

:fail
echo.
echo BUILD FAILED
exit /b 1