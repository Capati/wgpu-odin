package application

nul_search_bytes :: proc "contextless" (buffer: []byte) -> (nul: int) {
	nul = -1
	nul_search: for i in 0 ..< len(buffer) {
		if buffer[i] == 0 {
			nul = i
			break nul_search
		}
	}

	if nul == -1 {
		nul = len(buffer) - 1 // Ensure space for null terminator
	}

	return
}

nul_search :: proc {
	nul_search_bytes,
}
