#!/bin/bash
# Exit on any error
set -e

# Set default values
RELEASE_MODE=false
BUILD_TARGET="$1"
ERROR_OCCURRED=false
RUN_AFTER_BUILD=false
CLEAN_BUILD=false
WEB_BUILD=false
ADDITIONAL_ARGS=""

# Check if a build target was provided
if [ -z "$BUILD_TARGET" ]; then
	echo "[BUILD] --- Error: Please provide a folder name to build"
	echo "[BUILD] --- Usage: $0 folder_name [release] [run] [clean] [web]"
	exit 1
fi

# Extract target name (last part of path)
TARGET_NAME=$(basename "$BUILD_TARGET")

# Process remaining arguments (skip first argument)
shift
while [ $# -gt 0 ]; do
	case "$1" in
	release)
		RELEASE_MODE=true
		;;
	run)
		RUN_AFTER_BUILD=true
		;;
	clean)
		CLEAN_BUILD=true
		;;
	web)
		WEB_BUILD=true
		;;
	*)
		ADDITIONAL_ARGS="$ADDITIONAL_ARGS $1"
		;;
	esac
	shift
done

# Set mode string
if [ "$RELEASE_MODE" = true ]; then
	MODE="RELEASE"
else
	MODE="DEBUG"
fi

# Set build arguments based on target and mode
if [ "$WEB_BUILD" = true ]; then
	# Web build arguments
	if [ "$RELEASE_MODE" = true ]; then
		ARGS="-o:size -disable-assert -no-bounds-check"
	else
		ARGS="-debug"
	fi
else
	# Native build arguments
	if [ "$RELEASE_MODE" = true ]; then
		ARGS="-o:speed -disable-assert -no-bounds-check"
	else
		ARGS="-debug -define:WGPU_SHARED=true"
	fi
fi

OUT="./build"
OUT_FLAG="-out:$OUT"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
	echo "[BUILD] --- Cleaning artifacts..."
	# Remove native build artifacts
	rm -f "$OUT"/*.o          # Object files
	rm -f "$OUT"/*.a          # Static libraries
	rm -f "$OUT"/*.so         # Shared objects/dynamic libraries
	rm -f "$OUT"/*.so.*       # Versioned shared objects
	rm -f "$OUT"/*.dylib      # macOS dynamic libraries
	rm -f "$OUT"/*.out        # Default executable name (a.out)
	rm -f "$OUT"/*~           # Backup files
	rm -rf "$OUT"/*.dSYM      # macOS debug symbols directory
	# Remove web build artifacts
	rm -f "$OUT"/web/*.wasm
	rm -f "$OUT"/web/wgpu.js
	rm -f "$OUT"/web/odin.js
fi

# Web memory settings (matching the .bat file)
INITIAL_MEMORY_PAGES=2000
MAX_MEMORY_PAGES=65536
PAGE_SIZE=65536
INITIAL_MEMORY_BYTES=$((INITIAL_MEMORY_PAGES * PAGE_SIZE))
MAX_MEMORY_BYTES=$((MAX_MEMORY_PAGES * PAGE_SIZE))

# Get and set ODIN_ROOT environment variable
ODIN_ROOT=$(odin root | tr -d '"')
# Remove trailing slash if present
ODIN_ROOT=${ODIN_ROOT%/}

# Handle web build
if [ "$WEB_BUILD" = true ]; then
	echo "[BUILD] --- Building '$TARGET_NAME' for web in $MODE mode..."

	# Create web directory if it doesn't exist
	mkdir -p "$OUT/web"

	if ! odin build "./$BUILD_TARGET" \
		"$OUT_FLAG/web/app.wasm" \
		$ARGS \
		-target:js_wasm32 \
		-extra-linker-flags:"--export-table --import-memory --initial-memory=$INITIAL_MEMORY_BYTES --max-memory=$MAX_MEMORY_BYTES" \
		$ADDITIONAL_ARGS; then
		echo "[BUILD] --- Error building '$TARGET_NAME' for web"
		ERROR_OCCURRED=true
	else
		# Copy required JS files (adjust paths as needed for your setup)
		if [ -f "../resources/wgpu.js" ]; then
			cp "../resources/wgpu.js" "$OUT/web/wgpu.js"
		fi
		if [ -f "../resources/odin.js" ]; then
			cp "../resources/odin.js" "$OUT/web/odin.js"
		fi
		echo "[BUILD] --- Web build completed successfully."
	fi
else
	# Copy shared library if in debug mode (Linux/macOS equivalent of DLL copying)
	if [ "$RELEASE_MODE" = false ]; then
		# Determine the appropriate shared library based on OS
		case "$(uname -s)" in
		Linux*)
			WGPU_LIB="$ODIN_ROOT/vendor/wgpu/lib/wgpu-linux-x86_64-gnu/lib/libwgpu_native.so"
			if [ -f "$WGPU_LIB" ] && [ ! -f "$OUT/libwgpu_native.so" ]; then
				cp "$WGPU_LIB" "$OUT/libwgpu_native.so"
			fi
			;;
		Darwin*)
			WGPU_LIB="$ODIN_ROOT/vendor/wgpu/lib/wgpu-macos-universal/lib/libwgpu_native.dylib"
			if [ -f "$WGPU_LIB" ] && [ ! -f "$OUT/libwgpu_native.dylib" ]; then
				cp "$WGPU_LIB" "$OUT/libwgpu_native.dylib"
			fi
			;;
		esac
	fi

	# Build the target (regular build)
	echo "[BUILD] --- Building '$TARGET_NAME' in $MODE mode..."
	if ! odin build "./$BUILD_TARGET" $ARGS $ADDITIONAL_ARGS "$OUT_FLAG/$TARGET_NAME"; then
		echo "[BUILD] --- Error building '$TARGET_NAME'"
		ERROR_OCCURRED=true
	fi
fi

if [ "$ERROR_OCCURRED" = true ]; then
	echo "[BUILD] --- Build process failed."
	exit 1
else
	echo "[BUILD] --- Build process completed successfully."
	if [ "$RUN_AFTER_BUILD" = true ]; then
		if [ "$WEB_BUILD" = true ]; then
			echo "[BUILD] --- Note: Cannot automatically run web builds. Please open web/index.html in a browser."
		else
			echo "[BUILD] --- Running $TARGET_NAME..."
			(cd build && ./"$TARGET_NAME")
		fi
	fi
	exit 0
fi
