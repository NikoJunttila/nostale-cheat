#pragma once
#include "Typedef.h"

enum EAddress : byte {
	ARecvHook,
	ASendHook,

	APacketClassPointer,
	ASendPacket,
	ARecvPacket,
};

namespace AddressManager
{
	void Initialize();

	DWORD Get(EAddress i_eAddress);
};