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
