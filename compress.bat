@echo off
setlocal EnableDelayedExpansion

:: === Check if ffmpeg is installed ===
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo ⚠️ FFmpeg not found! Please install it first.
    echo Run this command in your terminal:
    echo winget install ffmpeg
    echo.
    pause
    exit /b
)

:: === Create folders if needed ===
if not exist input mkdir input
if not exist output mkdir output
if not exist logs mkdir logs

:: === Bitrate options ===
echo.
echo Choose bitrate setting:
echo 1. Low Quality (500k)
echo 2. Medium Quality (1000k)
echo 3. High Quality (2000k)
echo 4. Custom Bitrate
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" set bitrate=500k
if "%choice%"=="2" set bitrate=1000k
if "%choice%"=="3" set bitrate=2000k
if "%choice%"=="4" (
    set /p bitrate="Enter custom bitrate (e.g., 750k, 1M): "
)

:: === List MP4 files in /input, newest first ===
echo.
echo === Available MP4 Files ===
set i=0

for /f "delims=" %%A in ('dir /b /o-d /a:-d "input\*.mp4"') do (
    set /a i+=1
    set "file!i!=%%A"
    echo !i!. %%A
)

if %i%==0 (
    echo // No .mp4 files found in input folder.
    timeout /t 5 >nul
    exit
)

:: === Ask which file ===
echo.
set /p fileChoice="Enter the number of the file to compress: "
call set "selectedFile=%%file%fileChoice%%%"

:: === Sanity check ===
if not defined selectedFile (
    echo // Invalid selection.
    timeout /t 5 >nul
    exit
)

:: === Setup paths ===
set "inputFile=input\%selectedFile%"
set "outputName=%selectedFile:.mp4=_compressed.mp4%"
set "outputFile=output\%outputName%"
set "logFile=logs\%selectedFile:.mp4=_log.txt%"

:: === Display summary ===
echo.
echo // Compressing: %selectedFile%
echo // Bitrate: %bitrate%
echo // Output: %outputName%
echo // Log: %logFile%
echo.

:: === Start FFmpeg in background with overwrite flag ===
start "" /b cmd /c "ffmpeg -y -i "%inputFile%" -b:v %bitrate% -b:a 128k "%outputFile%" > "%logFile%" 2>&1"

:: === Dummy progress counter with screen clearing ===
set counter=0
echo Encoding... Press Ctrl+C to cancel.

:progress_loop
cls
set /a counter+=1
echo Progress: %counter% seconds...
ping -n 2 127.0.0.1 >nul

:: Check if ffmpeg is still running
tasklist | findstr /i "ffmpeg.exe" >nul
if %errorlevel%==0 goto progress_loop

cls
echo.
echo // Compression complete!

:: === Get compressed file size in bytes and convert to KB ===
for %%I in ("%outputFile%") do set sizeBytes=%%~zI
set /a sizeKB=%sizeBytes% / 1024

echo Compressed file size: %sizeKB% KB
echo.
echo Closing in 5 seconds...
timeout /t 5 >nul
exit
