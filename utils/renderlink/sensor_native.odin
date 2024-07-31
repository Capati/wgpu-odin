//+private
//+build linux, darwin, windows
package application

// Vendor
import sdl "vendor:sdl2"

_sensor_native_convert_to_sdl_sensor :: proc(type: Sensor_Type) -> sdl.SensorType {
	#partial switch type {
	case .Accelerometer:
		return .ACCEL
	case .Gyroscope:
		return .GYRO
	case:
		return .UNKNOWN
	}
}

_sensor_native_convert_sdl_to_sensor :: proc(type: sdl.SensorType) -> Sensor_Type {
	#partial switch type {
	case .ACCEL:
		return .Accelerometer
	case .GYRO:
		return .Gyroscope
	case:
		return .Unknown
	}
}
