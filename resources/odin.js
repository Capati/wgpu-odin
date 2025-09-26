"use strict";

(function() {

function getElement(name) {
	if (name) {
		return document.getElementById(name);
	}
	return undefined;
}

function stripNewline(str) {
    return str.replace(/\n/, ' ')
}

class WasmMemoryInterface {
	constructor() {
		this.memory = null;
		this.exports = null;
		this.listenerMap = new Map();

		// Size (in bytes) of the integer type, should be 4 on `js_wasm32` and 8 on `js_wasm64p32`
		this.intSize = 4;
	}

	setIntSize(size) {
		this.intSize = size;
	}

	setMemory(memory) {
		this.memory = memory;
	}

	setExports(exports) {
		this.exports = exports;
	}

	get mem() {
		return new DataView(this.memory.buffer);
	}


	loadF32Array(addr, len) {
		let array = new Float32Array(this.memory.buffer, addr, len);
		return array;
	}
	loadF64Array(addr, len) {
		let array = new Float64Array(this.memory.buffer, addr, len);
		return array;
	}
	loadU32Array(addr, len) {
		let array = new Uint32Array(this.memory.buffer, addr, len);
		return array;
	}
	loadI32Array(addr, len) {
		let array = new Int32Array(this.memory.buffer, addr, len);
		return array;
	}


	loadU8(addr)  { return this.mem.getUint8  (addr); }
	loadI8(addr)  { return this.mem.getInt8   (addr); }
	loadU16(addr) { return this.mem.getUint16 (addr, true); }
	loadI16(addr) { return this.mem.getInt16  (addr, true); }
	loadU32(addr) { return this.mem.getUint32 (addr, true); }
	loadI32(addr) { return this.mem.getInt32  (addr, true); }
	loadU64(addr) {
		const lo = this.mem.getUint32(addr + 0, true);
		const hi = this.mem.getUint32(addr + 4, true);
		return lo + hi*4294967296;
	};
	loadI64(addr) {
		const lo = this.mem.getUint32(addr + 0, true);
		const hi = this.mem.getInt32 (addr + 4, true);
		return lo + hi*4294967296;
	};
	loadF32(addr) { return this.mem.getFloat32(addr, true); }
	loadF64(addr) { return this.mem.getFloat64(addr, true); }
	loadInt(addr) {
		if (this.intSize == 8) {
			return this.loadI64(addr);
		} else if (this.intSize == 4) {
			return this.loadI32(addr);
		} else {
			throw new Error('Unhandled `intSize`, expected `4` or `8`');
		}
	};
	loadUint(addr) {
		if (this.intSize == 8) {
			return this.loadU64(addr);
		} else if (this.intSize == 4) {
			return this.loadU32(addr);
		} else {
			throw new Error('Unhandled `intSize`, expected `4` or `8`');
		}
	};
	loadPtr(addr) { return this.loadU32(addr); }

	loadB32(addr) {
		return this.loadU32(addr) != 0;
	}

	loadBytes(ptr, len) {
		return new Uint8Array(this.memory.buffer, ptr, Number(len));
	}

	loadString(ptr, len) {
		const bytes = this.loadBytes(ptr, Number(len));
		return new TextDecoder().decode(bytes);
	}

	loadCstring(ptr) {
		if (ptr == 0) {
			return null;
		}
		let len = 0;
		for (; this.mem.getUint8(ptr+len) != 0; len += 1) {}
		return this.loadString(ptr, len);
	}

	storeU8(addr, value)  { this.mem.setUint8  (addr, value); }
	storeI8(addr, value)  { this.mem.setInt8   (addr, value); }
	storeU16(addr, value) { this.mem.setUint16 (addr, value, true); }
	storeI16(addr, value) { this.mem.setInt16  (addr, value, true); }
	storeU32(addr, value) { this.mem.setUint32 (addr, value, true); }
	storeI32(addr, value) { this.mem.setInt32  (addr, value, true); }
	storeU64(addr, value) {
		this.mem.setUint32(addr + 0, Number(value), true);

		let div = 4294967296;
		if (typeof value == 'bigint') {
			div = BigInt(div);
		}

		this.mem.setUint32(addr + 4, Math.floor(Number(value / div)), true);
	}
	storeI64(addr, value) {
		this.mem.setUint32(addr + 0, Number(value), true);

		let div = 4294967296;
		if (typeof value == 'bigint') {
			div = BigInt(div);
		}

		this.mem.setInt32(addr + 4, Math.floor(Number(value / div)), true);
	}
	storeF32(addr, value) { this.mem.setFloat32(addr, value, true); }
	storeF64(addr, value) { this.mem.setFloat64(addr, value, true); }
	storeInt(addr, value) {
		if (this.intSize == 8) {
			this.storeI64(addr, value);
		} else if (this.intSize == 4) {
			this.storeI32(addr, value);
		} else {
			throw new Error('Unhandled `intSize`, expected `4` or `8`');
		}
	}
	storeUint(addr, value) {
		if (this.intSize == 8) {
			this.storeU64(addr, value);
		} else if (this.intSize == 4) {
			this.storeU32(addr, value);
		} else {
			throw new Error('Unhandled `intSize`, expected `4` or `8`');
		}
	}

	// Returned length might not be the same as `value.length` if non-ascii strings are given.
	storeString(addr, value) {
		const src = new TextEncoder().encode(value);
		const dst = new Uint8Array(this.memory.buffer, addr, src.length);
		dst.set(src);
		return src.length;
	}
};

function odinSetupDefaultImports(wasmMemoryInterface, consoleElement, memory) {
	const MAX_INFO_CONSOLE_LINES = 512;
	let infoConsoleLines = new Array();
	let currentLine = {};
	currentLine[false] = "";
	currentLine[true] = "";
	let prevIsError = false;
	
	let event_temp = {};

	const onEventReceived = (event_data, data, callback) => {
		event_temp.data = event_data;
		
		const exports = wasmMemoryInterface.exports;
		const odin_ctx = exports.default_context_ptr();
		
		exports.odin_dom_do_event_callback(data, callback, odin_ctx);
		
		event_temp.data = null;
	};

	const writeToConsole = (line, isError) => {
		if (!line) {
			return;
		}

		const println = (text, forceIsError) => {
			let style = [
				"color: #eee",
				"background-color: #d20",
				"padding: 2px 4px",
				"border-radius: 2px",
			].join(";");
			let doIsError = isError;
			if (forceIsError !== undefined) {
				doIsError = forceIsError;
			}

			if (doIsError) {
				console.log("%c"+text, style);
			} else {
				console.log(text);
			}

		};

		// Print to console
		if (line == "\n") {
			println(currentLine[isError]);
			currentLine[isError] = "";
		} else if (!line.includes("\n")) {
			currentLine[isError] = currentLine[isError].concat(line);
		} else {
			let lines = line.trimEnd().split("\n");
			let printLast = lines.length > 1 && line.endsWith("\n");
			println(currentLine[isError].concat(lines[0]));
			currentLine[isError] = "";
			for (let i = 1; i < lines.length-1; i++) {
				println(lines[i]);
			}
			if (lines.length > 1) {
				let last = lines[lines.length-1];
				if (printLast) {
					println(last);
				} else {
					currentLine[isError] = last;
				}
			}
		}

		if (prevIsError != isError) {
			if (prevIsError) {
				println(currentLine[prevIsError], prevIsError);
				currentLine[prevIsError] = "";
			}
		}
		prevIsError = isError;


		// HTML based console
		if (!consoleElement) {
			return;
		}
		const wrap = (x) => {
			if (isError) {
				return '<span style="color:#f21">'+x+'</span>';
			}
			return x;
		};

		if (line == "\n") {
			infoConsoleLines.push(line);
		} else if (!line.includes("\n")) {
			let prevLine = "";
			if (infoConsoleLines.length > 0) {
				prevLine = infoConsoleLines.pop();
			}
			infoConsoleLines.push(prevLine.concat(wrap(line)));
		} else {
			let lines = line.split("\n");
			let lastHasNewline = lines.length > 1 && line.endsWith("\n");

			let prevLine = "";
			if (infoConsoleLines.length > 0) {
				prevLine = infoConsoleLines.pop();
			}
			infoConsoleLines.push(prevLine.concat(wrap(lines[0]).concat("\n")));

			for (let i = 1; i < lines.length-1; i++) {
				infoConsoleLines.push(wrap(lines[i]).concat("\n"));
			}
			let last = lines[lines.length-1];
			if (lastHasNewline) {
				infoConsoleLines.push(last.concat("\n"));
			} else {
				infoConsoleLines.push(last);
			}
		}

		if (infoConsoleLines.length > MAX_INFO_CONSOLE_LINES) {
			infoConsoleLines.shift(MAX_INFO_CONSOLE_LINES);
		}

		let data = "";
		for (let i = 0; i < infoConsoleLines.length; i++) {
			data = data.concat(infoConsoleLines[i]);
		}

		let info = consoleElement;
		info.innerHTML = data;
		info.scrollTop = info.scrollHeight;
	};

	const listener_key = (id, name, data, callback, useCapture) => {
		return `${id}-${name}-data:${data}-callback:${callback}-useCapture:${useCapture}`;
	};

	const env = {};

	if (memory) {
		env.memory = memory;
	}

	return {
		env,
		"odin_env": {
			write: (fd, ptr, len) => {
				const str = wasmMemoryInterface.loadString(ptr, len);
				if (fd == 1) {
					writeToConsole(str, false);
					return;
				} else if (fd == 2) {
					writeToConsole(str, true);
					return;
				} else {
					throw new Error("Invalid fd to 'write'" + stripNewline(str));
				}
			},
			trap: () => { throw new Error() },
			alert: (ptr, len) => { alert(wasmMemoryInterface.loadString(ptr, len)) },
			abort: () => { Module.abort() },
			evaluate: (str_ptr, str_len) => { eval.call(null, wasmMemoryInterface.loadString(str_ptr, str_len)); },

			open: (url_ptr, url_len, name_ptr, name_len, specs_ptr, specs_len) => {
				const url = wasmMemoryInterface.loadString(url_ptr, url_len);
				const name = wasmMemoryInterface.loadString(name_ptr, name_len);
				const specs = wasmMemoryInterface.loadString(specs_ptr, specs_len);
				window.open(url, name, specs);
			},

			// return a bigint to be converted to i64
			time_now: () => BigInt(Date.now()),
			tick_now: () => performance.now(),
			time_sleep: (duration_ms) => {
				if (duration_ms > 0) {
					// TODO(bill): Does this even make any sense?
				}
			},

			sqrt:    Math.sqrt,
			sin:     Math.sin,
			cos:     Math.cos,
			pow:     Math.pow,
			fmuladd: (x, y, z) => x*y + z,
			ln:      Math.log,
			exp:     Math.exp,
			ldexp:   (x, exp) => x * Math.pow(2, exp),

			rand_bytes: (ptr, len) => {
				const view = new Uint8Array(wasmMemoryInterface.memory.buffer, ptr, len)
				crypto.getRandomValues(view)
			},
		},
		"odin_dom": {
			init_event_raw: (ep) => {
				const W = wasmMemoryInterface.intSize;
				let offset = ep;
				let off = (amount, alignment) => {
					if (alignment === undefined) {
						alignment = Math.min(amount, W);
					}
					if (offset % alignment != 0) {
						offset += alignment - (offset%alignment);
					}
					let x = offset;
					offset += amount;
					return x;
				};

				let align = (alignment) => {
					const modulo = offset & (alignment-1);
					if (modulo != 0) {
						offset += alignment - modulo
					}
				};

				let wmi = wasmMemoryInterface;

				if (!event_temp.data) {
					return;
				}

				let e = event_temp.data.event;

				wmi.storeU32(off(4), event_temp.data.name_code);
				if (e.target == document) {
					wmi.storeU32(off(4), 1);
				} else if (e.target == window) {
					wmi.storeU32(off(4), 2);
				} else {
					wmi.storeU32(off(4), 0);
				}
				if (e.currentTarget == document) {
					wmi.storeU32(off(4), 1);
				} else if (e.currentTarget == window) {
					wmi.storeU32(off(4), 2);
				} else {
					wmi.storeU32(off(4), 0);
				}

				align(W);

				wmi.storeI32(off(W), event_temp.data.id_ptr);
				wmi.storeUint(off(W), event_temp.data.id_len);

				align(8);
				wmi.storeF64(off(8), e.timeStamp*1e-3);

				wmi.storeU8(off(1), e.eventPhase);
				let options = 0;
				if (!!e.bubbles)    { options |= 1<<0; }
				if (!!e.cancelable) { options |= 1<<1; }
				if (!!e.composed)   { options |= 1<<2; }
				wmi.storeU8(off(1), options);
				wmi.storeU8(off(1), !!e.isComposing);
				wmi.storeU8(off(1), !!e.isTrusted);

				align(8);
				if (e instanceof WheelEvent) {
					wmi.storeF64(off(8), e.deltaX);
					wmi.storeF64(off(8), e.deltaY);
					wmi.storeF64(off(8), e.deltaZ);
					wmi.storeU32(off(4), e.deltaMode);
				} else if (e instanceof MouseEvent) {
					wmi.storeI64(off(8), e.screenX);
					wmi.storeI64(off(8), e.screenY);
					wmi.storeI64(off(8), e.clientX);
					wmi.storeI64(off(8), e.clientY);
					wmi.storeI64(off(8), e.offsetX);
					wmi.storeI64(off(8), e.offsetY);
					wmi.storeI64(off(8), e.pageX);
					wmi.storeI64(off(8), e.pageY);
					wmi.storeI64(off(8), e.movementX);
					wmi.storeI64(off(8), e.movementY);

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeI16(off(2), e.button);
					wmi.storeU16(off(2), e.buttons);

					if (e instanceof PointerEvent) {
						wmi.storeF64(off(8), e.altitudeAngle);
						wmi.storeF64(off(8), e.azimuthAngle);
						wmi.storeInt(off(W), e.persistentDeviceId);
						wmi.storeInt(off(W), e.pointerId);
						wmi.storeInt(off(W), e.width);
						wmi.storeInt(off(W), e.height);
						wmi.storeF64(off(8), e.pressure);
						wmi.storeF64(off(8), e.tangentialPressure);
						wmi.storeF64(off(8), e.tiltX);
						wmi.storeF64(off(8), e.tiltY);
						wmi.storeF64(off(8), e.twist);
						if (e.pointerType == "pen") {
							wmi.storeU8(off(1), 1);
						} else if (e.pointerType == "touch") {
							wmi.storeU8(off(1), 2);
						} else {
							wmi.storeU8(off(1), 0);
						}
						wmi.storeU8(off(1), !!e.isPrimary);
					}

				} else if (e instanceof KeyboardEvent) {
					// Note: those strings are constructed
					// on the native side from buffers that
					// are filled later, so skip them
					const keyPtr  = off(W*2, W);
					const codePtr = off(W*2, W);

					wmi.storeU8(off(1), e.location);

					wmi.storeU8(off(1), !!e.ctrlKey);
					wmi.storeU8(off(1), !!e.shiftKey);
					wmi.storeU8(off(1), !!e.altKey);
					wmi.storeU8(off(1), !!e.metaKey);

					wmi.storeU8(off(1), !!e.repeat);

					wmi.storeI32(off(4), e.charCode);

					wmi.storeInt(off(W, W), e.key.length)
					wmi.storeInt(off(W, W), e.code.length)
					wmi.storeString(off(32, 1), e.key);
					wmi.storeString(off(32, 1), e.code);
				} else if (e.type === 'scroll') {
					wmi.storeF64(off(8, 8), window.scrollX);
					wmi.storeF64(off(8, 8), window.scrollY);
				} else if (e.type === 'visibilitychange') {
					wmi.storeU8(off(1), !document.hidden);
				} else if (e instanceof GamepadEvent) {
					const idPtr      = off(W*2, W);
					const mappingPtr = off(W*2, W);

					wmi.storeI32(off(W, W), e.gamepad.index);
					wmi.storeU8(off(1), !!e.gamepad.connected);
					wmi.storeF64(off(8, 8), e.gamepad.timestamp);

					wmi.storeInt(off(W, W), e.gamepad.buttons.length);
					wmi.storeInt(off(W, W), e.gamepad.axes.length);

					for (let i = 0; i < 64; i++) {
						if (i < e.gamepad.buttons.length) {
							let b = e.gamepad.buttons[i];
							wmi.storeF64(off(8, 8), b.value);
							wmi.storeU8(off(1),  !!b.pressed);
							wmi.storeU8(off(1),  !!b.touched);
						} else {
							off(16, 8);
						}
					}
					for (let i = 0; i < 16; i++) {
						if (i < e.gamepad.axes.length) {
							let a = e.gamepad.axes[i];
							wmi.storeF64(off(8, 8), a);
						} else {
							off(8, 8);
						}
					}

					let idLength = e.gamepad.id.length;
					let id = e.gamepad.id;
					if (idLength > 96) {
						idLength = 96;
						id = id.slice(0, 93) + '...';
					}

					let mappingLength = e.gamepad.mapping.length;
					let mapping = e.gamepad.mapping;
					if (mappingLength > 64) {
						mappingLength = 61;
						mapping = mapping.slice(0, 61) + '...';
					}

					wmi.storeInt(off(W, W), idLength);
					wmi.storeInt(off(W, W), mappingLength);
					wmi.storeString(off(96, 1), id);
					wmi.storeString(off(64, 1), mapping);
				}
			},

			add_event_listener: (id_ptr, id_len, name_ptr, name_len, name_code, data, callback, use_capture) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = getElement(id);
				if (element == undefined) {
					return false;
				}
				let key = listener_key(id, name, data, callback, !!use_capture);
				if (wasmMemoryInterface.listenerMap.has(key)) {
					return false;
				}

				let listener = (e) => {
					let event_data = {};
					event_data.id_ptr = id_ptr;
					event_data.id_len = id_len;
					event_data.event = e;
					event_data.name_code = name_code;

					onEventReceived(event_data, data, callback);
				};
				wasmMemoryInterface.listenerMap.set(key, listener);
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			add_window_event_listener: (name_ptr, name_len, name_code, data, callback, use_capture) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = window;
				let key = listener_key('window', name, data, callback, !!use_capture);
				if (wasmMemoryInterface.listenerMap.has(key)) {
					return false;
				}

				let listener = (e) => {
					let event_data = {};
					event_data.id_ptr = 0;
					event_data.id_len = 0;
					event_data.event = e;
					event_data.name_code = name_code;

					onEventReceived(event_data, data, callback);
				};
				wasmMemoryInterface.listenerMap.set(key, listener);
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			add_document_event_listener: (name_ptr, name_len, name_code, data, callback, use_capture) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = document;
				let key = listener_key('document', name, data, callback, !!use_capture);
				if (wasmMemoryInterface.listenerMap.has(key)) {
					return false;
				}

				let listener = (e) => {
					let event_data = {};
					event_data.id_ptr = 0;
					event_data.id_len = 0;
					event_data.event = e;
					event_data.name_code = name_code;

					onEventReceived(event_data, data, callback);
				};
				wasmMemoryInterface.listenerMap.set(key, listener);
				element.addEventListener(name, listener, !!use_capture);
				return true;
			},

			remove_event_listener: (id_ptr, id_len, name_ptr, name_len, data, callback, use_capture) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = getElement(id);
				if (element == undefined) {
					return false;
				}

				let key = listener_key(id, name, data, callback, !!use_capture);
				let listener = wasmMemoryInterface.listenerMap.get(key);
				if (listener === undefined) {
					return false;
				}
				wasmMemoryInterface.listenerMap.delete(key);

				element.removeEventListener(name, listener, !!use_capture);
				return true;
			},
			remove_window_event_listener: (name_ptr, name_len, data, callback, use_capture) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = window;

				let key = listener_key('window', name, data, callback, !!use_capture);
				let listener = wasmMemoryInterface.listenerMap.get(key);
				if (listener === undefined) {
					return false;
				}
				wasmMemoryInterface.listenerMap.delete(key);

				element.removeEventListener(name, listener, !!use_capture);
				return true;
			},
			remove_document_event_listener: (name_ptr, name_len, data, callback, use_capture) => {
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let element = document;

				let key = listener_key('document', name, data, callback, !!use_capture);
				let listener = wasmMemoryInterface.listenerMap.get(key);
				if (listener === undefined) {
					return false;
				}
				wasmMemoryInterface.listenerMap.delete(key);

				element.removeEventListener(name, listener, !!use_capture);
				return true;
			},

			event_stop_propagation: () => {
				if (event_temp.data && event_temp.data.event) {
					event_temp.data.event.stopPropagation();
				}
			},
			event_stop_immediate_propagation: () => {
				if (event_temp.data && event_temp.data.event) {
					event_temp.data.event.stopImmediatePropagation();
				}
			},
			event_prevent_default: () => {
				if (event_temp.data && event_temp.data.event) {
					event_temp.data.event.preventDefault();
				}
			},

			dispatch_custom_event: (id_ptr, id_len, name_ptr, name_len, options_bits) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let name = wasmMemoryInterface.loadString(name_ptr, name_len);
				let options = {
					bubbles:    (options_bits & (1<<0)) !== 0,
					cancelable: (options_bits & (1<<1)) !== 0,
					composed:   (options_bits & (1<<2)) !== 0,
				};

				let element = getElement(id);
				if (element) {
					element.dispatchEvent(new Event(name, options));
					return true;
				}
				return false;
			},

			get_gamepad_state: (gamepad_id, ep) => {
				let index = gamepad_id;
				let gps = navigator.getGamepads();
				if (0 <= index && index < gps.length) {
					let gamepad = gps[index];
					if (!gamepad) {
						return false;
					}

					const W = wasmMemoryInterface.intSize;
					let offset = ep;
					let off = (amount, alignment) => {
						if (alignment === undefined) {
							alignment = Math.min(amount, W);
						}
						if (offset % alignment != 0) {
							offset += alignment - (offset%alignment);
						}
						let x = offset;
						offset += amount;
						return x;
					};

					let align = (alignment) => {
						const modulo = offset & (alignment-1);
						if (modulo != 0) {
							offset += alignment - modulo
						}
					};

					let wmi = wasmMemoryInterface;

					const idPtr      = off(W*2, W);
					const mappingPtr = off(W*2, W);

					wmi.storeI32(off(W), gamepad.index);
					wmi.storeU8(off(1), !!gamepad.connected);
					wmi.storeF64(off(8), gamepad.timestamp);

					wmi.storeInt(off(W), gamepad.buttons.length);
					wmi.storeInt(off(W), gamepad.axes.length);

					for (let i = 0; i < 64; i++) {
						if (i < gamepad.buttons.length) {
							let b = gamepad.buttons[i];
							wmi.storeF64(off(8, 8), b.value);
							wmi.storeU8(off(1),  !!b.pressed);
							wmi.storeU8(off(1),  !!b.touched);
						} else {
							off(16, 8);
						}
					}
					for (let i = 0; i < 16; i++) {
						if (i < gamepad.axes.length) {
							wmi.storeF64(off(8, 8), gamepad.axes[i]);
						} else {
							off(8, 8);
						}
					}

					let idLength = gamepad.id.length;
					let id = gamepad.id;
					if (idLength > 96) {
						idLength = 96;
						id = id.slice(0, 93) + '...';
					}

					let mappingLength = gamepad.mapping.length;
					let mapping = gamepad.mapping;
					if (mappingLength > 64) {
						mappingLength = 61;
						mapping = mapping.slice(0, 61) + '...';
					}

					wmi.storeInt(off(W, W), idLength);
					wmi.storeInt(off(W, W), mappingLength);
					wmi.storeString(off(96, 1), id);
					wmi.storeString(off(64, 1), mapping);

					return true;
				}
				return false;
			},

			get_element_value_f64: (id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				return element ? element.value : 0;
			},
			get_element_value_string: (id_ptr, id_len, buf_ptr, buf_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let str = element.value;
					if (buf_len > 0 && buf_ptr) {
						let n = Math.min(buf_len, str.length);
						str = str.substring(0, n);
						this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder().encode(str))
						return n;
					}
				}
				return 0;
			},
			get_element_value_string_length: (id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					return element.value.length;
				}
				return 0;
			},
			get_element_min_max: (ptr_array2_f64, id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let values = wasmMemoryInterface.loadF64Array(ptr_array2_f64, 2);
					values[0] = element.min;
					values[1] = element.max;
				}
			},
			set_element_value_f64: (id_ptr, id_len, value) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					element.value = value;
				}
			},
			set_element_value_string: (id_ptr, id_len, value_ptr, value_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let value = wasmMemoryInterface.loadString(value_ptr, value_len);
				let element = getElement(id);
				if (element) {
					element.value = value;
				}
			},

			set_element_style: (id_ptr, id_len, key_ptr, key_len, value_ptr, value_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let value = wasmMemoryInterface.loadString(value_ptr, value_len);
				let element = getElement(id);
				if (element) {
					element.style[key] = value;
				}
			},

			get_element_key_f64: (id_ptr, id_len, key_ptr, key_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let element = getElement(id);
				return element ? element[key] : 0;
			},
			get_element_key_string: (id_ptr, id_len, key_ptr, key_len, buf_ptr, buf_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let element = getElement(id);
				if (element) {
					let str = element[key];
					if (buf_len > 0 && buf_ptr) {
						let n = Math.min(buf_len, str.length);
						str = str.substring(0, n);
						this.mem.loadBytes(buf_ptr, buf_len).set(new TextEncoder().encode(str))
						return n;
					}
				}
				return 0;
			},
			get_element_key_string_length: (id_ptr, id_len, key_ptr, key_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let element = getElement(id);
				if (element && element[key]) {
					return element[key].length;
				}
				return 0;
			},

			set_element_key_f64: (id_ptr, id_len, key_ptr, key_len, value) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let element = getElement(id);
				if (element) {
					element[key] = value;
				}
			},
			set_element_key_string: (id_ptr, id_len, key_ptr, key_len, value_ptr, value_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let key = wasmMemoryInterface.loadString(key_ptr, key_len);
				let value = wasmMemoryInterface.loadString(value_ptr, value_len);
				let element = getElement(id);
				if (element) {
					element[key] = value;
				}
			},


			get_bounding_client_rect: (rect_ptr, id_ptr, id_len) => {
				let id = wasmMemoryInterface.loadString(id_ptr, id_len);
				let element = getElement(id);
				if (element) {
					let values = wasmMemoryInterface.loadF64Array(rect_ptr, 4);
					let rect = element.getBoundingClientRect();
					values[0] = rect.left;
					values[1] = rect.top;
					values[2] = rect.right  - rect.left;
					values[3] = rect.bottom - rect.top;
				}
			},
			window_get_rect: (rect_ptr) => {
				let values = wasmMemoryInterface.loadF64Array(rect_ptr, 4);
				values[0] = window.screenX;
				values[1] = window.screenY;
				values[2] = window.screen.width;
				values[3] = window.screen.height;
			},

			window_get_scroll: (pos_ptr) => {
				let values = wasmMemoryInterface.loadF64Array(pos_ptr, 2);
				values[0] = window.scrollX;
				values[1] = window.scrollY;
			},
			window_set_scroll: (x, y) => {
				window.scroll(x, y);
			},

			device_pixel_ratio: () => {
				return window.devicePixelRatio;
			},

		},
	};
};

