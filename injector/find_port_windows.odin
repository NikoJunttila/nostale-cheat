package injector

import "core:c"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:sys/windows"

// Windows API structures and constants for TCP table
MIB_TCP_STATE :: enum c.int {
	CLOSED     = 1,
	LISTEN     = 2,
	SYN_SENT   = 3,
	SYN_RCVD   = 4,
	ESTAB      = 5,
	FIN_WAIT1  = 6,
	FIN_WAIT2  = 7,
	CLOSE_WAIT = 8,
	CLOSING    = 9,
	LAST_ACK   = 10,
	TIME_WAIT  = 11,
	DELETE_TCB = 12,
}

MIB_TCPROW_OWNER_PID :: struct {
	dwState:      c.ulong,
	dwLocalAddr:  c.ulong,
	dwLocalPort:  c.ulong,
	dwRemoteAddr: c.ulong,
	dwRemotePort: c.ulong,
	dwOwningPid:  c.ulong,
}

MIB_TCPTABLE_OWNER_PID :: struct {
	dwNumEntries: c.ulong,
	table:        [1]MIB_TCPROW_OWNER_PID,
}

// Import GetExtendedTcpTable from iphlpapi.dll
foreign import iphlpapi "system:iphlpapi.lib"

@(default_calling_convention = "stdcall")
foreign iphlpapi {
	GetExtendedTcpTable :: proc(pTcpTable: rawptr, pdwSize: ^c.ulong, bOrder: c.int, ulAf: c.ulong, TableClass: c.int, Reserved: c.ulong) -> c.ulong ---
}

AF_INET :: 2
TCP_TABLE_OWNER_PID_LISTENER :: 3

// find_listening_port_for_process finds a listening port for a given process ID
// Parameters:
//   pid: The process ID to search for
// Returns:
//   bool: true if a listening port was found
//   u32: The port number (0 if not found)
find_listening_port_for_process :: proc(pid: u32) -> (string, bool) {
	// First call to get the required buffer size
	size: c.ulong = 0
	result := GetExtendedTcpTable(nil, &size, 0, AF_INET, TCP_TABLE_OWNER_PID_LISTENER, 0)

	if result != 122 { 	// ERROR_INSUFFICIENT_BUFFER
		fmt.printf("Failed to get TCP table size: %d\n", result)
		return "", false
	}

	// Allocate buffer
	buffer := make([]byte, size)
	defer delete(buffer)

	// Second call to get the actual data
	result = GetExtendedTcpTable(
		raw_data(buffer),
		&size,
		0,
		AF_INET,
		TCP_TABLE_OWNER_PID_LISTENER,
		0,
	)

	if result != 0 {
		fmt.printf("Failed to get TCP table: %d\n", result)
		return "", false
	}

	// Cast buffer to TCP table structure
	tcp_table := cast(^MIB_TCPTABLE_OWNER_PID)raw_data(buffer)
	num_entries := tcp_table.dwNumEntries

	// Iterate through TCP table entries
	// Note: We need to manually calculate offsets since the table is a flexible array
	for i in 0 ..< num_entries {
		// Calculate pointer to current entry
		entry_ptr := cast(^MIB_TCPROW_OWNER_PID)(uintptr(tcp_table) +
			size_of(c.ulong) +
			uintptr(i) * size_of(MIB_TCPROW_OWNER_PID))

		// Check if this entry belongs to our process
		if entry_ptr.dwOwningPid == c.ulong(pid) {
			// Check if the connection is in LISTEN state
			if entry_ptr.dwState == c.ulong(MIB_TCP_STATE.LISTEN) {
				// Convert port from network byte order (big endian) to host byte order
				port := u32((entry_ptr.dwLocalPort >> 8) | ((entry_ptr.dwLocalPort & 0xFF) << 8))

				if port > 0 {
					fmt.printf("Found listening port: %d for PID: %d\n", port, pid)
					return fmt.tprintf("%d", port), true
				}
			}
		}
	}

	return "", false
}

// find_process_by_name searches for a running process by its executable name
find_multiple_process_by_name :: proc(process_name: string) -> ([dynamic]u32, bool) {
	values := make([dynamic]u32, 0, 16)
	snapshot := windows.CreateToolhelp32Snapshot(windows.TH32CS_SNAPPROCESS, 0)
	if snapshot == windows.INVALID_HANDLE_VALUE {
		fmt.println("Failed to create process snapshot")
		return values, false
	}
	defer windows.CloseHandle(snapshot)

	pe: windows.PROCESSENTRY32W
	pe.dwSize = size_of(windows.PROCESSENTRY32W)

	if !windows.Process32FirstW(snapshot, &pe) {
		fmt.println("Failed to get first process")
		return values, false
	}

	for {
		current_name, _ := windows.utf16_to_utf8(pe.szExeFile[:])
		current_name = strings.to_lower(current_name)
		defer delete(current_name)

		if strings.contains(current_name, process_name) {
			fmt.printf("Found process: %s (PID: %d)\n", current_name, pe.th32ProcessID)
			append(&values, pe.th32ProcessID)
		}

		if !windows.Process32NextW(snapshot, &pe) {
			break
		}
	}
	if len(values) > 0 {
		return values, true
	}

	return values, false
}

// find_packetlogger_process_port combines process search and port detection
find_packetlogger_process_ports :: proc(process_name: string) -> [dynamic]string {
	ports := make([dynamic]string, 0, 16)
	pids, found := find_multiple_process_by_name(process_name)
	defer delete(pids)

	if !found {
		fmt.printf("Process %s not found\n", process_name)
		log.fatal("failed to find any processes")
		return ports
	}
	for pid in pids {
		port, ok := find_listening_port_for_process(pid)
		if ok do append(&ports, port)
	}
	return ports
}
