package payload

import "core:encoding/json"
import "core:fmt"
import "core:strings"

users_json := #load("users.json")

User :: struct {
	id:       string,
	username: string,
}

get_username :: proc(target_id: string) -> string {
	users: [dynamic]User
	defer delete(users)

	if err := json.unmarshal(users_json, &users); err != nil {
		fmt.println("failed to parse json:", err)
		return ""
	}

	for user in users {
		if user.id == target_id {
			u, err := strings.clone(user.username)
			if err != nil {
				log_info("failed to clone username")
				return ""
			}
			log_info(u)
			return u
		}
	}
	return ""
}