/**
 * @param {string} wasmPath                          - Path to the WASM module to run
 * @param {?HTMLPreElement} consoleElement           - Optional console/pre element to append output to, in addition to the console
 * @param {any} extraForeignImports                  - Imports, in addition to the default runtime to provide the module
 * @param {?WasmMemoryInterface} wasmMemoryInterface - Optional memory to use instead of the defaults
 * @param {?int} intSize                             - Size (in bytes) of the integer type, should be 4 on `js_wasm32` and 8 on `js_wasm64p32`
 */
async function runWasm(wasmPath, consoleElement, extraForeignImports, wasmMemoryInterface, intSize = 4) {
	if (!wasmMemoryInterface) {
		wasmMemoryInterface = new WasmMemoryInterface();
	}
	wasmMemoryInterface.setIntSize(intSize);

	let imports = odinSetupDefaultImports(wasmMemoryInterface, consoleElement, wasmMemoryInterface.memory);
	let exports = {};

	if (extraForeignImports !== undefined) {
		imports = {
			...imports,
			...extraForeignImports,
		};
	}

	const response = await fetch(wasmPath);
	const file = await response.arrayBuffer();
	const wasm = await WebAssembly.instantiate(file, imports);
	exports = wasm.instance.exports;
	wasmMemoryInterface.setExports(exports);

	if (exports.memory) {
		if (wasmMemoryInterface.memory) {
			console.warn("WASM module exports memory, but `runWasm` was given an interface with existing memory too");
		}
		wasmMemoryInterface.setMemory(exports.memory);
	}

	exports._start();

	// Define a `@export step :: proc(delta_time: f64) -> (keep_going: bool) {`
	// in your app and it will get called every frame.
	// return `false` to stop the execution of the module.
	if (exports.step) {
		const odin_ctx = exports.default_context_ptr();

		let prevTimeStamp = undefined;
		function step(currTimeStamp) {
			if (prevTimeStamp == undefined) {
				prevTimeStamp = currTimeStamp;
			}

			const dt = (currTimeStamp - prevTimeStamp)*0.001;
			prevTimeStamp = currTimeStamp;

			if (!exports.step(dt, odin_ctx)) {
				exports._end();
				return;
			}

			window.requestAnimationFrame(step);
		}

		window.requestAnimationFrame(step);
	} else {
		exports._end();
	}

	return;
};

window.odin = {
	// Interface Types
	WasmMemoryInterface: WasmMemoryInterface,

	// Functions
	setupDefaultImports: odinSetupDefaultImports,
	runWasm:             runWasm,
};
})();
