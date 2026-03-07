#include "AddressManager.h"
#include "HookFunctions.h"
#include "HookManager.h"
#include "Defines.h"
#include "Memory.h"

#ifdef ACTIVATE_CONSOLE
#include <iostream>
#endif
#include <map>


static std::map<EAddress, DWORD> s_mapAddress;


void ReadPattern(const EAddress i_eAddress, const byte *i_abSignature, const char *i_szMask, const DWORD i_dwAdd = 0) {
	DWORD dwAddress = Memory::FindPattern(i_abSignature, i_szMask);
	if (dwAddress && i_dwAdd) {
		dwAddress = *reinterpret_cast<DWORD*>(dwAddress + i_dwAdd);
	}

#ifdef ACTIVATE_CONSOLE
	std::cout << std::hex << "[AddressManager] Pattern Result (0x" << i_eAddress << "): " << dwAddress << std::endl;
#endif

	s_mapAddress[i_eAddress] = dwAddress;
}

void AddressManager::Initialize()
{
	// Recv & Hook
	{
		const byte abSignature[] = { 0x55, 0x8B, 0xEC, 0x83, 0xC4, 0xF0, 0x53, 0x56, 0x57, 0x33, 0xC9, 0x89, 0x4D, 0xF4, 0x89, 0x4D, 0xF0, 0x89, 0x55, 0xFC, 0x8B, 0xD8, 0x8B, 0x45, 0xFC };
		const char *szMask = "xxxxx?xxxxxxx?xx?xx?xxxx?";
		ReadPattern(EAddress::ARecvHook, abSignature, szMask);

		s_mapAddress[EAddress::ARecvPacket] = s_mapAddress[EAddress::ARecvHook];
	}

	// Send & Hook
	{
		// Official
		const byte abSignature[] = { 0x53, 0x56, 0x8B, 0xF2, 0x8B, 0xD8, 0xEB, 0x04, 0xEB, 0x05, 0x39, 0x19, 0x8B, 0xD6, 0x8B, 0xC3, 0xE8, 0xFF, 0xFF, 0xFF, 0xFF, 0x84, 0xC0, 0x74, 0x1A };
		const char *szMask = "xxxxxxxxxxxxxxxxx????xxxx";
		
		ReadPattern(EAddress::ASendHook, abSignature, szMask);
		
		s_mapAddress[EAddress::ASendPacket] = s_mapAddress[EAddress::ASendHook];
	}

	// Send & Hook Vendetta
	if (!s_mapAddress[EAddress::ASendHook]) {
		const byte abSignature[] = { 0x53, 0x56, 0x57, 0x8B, 0xFA, 0x8B, 0xF0, 0xB3, 0x01, 0xEB, 0x04, 0xEB, 0x05 };
		const char* szMask = "xxxxxxxxxx?x?";
		ReadPattern(EAddress::ASendHook, abSignature, szMask);

		s_mapAddress[EAddress::ASendPacket] = s_mapAddress[EAddress::ASendHook];
	}

	// Packet Class Pointer
	{
		const byte abSignature[] = { 0xA1, 0x00, 0x00, 0x00, 0x00, 0x8B, 0x00, 0x80, 0x78, 0x60, 0x00, 0x74, 0x1B, 0x84, 0xDB };
		const char *szMask = "x????xxxxxxxxxx";
		ReadPattern(EAddress::APacketClassPointer, abSignature, szMask, 1);
	}

	HookManager::Initialize(&HookFunctions::HandleRecvPacket, &HookFunctions::HandleSendPacket);
}

DWORD AddressManager::Get(const EAddress i_eAddress)
{
	const auto oIterator = s_mapAddress.find(i_eAddress);
	if (oIterator != s_mapAddress.end())
	{
		return oIterator->second;
	}

	return 0;
}