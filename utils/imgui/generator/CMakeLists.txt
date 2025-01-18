cmake_minimum_required(VERSION 3.11)
project(PrepareImgui)

# For managing external dependencies
include(FetchContent)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# option(IMGUI_ENABLE_FREETYPE "ImGui: Enable FreeType font rasterizer" OFF)

# Versions
set(IMGUI_VERSION "v1.91.7")
set(DEAR_BINDINGS_VERSION "139b5b8")

# Ensures everything uses the same static runtime
if(MSVC)
  add_compile_options($<$<CONFIG:>:/MT> $<$<CONFIG:Debug>:/MT>
                      $<$<CONFIG:Release>:/MT>)
endif()

message(STATUS "Fetching ImGui ${IMGUI_VERSION}")
FetchContent_Declare(
  imgui
  GIT_REPOSITORY https://github.com/ocornut/imgui.git
  GIT_TAG ${IMGUI_VERSION})

FetchContent_GetProperties(imgui)
if(NOT imgui_POPULATED)
  FetchContent_Populate(imgui)
endif()

message(STATUS "Fetching Dear_Bindings ${DEAR_BINDINGS_VERSION}")
FetchContent_Declare(
  dear_bindings
  GIT_REPOSITORY https://github.com/dearimgui/dear_bindings.git
  GIT_TAG ${DEAR_BINDINGS_VERSION})

FetchContent_GetProperties(dear_bindings)
if(NOT dear_bindings_POPULATED)
  FetchContent_Populate(dear_bindings)
endif()

message(STATUS "Setting up Python virtual environment...")
find_package(
  Python3
  COMPONENTS Interpreter
  REQUIRED)

set(VENV_DIR ${CMAKE_BINARY_DIR}/venv)
set(REQUIREMENTS_FILE ${dear_bindings_SOURCE_DIR}/requirements.txt)

if(WIN32)
  set(VENV_PYTHON ${VENV_DIR}/Scripts/python.exe)
  set(VENV_PIP ${VENV_DIR}/Scripts/pip.exe)
else()
  set(VENV_PYTHON ${VENV_DIR}/bin/python)
  set(VENV_PIP ${VENV_DIR}/bin/pip)
endif()

# Create virtual environment and install requirements
add_custom_command(
  OUTPUT ${VENV_PYTHON}
  COMMAND ${Python3_EXECUTABLE} -m venv ${VENV_DIR}
  COMMAND ${VENV_PIP} install -r ${REQUIREMENTS_FILE}
  DEPENDS ${REQUIREMENTS_FILE}
  COMMENT "Creating Python virtual environment and installing requirements")

add_custom_target(setup_venv DEPENDS ${VENV_PYTHON})

set(GENERATED_BINDINGS_DIR ${CMAKE_BINARY_DIR}/generated_imgui_bindings)

# Helper function to generate bindings for headers
function(generate_binding HEADER OUTPUT)
  add_custom_command(
    OUTPUT ${GENERATED_BINDINGS_DIR}/${OUTPUT}.h
           ${GENERATED_BINDINGS_DIR}/${OUTPUT}.cpp
    COMMAND ${CMAKE_COMMAND} -E make_directory ${GENERATED_BINDINGS_DIR}
    COMMAND
      ${VENV_PYTHON} ${dear_bindings_SOURCE_DIR}/dear_bindings.py
      --nogeneratedefaultargfunctions -o ${GENERATED_BINDINGS_DIR}/${OUTPUT}
      ${HEADER}
    DEPENDS ${HEADER} setup_venv)
endfunction()

# Generate bindings for imgui.h
generate_binding(${imgui_SOURCE_DIR}/imgui.h dcimgui)

set(IMGUI_GENERATED_HEADERS ${GENERATED_BINDINGS_DIR}/dcimgui.h)
set(IMGUI_GENERATED_SOURCES ${GENERATED_BINDINGS_DIR}/dcimgui.cpp)

# Create a custom target for the bindings generation
add_custom_target(generate_imgui_bindings DEPENDS ${IMGUI_GENERATED_HEADERS}
                                                  ${IMGUI_GENERATED_SOURCES})

# Post-build step: Copy generated files to assets/imgui
add_custom_command(
  TARGET generate_imgui_bindings
  POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${GENERATED_BINDINGS_DIR}
          ../assets/
  COMMENT "Copying generated bindings to assets")

# Gather ImGui source files
file(GLOB IMGUI_SOURCE_FILES ${imgui_SOURCE_DIR}/*.cpp)
file(GLOB IMGUI_HEADER_FILES ${imgui_SOURCE_DIR}/*.h)

# Create object library for generated sources
add_library(imgui_generated_sources OBJECT)
target_sources(
  imgui_generated_sources
  PRIVATE ${IMGUI_GENERATED_SOURCES}
  PUBLIC ${IMGUI_GENERATED_HEADERS})
add_dependencies(imgui_generated_sources generate_imgui_bindings)

target_include_directories(imgui_generated_sources
                           PUBLIC ${GENERATED_BINDINGS_DIR} ${imgui_SOURCE_DIR})

target_compile_definitions(
  imgui_generated_sources PRIVATE IMGUI_DISABLE_OBSOLETE_FUNCTIONS
                                  IMGUI_DISABLE_OBSOLETE_KEYIO)

# Main ImGui library
add_library(imgui STATIC ${IMGUI_SOURCE_FILES} ${IMGUI_HEADER_FILES})
target_link_libraries(imgui PUBLIC imgui_generated_sources)

# Set include directories for ImGui
target_include_directories(imgui PUBLIC ${GENERATED_BINDINGS_DIR}
                                        ${imgui_SOURCE_DIR})

target_compile_definitions(
  imgui PRIVATE IMGUI_DISABLE_OBSOLETE_FUNCTIONS IMGUI_DISABLE_OBSOLETE_KEYIO
                "IMGUI_IMPL_API=extern \"C\"")

# Determine platform and architecture for library naming
if(WIN32)
  set(OS_NAME "windows")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM64")
    set(ARCH_NAME "arm64")
  else()
    set(ARCH_NAME "x64")
  endif()
  set(LIB_EXTENSION "lib")
elseif(APPLE)
  set(OS_NAME "darwin")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64")
    set(ARCH_NAME "arm64")
  else()
    set(ARCH_NAME "x64")
  endif()
  set(LIB_EXTENSION "a")
elseif(UNIX)
  set(OS_NAME "linux")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(ARCH_NAME "arm64")
  else()
    set(ARCH_NAME "x64")
  endif()
  set(LIB_EXTENSION "a")
endif()

# Set the target platform name to match Odin's foreign block pattern
set(TARGET_PLATFORM "imgui_${OS_NAME}_${ARCH_NAME}.${LIB_EXTENSION}")

add_custom_command(
  TARGET imgui
  POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:imgui>
          ${CMAKE_SOURCE_DIR}/../${TARGET_PLATFORM}
  COMMENT "Copying ImGui library ${TARGET_PLATFORM}")
