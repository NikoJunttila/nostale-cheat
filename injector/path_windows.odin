package injector

import "core:sys/windows"

windows_file_exists :: proc(path: string) -> bool {
	if len(path) == 0 {
		return false
	}

	path_w := windows.utf8_to_wstring(path)
	if path_w == nil {
		return false
	}

	attr := windows.GetFileAttributesW(path_w)
	if attr == windows.INVALID_FILE_ATTRIBUTES {
		return false
	}
	return attr & windows.FILE_ATTRIBUTE_DIRECTORY == 0
}

windows_get_full_path :: proc(path: string) -> (string, bool) {
	if len(path) == 0 {
		return "", false
	}

	path_w := windows.utf8_to_wstring(path)
	if path_w == nil {
		return "", false
	}

	buffer := make([]u16, windows.MAX_PATH_WIDE)
	buffer_ptr := windows.LPWSTR(&buffer[0])
	buffer_len := cast(windows.DWORD)len(buffer)
	res := windows.GetFullPathNameW(path_w, buffer_len, windows.LPCWSTR(buffer_ptr), nil)
	if res == 0 {
		return "", false
	}
	length := cast(int)res
	if res >= buffer_len {
		buffer = make([]u16, cast(int)res + 2)
		buffer_ptr = windows.LPWSTR(&buffer[0])
		buffer_len = cast(windows.DWORD)len(buffer)
		res = windows.GetFullPathNameW(path_w, buffer_len, windows.LPCWSTR(buffer_ptr), nil)
		if res == 0 {
			return "", false
		}
		length = cast(int)res
	}

	full_path, err := windows.wstring_to_utf8_alloc(windows.wstring(buffer_ptr), length, context.temp_allocator)
	if err != nil {
		return "", false
	}
	return full_path, true
}
