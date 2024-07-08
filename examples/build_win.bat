@echo off
setlocal enabledelayedexpansion

:: Set default values
set ARGS=-debug -vet -strict-style
set RELEASE_MODE=false
set BUILD_TARGET=

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
    echo Building all examples in %MODE% mode...
    call :all
) else (
    echo Building '%BUILD_TARGET%' in %MODE% mode...
    call :%BUILD_TARGET%
    if errorlevel 1 (
        echo Example not recognized: %BUILD_TARGET%
    )
)
goto :end

:all
call :capture
call :compute
call :cube
call :cube_textured
call :image_blur
call :info
call :microui
call :rotating_cube
call :texture_arrays
call :triangle
call :triangle_msaa
call :learn_wgpu
goto :eof

:capture
odin build .\capture %ARGS% %OUT%\capture.exe
goto :eof

:compute
odin build .\compute %ARGS% %OUT%\compute.exe
goto :eof

:cube
odin build .\cube %ARGS% %ADDITIONAL_ARGS% %OUT%\cube.exe
goto :eof

:cube_textured
odin build .\cube_textured %ARGS% %ADDITIONAL_ARGS% %OUT%\cube_textured.exe
goto :eof

:image_blur
odin build .\image_blur %ARGS% %ADDITIONAL_ARGS% %OUT%\image_blur.exe
goto :eof

:info
odin build .\info %ARGS% %ADDITIONAL_ARGS% %OUT%\info.exe
goto :eof

:microui
odin build .\microui %ARGS% %ADDITIONAL_ARGS% %OUT%\microui.exe
goto :eof

:rotating_cube
odin build .\rotating_cube %ARGS% %ADDITIONAL_ARGS% %OUT%\rotating_cube.exe
goto :eof

:texture_arrays
odin build .\texture_arrays %ARGS% %ADDITIONAL_ARGS% %OUT%\texture_arrays.exe
goto :eof

:triangle
odin build .\triangle %ARGS% %ADDITIONAL_ARGS% %OUT%\triangle.exe
goto :eof

:triangle_msaa
odin build .\triangle_msaa %ARGS% %ADDITIONAL_ARGS% %OUT%\triangle_msaa.exe
goto :eof

:learn_wgpu
odin build .\learn_wgpu\beginner\tutorial1_window_sdl %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial1_window_sdl.exe
odin build .\learn_wgpu\beginner\tutorial1_window_glfw %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial1_window_glfw.exe
odin build .\learn_wgpu\beginner\tutorial2_surface_sdl %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial2_surface_sdl.exe
odin build .\learn_wgpu\beginner\tutorial2_surface_glfw %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial2_surface_glfw.exe
odin build .\learn_wgpu\beginner\tutorial2_surface_challenge %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial2_surface_challenge.exe
odin build .\learn_wgpu\beginner\tutorial3_pipeline %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial3_pipeline.exe
odin build .\learn_wgpu\beginner\tutorial3_pipeline_challenge %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial3_pipeline_challenge.exe
odin build .\learn_wgpu\beginner\tutorial4_buffer %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial4_buffer.exe
odin build .\learn_wgpu\beginner\tutorial4_buffer_challenge %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial4_buffer_challenge.exe
odin build .\learn_wgpu\beginner\tutorial5_textures %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial5_textures.exe
odin build .\learn_wgpu\beginner\tutorial5_textures_challenge %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial5_textures_challenge.exe
odin build .\learn_wgpu\beginner\tutorial6_uniforms %ARGS% %ADDITIONAL_ARGS% %OUT%/tutorial6_uniforms.exe
goto :eof

:end
endlocal
