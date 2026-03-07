#pragma once
#include <functional>

namespace HookManager
{
	void Initialize(std::function<bool(char *i_szPacket)> i_pRecvCallback, std::function<bool(char *i_szPacket)> i_pSendCallback);
	void Unhook();
};