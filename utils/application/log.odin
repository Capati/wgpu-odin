package application

// Core
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

LOG_BUFFER_SIZE :: #config(APP_LOG_BUFFER_SIZE, 1024)

log_loc :: proc(fmt_str: string, args: ..any, level := Log_Level.Info, loc := #caller_location) {
	buffer: [LOG_BUFFER_SIZE]byte
	builder := strings.builder_from_bytes(buffer[:])

	// Write the formatted string first
	fmt.sbprintf(&builder, fmt_str, ..args)
	strings.write_byte(&builder, '\n')
	strings.write_string(&builder, "    ") // 4 spaces for indentation

	// Write the location
	strings.write_string(&builder, loc.file_path)
	strings.write_byte(&builder, ':')
	strings.write_int(&builder, int(loc.line))
	if loc.column != 0 {
		strings.write_byte(&builder, ':')
		strings.write_int(&builder, int(loc.column))
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
