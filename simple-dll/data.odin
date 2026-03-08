package payload

// Call FindPattern for the 4 core signatures: RecvHook, SendHook, SendHook-Vendetta fallback, and PacketClassPointer.
// Store the resolved addresses in global variables or a map.

// bool CompareData(const byte *i_pData, const byte *i_bSignature, const char *i_szMask)
// {
// 	for (; *i_szMask; ++i_szMask, ++i_pData, ++i_bSignature) {
// 		if (*i_szMask == 'x' && *i_pData != *i_bSignature)
// 			return false;
// 	}
//
// 	return (*i_szMask) == 0;
// }
//
// DWORD Memory::FindPattern(const byte *i_bSignature, const char *i_szMask, const DWORD i_dwAddress, const DWORD i_dwLength)
// {
// 	for (DWORD i = 0; i < i_dwLength; i++) {
// 		if (CompareData(reinterpret_cast<BYTE *>(i_dwAddress + i), i_bSignature, i_szMask))
// 			return i_dwAddress + i;
// 	}
//
// 	return 0;
// }


// void ReadPattern(const EAddress i_eAddress, const byte *i_abSignature, const char *i_szMask, const DWORD i_dwAdd = 0) {
// 	DWORD dwAddress = Memory::FindPattern(i_abSignature, i_szMask);
// 	if (dwAddress && i_dwAdd) {
// 		dwAddress = *reinterpret_cast<DWORD*>(dwAddress + i_dwAdd);
// 	}
// DWORD Memory::FindPattern(char* pattern, char* mask)
// {
//     MODULEINFO mInfo = GetModuleInfo();
//     DWORD base = (DWORD)mInfo.lpBaseOfDll;
//     DWORD size = (DWORD)mInfo.SizeOfImage;
//
//     DWORD patternLength = strlen(mask);
//
//     for (DWORD i = 0; i < size - patternLength; i++)
//     {
//         bool found = true;
//         for (DWORD j = 0; j < patternLength; j++)
//             found &= mask[j] == '?' || pattern[j] == *(char*)(base + i + j);
//
//         if (found)
//             return base + i;
//     }
//
//     return NULL;
// }
// MODULEINFO GetModuleInfo()
// {
//     MODULEINFO modinfo = { 0 };
//     HMODULE hModule = GetModuleHandle(NULL);
//
//     if (hModule == 0)
//         return modinfo;
//
//     GetModuleInformation(GetCurrentProcess(), hModule, &modinfo, sizeof(MODULEINFO));
//     return modinfo;
// }
