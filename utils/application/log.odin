package application

// Packages
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"

Log_Level :: enum {
	Info, // default
	Debug,
	Warn,
	Error,
	Fatal,
}

LOG_BUFFER_SIZE :: #config(APP_LOG_BUFFER_SIZE, 512)

log_loc :: proc(fmt_str: string, args: ..any, level := Log_Level.Info, loc := #caller_location) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	builder := strings.builder_make(LOG_BUFFER_SIZE, context.temp_allocator)

	// Write the formatted string first
	fmt.sbprintf(&builder, fmt_str, ..args)
	strings.write_byte(&builder, '\n')
	strings.write_string(&builder, "    ") // 4 spaces for indentation

	// Write the location
	strings.write_string(&builder, loc.file_path)
	when ODIN_ERROR_POS_STYLE == .Default {
		strings.write_byte(&builder, '(')
		strings.write_int(&builder, int(loc.line))
		if loc.column != 0 {
			strings.write_byte(&builder, ':')
			strings.write_int(&builder, int(loc.column))
		}
		strings.write_byte(&builder, ')')
	} else when ODIN_ERROR_POS_STYLE == .Unix {
		strings.write_byte(&builder, ':')
		strings.write_int(&builder, loc.line)
		if loc.column != 0 {
			strings.write_byte(&builder, ':')
			strings.write_int(&builder, loc.column)
		}
		strings.write_byte(&builder, ':')
	} else {
		#panic("unhandled ODIN_ERROR_POS_STYLE")
	}

	str := strings.to_string(builder)
	switch level {
	case .Info:
		log.infof("%s", str)
	case .Debug:
		log.debugf("%s", str)
	case .Warn:
		log.warnf("%s", str)
	case .Error:
		log.errorf("%s", str)
	case .Fatal:
		log.fatalf("%s", str)
	}
}
