package payload

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


//This should be a enum?
GURI :: "guri"
SAYI :: "sayi"
SU :: "su"
SR :: "sr"
C_MAP :: "c_map"
IN :: "IN"

important_packets := []string{GURI, SAYI, SU, SR, C_MAP, IN}
