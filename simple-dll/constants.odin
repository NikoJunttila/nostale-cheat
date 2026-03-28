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
IN :: "in"
QNAMLI :: "qnamli"
MSGI :: "msgi"
SAY :: "say"
EFF :: "eff"

important_packets := []string{GURI, SAYI, SAY, SU, SR, C_MAP, IN, QNAMLI, MSGI, EFF}
spam_packets := []string {
	"ncif ",
	"pulse ",
	"u_s ", // skill usage
	"walk ",
	"guri ",
	"c_close ",
	"mall ",
	"rest ",
	"f_stash_end",
	"bp_close",
	"ptctl", // pet movement
	"suctl ",
	"u_i ",
}
