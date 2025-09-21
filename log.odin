package webgpu

// Vendor
import "vendor:wgpu"

/*
Defines the available log levels for WGPU logging, levels are ordered from least
to most verbose.
*/
LogLevel :: wgpu.LogLevel

/*
Sets the global log level for WGPU.

This controls which log messages will be emitted by the WGPU implementation.
Only messages at the specified level and more severe levels will be shown.
*/
SetLogLevel :: wgpu.SetLogLevel

/*
Sets a callback procedure to handle WGPU log messages.

The callback will be invoked whenever WGPU generates a log message at or above
the current log level. Pass `nil` to remove the current callback.
*/
SetLogCallback :: wgpu.SetLogCallback

/*
Procedure type for WGPU logging callbacks.

Inputs:

- `level`: The severity level of the log message
- `message`: The content of the log message as a string view
- `userData`: Optional pointer to user-provided data that was passed when
  setting the callback
*/
LogCallback :: #type proc "c" (level: LogLevel, message: string, userData: rawptr)

ConvertOdinToWGPULogLevel :: wgpu.ConvertOdinToWGPULogLevel
ConvertWGPUToOdinLogLevel :: wgpu.ConvertWGPUToOdinLogLevel
ConvertLogLevel           :: wgpu.ConvertLogLevel
