package main

import "core:fmt"
import "core:time"


main :: proc() {
	for {
		fmt.println("Hello World")
		time.sleep(5 * time.Second)
	}
}
