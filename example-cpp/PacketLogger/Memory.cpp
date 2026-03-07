#include "Memory.h"
#include <Windows.h>


bool CompareData(const byte *i_pData, const byte *i_bSignature, const char *i_szMask)
{
	for (; *i_szMask; ++i_szMask, ++i_pData, ++i_bSignature) {
		if (*i_szMask == 'x' && *i_pData != *i_bSignature)
			return false;
	}

	return (*i_szMask) == 0;
}

DWORD Memory::FindPattern(const byte *i_bSignature, const char *i_szMask, const DWORD i_dwAddress, const DWORD i_dwLength)
{
	for (DWORD i = 0; i < i_dwLength; i++) {
		if (CompareData(reinterpret_cast<BYTE *>(i_dwAddress + i), i_bSignature, i_szMask))
			return i_dwAddress + i;
	}

	return 0;
}


void *Memory::DetourFunc(byte *i_pOriginal, byte *i_pDetour, DWORD i_dwLength)
{
	DWORD dwOld;
	VirtualProtect(i_pOriginal, i_dwLength, PAGE_READWRITE, &dwOld);

	/* Get old bytes */
	byte *pJump = new byte[i_dwLength + 4];
	*reinterpret_cast<DWORD*>(pJump) = reinterpret_cast<DWORD>(i_pOriginal + i_dwLength);

	for (DWORD i = 0; i < i_dwLength; i++) {
		pJump[i + 4] = i_pOriginal[i];
	}
	/* End */

	/* Jump to new Function */
	i_pOriginal[0] = 0xE9;
	*reinterpret_cast<DWORD*>(i_pOriginal + 1) = static_cast<DWORD>(i_pDetour - i_pOriginal) - 5;
	/* End */

	VirtualProtect(i_pOriginal, i_dwLength, dwOld, &dwOld);

	return pJump;
}