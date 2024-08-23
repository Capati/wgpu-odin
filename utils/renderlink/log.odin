//+private
package application

// STD Library
import "base:runtime"
import "core:log"

@(disabled = !ODIN_DEBUG)
_log_info_contextless :: proc "contextless" (fmt_str: string, args: ..any) {
	if g_logger.data == nil do return
	context = runtime.default_context()
	context.logger = g_logger
	if len(args) > 0 {
		log.infof(fmt_str, ..args)
	} else {
		log.info(fmt_str)
	}
}

@(disabled = !ODIN_DEBUG)
_log_warn_contextless :: proc "contextless" (fmt_str: string, args: ..any) {
	if g_logger.data == nil do return
	context = runtime.default_context()
	context.logger = g_logger
	if len(args) > 0 {
		log.warnf(fmt_str, ..args)
	} else {
		log.warn(fmt_str)
	}
}

@(disabled = !ODIN_DEBUG)
_log_error_contextless :: proc "contextless" (fmt_str: string, args: ..any) {
	if g_logger.data == nil do return
	context = runtime.default_context()
	context.logger = g_logger
	if len(args) > 0 {
		log.errorf(fmt_str, ..args)
	} else {
		log.error(fmt_str)
	}
}

@(disabled = !ODIN_DEBUG)
_log_fatal_contextless :: proc "contextless" (fmt_str: string, args: ..any) {
	if g_logger.data == nil do return
	context = runtime.default_context()
	context.logger = g_logger
	if len(args) > 0 {
		log.fatalf(fmt_str, ..args)
	} else {
		log.fatal(fmt_str)
	}
}
