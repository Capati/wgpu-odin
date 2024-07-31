package application

// STD Library
import si "core:sys/info"

Power_State :: enum {
	Unknown,
	Battery,
	No_Battery,
	Charging,
	Charged,
}

OS_Info :: struct {
	os_name:    string,
	os_version: si.OS_Version,
}

System_Info :: struct {
	using _os: OS_Info,
	cpu:       string,
	ram:       si.RAM,
}

// Gets the current operating _system.
system_get_os :: proc "contextless" () -> (info: OS_Info) {
	info.os_name = si.os_version.as_string
	info.os_version = si.os_version
	return
}

// Gets information about the _system.
system_get_info :: proc "contextless" () -> (info: System_Info) {
	info._os = system_get_os()
	info.cpu = si.cpu_name.? or_else ""
	info.ram = si.ram
	return
}

// Gets text from the clipboard.
system_get_clipboard_text :: _system_get_clipboard_text

// Gets information about the system's power supply.
system_get_power_info :: _system_get_power_info

// Gets the amount of logical processors in the _system.
system_get_processor_count :: _system_get_processor_count

// Gets whether another application on the system is playing music in the background.
system_has_background_music :: _system_has_background_music

// Opens a URL with the user's web or file browser.
system_open_url :: _system_open_url

// Puts text in the clipboard.
system_set_clipboard_text :: _system_set_clipboard_text

// Causes the device to vibrate, if possible.
system_vibrate :: _system_vibrate
