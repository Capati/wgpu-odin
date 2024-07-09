@echo off
setlocal enabledelayedexpansion

:: Set default values
set ARGS=-debug -vet -strict-style
set RELEASE_MODE=false
set BUILD_TARGET=
set ERROR_OCCURRED=false

:: Check all arguments for "release" and identify the build target
for %%i in (%*) do (
    if /i "%%i"=="release" (
        set RELEASE_MODE=true
    ) else if "!BUILD_TARGET!"=="" (
        set BUILD_TARGET=%%i
    )
)

:: Set mode string
if "%RELEASE_MODE%"=="true" (
    set MODE=RELEASE
) else (
    set MODE=DEBUG
)

if "%RELEASE_MODE%"=="true" (
    set ARGS=-o:speed ^
        -disable-assert ^
        -no-bounds-check ^
        -define:WGPU_CHECK_TO_BYTES=false ^
        -define:WGPU_ENABLE_ERROR_HANDLING=false
    set ADDITIONAL_ARGS=-subsystem:windows
)

:: Force DX12 backend
::set ARGS=%ARGS% -define:WGPU_BACKEND_TYPE=DX12

set OUT=-out:.\build

:: Process the build target
if "%BUILD_TARGET%"=="" (
    call :all
) else (
    call :%BUILD_TARGET%
    if errorlevel 1 (
        set ERROR_OCCURRED=true
    )
)

if "%ERROR_OCCURRED%"=="true" (
    echo One or more errors occurred during the build process.
    exit /b 1
) else (
    echo Build process completed successfully.
    exit /b 0
)

:all
call :capture
call :compute
call :cube
call :cube_textured
call :image_blur
call :info
call :microui
call :rotating_cube
call :rotating_cube_textured
call :texture_arrays
call :triangle
call :triangle_msaa
call :learn_wgpu
goto :eof

:capture
call :build_example capture
goto :eof

:compute
call :build_example compute
goto :eof

:cube
call :build_example cube
goto :eof

:cube_textured
call :build_example cube_textured
goto :eof

:image_blur
call :build_example image_blur
goto :eof

:info
call :build_example info
goto :eof

:microui
call :build_example microui
goto :eof

:rotating_cube
call :build_example rotating_cube
goto :eof

:rotating_cube_textured
call :build_example rotating_cube_textured
goto :eof

:texture_arrays
call :build_example texture_arrays
goto :eof

:triangle
call :build_example triangle
goto :eof

:triangle_msaa
call :build_example triangle_msaa
goto :eof

:learn_wgpu
call :build_learn_wgpu
goto :eof

:build_example
echo Building '%1' in %MODE% mode...
odin build .\%1 %ARGS% %ADDITIONAL_ARGS% %OUT%\%1.exe
if errorlevel 1 (
	ECHO.
    echo Error building '%1'
    set ERROR_OCCURRED=true
)
goto :eof

:build_learn_wgpu
set LEARN_WGPU_EXAMPLES=^
	beginner\tutorial1_window_sdl ^
	beginner\tutorial1_window_glfw ^
	beginner\tutorial2_surface_sdl ^
	beginner\tutorial2_surface_glfw ^
	beginner\tutorial2_surface_challenge ^
	beginner\tutorial3_pipeline ^
	beginner\tutorial3_pipeline_challenge ^
	beginner\tutorial4_buffer ^
	beginner\tutorial4_buffer_challenge ^
	beginner\tutorial5_textures ^
	beginner\tutorial5_textures_challenge ^
	beginner\tutorial6_uniforms

echo Building 'learn_wgpu' in %MODE% mode...
for %%e in (%LEARN_WGPU_EXAMPLES%) do (
    odin build .\learn_wgpu\%%e %ARGS% %ADDITIONAL_ARGS% %OUT%\%%~nxe.exe
    if errorlevel 1 (
        echo Error building %%e
        set ERROR_OCCURRED=true
    )
)
goto :eof
