@echo off
setlocal enabledelayedexpansion

:: Set default values
set RELEASE_MODE=false
set BUILD_TARGET=%1
set ERROR_OCCURRED=false
set RUN_AFTER_BUILD=false
set CLEAN_BUILD=false
set WEB_BUILD=false
set ADDITIONAL_ARGS=

:: Check for arguments
set ARG_COUNTER=0
for %%i in (%*) do (
	if !ARG_COUNTER! equ 0 (
		rem Skip the first argument
	) else (
		if /i "%%i"=="release" (
			set RELEASE_MODE=true
		) else if /i "%%i"=="run" (
			set RUN_AFTER_BUILD=true
		) else if /i "%%i"=="clean" (
			set CLEAN_BUILD=true
		) else if /i "%%i"=="web" (
			set WEB_BUILD=true
		) else (
			set "ADDITIONAL_ARGS=!ADDITIONAL_ARGS! %%i"
		)
	)
	set /a ARG_COUNTER+=1
)

:: Set mode string
if "%RELEASE_MODE%"=="true" (
	set MODE=RELEASE
) else (
	set MODE=DEBUG
)

:: Set build arguments based on target and mode
if "%WEB_BUILD%"=="true" (
	:: Web build arguments
	if "%RELEASE_MODE%"=="true" (
		set ARGS=-o:size -disable-assert -no-bounds-check
	) else (
		set ARGS=-debug
	)
) else (
	:: Native build arguments
	if "%RELEASE_MODE%"=="true" (
		set ARGS=-o:speed -disable-assert -no-bounds-check
	) else (
		set ARGS=-debug -define:WGPU_SHARED=true
	)
)

set OUT=.\build
set OUT_FLAG=-out:%OUT%

:: Check if a build target was provided
if "%BUILD_TARGET%"=="" (
	echo [BUILD] --- Error: Please provide a folder name to build
	echo [BUILD] --- Usage: build.bat folder_name [release] [run] [clean] [web]
	exit /b 1
)

for %%i in ("%BUILD_TARGET:\=" "%") do set TARGET_NAME=%%~ni

:: Clean build if requested
if "%CLEAN_BUILD%"=="true" (
	echo [BUILD] --- Cleaning artifacts...
	if exist "%OUT%\*.exe" del /F /Q %OUT%\*.exe
	if exist "%OUT%\*.pdb" del /F /Q %OUT%\*.pdb
	if exist "%OUT%\web\*.wasm" del /F /Q %OUT%\web\*.wasm
	if exist "%OUT%\web\wgpu.js" del /F /Q %OUT%\web\wgpu.js
	if exist "%OUT%\web\odin.js" del /F /Q %OUT%\web\odin.js
)

set INITIAL_MEMORY_PAGES=2000
set MAX_MEMORY_PAGES=65536
set PAGE_SIZE=65536
set /a INITIAL_MEMORY_BYTES=%INITIAL_MEMORY_PAGES% * %PAGE_SIZE%
set /a MAX_MEMORY_BYTES=%MAX_MEMORY_PAGES% * %PAGE_SIZE%

:: Get and set ODIN_ROOT environment variable
for /f "delims=" %%i in ('odin.exe root') do set "ODIN_ROOT=%%i"
set "ODIN_ROOT=%ODIN_ROOT:"=%"
if "%ODIN_ROOT:~-1%"=="\" set "ODIN_ROOT=%ODIN_ROOT:~0,-1%"
set ODIN_ROOT=%ODIN_ROOT%

:: Handle web build
if "%WEB_BUILD%"=="true" (
	echo [BUILD] --- Building '%TARGET_NAME%' for web in %MODE% mode...
	call odin build .\%BUILD_TARGET% ^
		%OUT_FLAG%\web\app.wasm ^
		%ARGS% ^
		-target:js_wasm32 ^
		-extra-linker-flags:"--export-table --import-memory --initial-memory=!INITIAL_MEMORY_BYTES! --max-memory=!MAX_MEMORY_BYTES!"
	if errorlevel 1 (
		echo [BUILD] --- Error building '%TARGET_NAME%' for web
		set ERROR_OCCURRED=true
	) else (
		copy "..\resources\wgpu.js" "%OUT%\web\wgpu.js" >nul
		copy "..\resources\odin.js" "%OUT%\web\odin.js" >nul
		echo [BUILD] --- Web build completed successfully.
	)
) else (
	:: Copy DLL if in debug mode
	if "%RELEASE_MODE%"=="false" (
    if not exist "%OUT%\wgpu_native.dll" (
	        copy "%ODIN_ROOT%\vendor\wgpu\lib\wgpu-windows-x86_64-msvc-release\lib\wgpu_native.dll" "%OUT%\wgpu_native.dll" >nul
	    )
	)

	:: Build the target (regular build)
	echo [BUILD] --- Building '%TARGET_NAME%' in %MODE% mode...
	call odin build .\%BUILD_TARGET% %ARGS% %ADDITIONAL_ARGS% %OUT_FLAG%\%TARGET_NAME%.exe
	if errorlevel 1 (
		echo [BUILD] --- Error building '%TARGET_NAME%'
		set ERROR_OCCURRED=true
	)
)

if "%ERROR_OCCURRED%"=="true" (
	echo [BUILD] --- Build process failed.
	exit /b 1
) else (
	echo [BUILD] --- Build process completed successfully.
	if "%RUN_AFTER_BUILD%"=="true" (
		if "%WEB_BUILD%"=="true" (
			echo [BUILD] --- Note: Cannot automatically run web builds. Please open web/index.html in a browser.
		) else (
			echo [BUILD] --- Running %TARGET_NAME%...
			pushd build
			%TARGET_NAME%.exe
			popd
		)
	)
	exit /b 0
)
