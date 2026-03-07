#pragma once
#include "Typedef.h"

namespace Memory
{
	DWORD FindPattern(const byte *i_bSignature, const char *i_szMask, DWORD i_dwAddress = 0x00400000, DWORD i_dwLength = 0x00436000);
	void *DetourFunc(byte *i_pOriginal, byte *i_pDetour, DWORD i_dwLength);
};