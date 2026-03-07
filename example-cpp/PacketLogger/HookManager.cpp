#include "HookManager.h"
#include "AddressManager.h"
#include "Memory.h"

#include <polyhook2/Detour/x86Detour.hpp>
#include <polyhook2/CapstoneDisassembler.hpp>

#include <iostream>
#include <Windows.h>


PLH::CapstoneDisassembler g_oCapstoneDisasm(PLH::Mode::x86);

std::function<bool(char *i_szPacket)> g_pRecvCallback;
PLH::x86Detour *g_pRecvDetour = nullptr;
uint64 g_iRecvTrampoline;

std::function<bool(char *i_szPacket)> g_pSendCallback;
PLH::x86Detour *g_pSendDetour = nullptr;
uint64 g_iSendTrampoline;


void RecvPacketHook() {
	static char *s_szPacket;

	__asm {
		pushad
		pushfd
		mov s_szPacket, edx
	}

	if (g_pRecvCallback(s_szPacket)) { 
		s_szPacket[0] = 0x00;
	}

	__asm {
		popfd
		popad
	}

	PLH::FnCast(g_iRecvTrampoline, &RecvPacketHook)();
}

void SendPacketHook() {
	static char *s_szPacket;

	__asm {
		pushad
		pushfd
		mov s_szPacket, edx
	}

	bool fBlockPacket = g_pSendCallback(s_szPacket);
	
	__asm {
		popfd
		popad
	}
	
	if (fBlockPacket) {
		return;
	}

	PLH::FnCast(g_iSendTrampoline, &SendPacketHook)();
}


void HookManager::Initialize(std::function<bool(char *i_szPacket)> i_pRecvCallback, std::function<bool(char *i_szPacket)> i_pSendCallback)
{
	if (!g_pRecvDetour) {
		g_pRecvCallback = i_pRecvCallback;
		g_pRecvDetour = new PLH::x86Detour(static_cast<uint64>(AddressManager::Get(EAddress::ARecvHook)), reinterpret_cast<uint64>(&RecvPacketHook), &g_iRecvTrampoline, g_oCapstoneDisasm);
		g_pRecvDetour->hook();
	}

	if (!g_pSendDetour) {
		g_pSendCallback = i_pSendCallback;
		g_pSendDetour = new PLH::x86Detour(static_cast<uint64>(AddressManager::Get(EAddress::ASendHook)), reinterpret_cast<uint64>(&SendPacketHook), &g_iSendTrampoline, g_oCapstoneDisasm);
		g_pSendDetour->hook();
	}
}


void HookManager::Unhook()
{
	if (g_pRecvDetour) {
		g_pRecvDetour->unHook();
		delete g_pRecvDetour;
		g_pRecvDetour = nullptr;
	}
	
	if (g_pSendDetour) {
		g_pSendDetour->unHook();
		delete g_pSendDetour;
		g_pSendDetour = nullptr;
	}
}