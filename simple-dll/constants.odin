package payload

TCP_PACKET_RECV_NOS :: "0"
TCP_PACKET_SEND_NOS :: "1"

EAddress :: enum {
	ARecvHook,
	ASendHook,
	APacketClassPointer,
	ASendPacket,
	ARecvPacket,
}

EPacketType :: enum {
	PTReceive,
	PTSend,
}

GURI :: "guri"
SAYI :: "sayi"
SU :: "su"

important_packets := []string{GURI, SAYI, SU}

//
// pattern_playerID := []byte {
// 	0xA1,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0xFF,
// 	0xA1,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0x83,
// 	0x38,
// 	0x00,
// 	0x76,
// }
//
// mask_playerID := []byte("x????????xx????xx?x")
//
// pattern_sp := []byte {
// 	0xA1,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0x8B,
// 	0,
// 	0x33,
// 	0xD2,
// 	0xE8,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0xB3,
// 	0x01,
// 	0xA1,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0x8B,
// 	0,
// 	0xE8,
// 	0,
// 	0,
// 	0,
// 	0,
// 	0x84,
// 	0xC0,
// 	0x74,
// 	0x21,
// }

// mask_sp := []byte("x????xxxxx????xxx????xxx????xxxx")
