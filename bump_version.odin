package main

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"

main :: proc() {
	filepath := "simple-dll/logging_windows.odin"
	data, err := os.read_entire_file_from_path(filepath, context.allocator)
	if err != nil {
		fmt.eprintln("Failed to read", filepath)
		os.exit(1)
	}

	content := string(data)
	
	idx := strings.index(content, "VERSION :: \"")
	if idx < 0 {
		fmt.eprintln("Could not find VERSION in", filepath)
		os.exit(1)
	}
	
	start := idx + len("VERSION :: \"")
	end := start + strings.index(content[start:], "\"")
	
	ver_str := content[start:end]
	parts := strings.split(ver_str, ".")
	if len(parts) == 3 {
		patch, _ := strconv.parse_int(parts[2])
		patch += 1
		new_ver := fmt.tprintf("%s.%s.%d", parts[0], parts[1], patch)
		
		old_line := fmt.tprintf("VERSION :: \"%s\"", ver_str)
		new_line := fmt.tprintf("VERSION :: \"%s\"", new_ver)
		
		new_content, _ := strings.replace(content, old_line, new_line, 1)
		
		write_err := os.write_entire_file(filepath, transmute([]u8)new_content)
		if write_err != nil {
			fmt.eprintln("Failed to write updated version to file")
		} else {
			fmt.println("Bumped payload version to", new_ver)
		}
	}
}
