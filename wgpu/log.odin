package wgpu

// Packages
import "base:runtime"

/*
Sets the global log level for WGPU.

This controls which log messages will be emitted by the WGPU implementation.
Only messages at the specified level and more severe levels will be shown.
*/
set_log_level :: wgpuSetLogLevel

/*
Sets a callback procedure to handle WGPU log messages.

The callback will be invoked whenever WGPU generates a log message at or above the current log
level. Pass `nil` to remove the current callback.
*/
set_log_callback :: wgpuSetLogCallback

/*
Defines the available log levels for WGPU logging, levels are ordered from least to most verbose.
*/
Log_Level :: enum i32 {
	Off,
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}

/*
Procedure type for WGPU logging callbacks.

Inputs:

- `level`: The severity level of the log message
- `message`: The content of the log message as a string view
- `user_data`: Optional pointer to user-provided data that was passed when setting the callback
*/
Log_Callback :: #type proc "c" (level: Log_Level, message: String_View, user_data: rawptr)

convert_odin_to_wgpu_log_level :: proc(level: runtime.Logger_Level) -> Log_Level {
	// odinfmt: disable
	switch {
	case level < .Debug   : return .Trace
	case level < .Info    : return .Debug
	case level < .Warning : return .Info
	case level < .Error   : return .Warn
	case                  : return .Error
	}
	// odinfmt: enable
}

convert_wgpu_to_odin_log_level :: proc(level: Log_Level) -> runtime.Logger_Level {
	// odinfmt: disable
	switch level {
	case .Off,   .Trace, .Debug : return .Debug
	case .Info  : return .Info
	case .Warn  : return .Warning
	case .Error : return .Error
	case        : return .Error
	}
	// odinfmt: enable
}

convert_log_level :: proc {
	convert_odin_to_wgpu_log_level,
	convert_wgpu_to_odin_log_level,
}
